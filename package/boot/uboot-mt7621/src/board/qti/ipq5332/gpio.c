#include <common.h>
#include <asm/gpio.h>
#include <linux/types.h>
#include <linux/time.h>
#include <linux/delay.h>
#include <dm/device.h>
#include <dm/uclass.h>
#include <env.h>

#include <tlt/leds.h>
#include <tlt/mnf_info.h>
#include "board.h"

#define GPIO_OUT_HIGH 1
#define GPIO_OUT_LOW  0

struct led_ctl_entry {
	u8 used;
	u64 mask;
	u8 use_sr;
};

#define LCE_GP(_mask)                                                                                        \
	{                                                                                                    \
		.used = true, .mask = _mask, .use_sr = false                                                 \
	}

#define LCE_SR(_mask)                                                                                        \
	{                                                                                                    \
		.used = true, .mask = _mask, .use_sr = true                                                  \
	}

static struct led_ctl_entry led_ctl_array[ARRAY_MAX_LED_COUNT + 1] = { 0 };
static int arr_len						   = 1;
static ulong nextTimerVal					   = 0;
static ulong btn_first_press					   = 0;
static ulong btn_press_diff					   = 0;
static int btn_press_blink					   = 0;
static u64 shiftreg_all_led_on					   = 0;
static u64 shiftreg_all_led_off					   = 0;
static u64 shiftreg_eth_leds					   = 0;
static u64 gpio_eth_leds					   = 0;
static u64 shiftreg_inv_leds					   = 0; //some leds are inverted
static u64 gpio_all_leds					   = 0;
static u64 gpio_inv_leds					   = 0;
static int flashing_active					   = 0;
static int failsafe_active					   = 0;
static int leds_on						   = 0;

unsigned shiftreg_data	= SHIFTREG_DATA;
unsigned shiftreg_latch = SHIFTREG_LATCH;
unsigned shiftreg_clk	= SHIFTREG_CLK;
unsigned rst_btn	= RST_BTN;

static void prepare_gpio(unsigned gpio, bool is_output)
{
	int ret;

	ret = gpio_request(gpio, "");
	if (ret)
		printf("Failed to request gpio:%d returned %d\n", gpio, ret);

	if (is_output) {
		ret = gpio_direction_output(gpio, GPIO_OUT_LOW);
		if (ret)
			printf("Failed to set gpio:%d as output\n", gpio);

	} else {
		ret = gpio_direction_input(gpio);
		if (ret)
			printf("Failed to set gpio:%d as input\n", gpio);
	}
}

static void reserve_gpios(void)
{
	prepare_gpio(shiftreg_clk, true);
	prepare_gpio(shiftreg_data, true);
	prepare_gpio(shiftreg_latch, true);
	prepare_gpio(RST_BTN, false);

	for (u32 i = 0; i < 64; i++) {
		if ((1LL << i) & gpio_all_leds) {
			prepare_gpio(i, true);
		} else if ((1LL << i) & gpio_eth_leds) {
			prepare_gpio(i, true);
		}
	}
}

static void control_gp(u64 mask, u32 val)
{
	for (u32 i = 0; i < 64; i++) {
		if ((1LL << i) & mask) {
			gpio_set_value(i, val);
		}
	}
}

static void control_reg(u64 mask)
{
	int j	= 0;
	u64 msk = (mask | shiftreg_eth_leds) ^ shiftreg_inv_leds;

	/* Use only lower 32 bits */
	for (u32 i = 1; i != 0; i <<= 1, j++) {
		if (i & msk) {
			gpio_set_value(shiftreg_data, GPIO_OUT_HIGH);
		} else {
			gpio_set_value(shiftreg_data, GPIO_OUT_LOW);
		}

		gpio_set_value(shiftreg_clk, GPIO_OUT_HIGH);
		udelay(SHIFTREG_TIME_UNIT);
		gpio_set_value(shiftreg_clk, GPIO_OUT_LOW);
	}

	gpio_set_value(shiftreg_latch, GPIO_OUT_HIGH);
	udelay(SHIFTREG_TIME_UNIT);
	gpio_set_value(shiftreg_latch, GPIO_OUT_LOW);
}

void tlt_leds_on(void)
{
	// Don't shift if value is initialized to zero
	if (shiftreg_inv_leds || shiftreg_eth_leds || shiftreg_all_led_on) {
		control_reg(shiftreg_all_led_on);
	}

	control_gp((gpio_all_leds | gpio_eth_leds) & ~gpio_inv_leds, GPIO_OUT_HIGH);
	control_gp((gpio_all_leds | gpio_eth_leds) & gpio_inv_leds, GPIO_OUT_LOW);
}

void tlt_leds_off(void)
{
	// Don't shift if value is initialized to zero
	if (shiftreg_inv_leds || shiftreg_eth_leds || shiftreg_all_led_on) {
		control_reg(shiftreg_all_led_off);
	}

	control_gp(gpio_all_leds & ~gpio_inv_leds, GPIO_OUT_LOW);
	control_gp(gpio_all_leds & gpio_inv_leds, GPIO_OUT_HIGH);
}

void tlt_leds_invert(void)
{
	if (leds_on)
		tlt_leds_off();
	else
		tlt_leds_on();

	leds_on = !leds_on;
}

static void tlt_tpm_reset_gp(u32 tpm_rst_gpio)
{
	gpio_set_value(tpm_rst_gpio, GPIO_OUT_LOW);
	udelay(50 * 1000);
	gpio_set_value(tpm_rst_gpio, GPIO_OUT_HIGH);
}

void tlt_btn_press_blink_set(int val)
{
	btn_press_blink = !!val;
}

/* Returns time interval in which reset button was continiously been pressed */
int tlt_leds_check_btn_blink(void)
{
	/* 'Button press blinking' state is not enabled or button is not pressed */
	if (tlt_get_rst_btn_status() || !btn_press_blink)
		return btn_press_diff;

	ulong currentTick = get_timer(0);
	if (btn_first_press) {
		btn_first_press = currentTick;
		tlt_leds_on();
		leds_on = 1;
		return 0;
	}

	ulong diff = (currentTick - btn_first_press) / 1000; // difference in seconds
	if (diff & 0x1 && leds_on) {
		tlt_leds_off();
		leds_on = 0;
	} else if (!(diff & 0x1) && !leds_on) {
		tlt_leds_on();
		leds_on = 1;
	}

	btn_press_diff = diff;

	return diff;
}

static void sr_led_animation(void)
{
	static char index     = 0;
	static char direction = 0;

	// Don't shift if value is initialized to zero
	if (!led_ctl_array[0].used) {
		return;
	}

	if (led_ctl_array[(u8)index].use_sr) {
		control_gp(gpio_all_leds & ~gpio_inv_leds, GPIO_OUT_LOW);
		control_gp(gpio_all_leds & gpio_inv_leds, GPIO_OUT_HIGH);
		control_reg(led_ctl_array[(u8)index].mask);
	} else {
		control_reg(shiftreg_all_led_off);
		control_gp(gpio_all_leds & ~gpio_inv_leds, GPIO_OUT_LOW);
		control_gp(gpio_all_leds & gpio_inv_leds, GPIO_OUT_HIGH);
		control_gp(led_ctl_array[(u8)index].mask & ~gpio_inv_leds, GPIO_OUT_HIGH);
		control_gp(led_ctl_array[(u8)index].mask & gpio_inv_leds, GPIO_OUT_LOW);
	}

	if (!led_ctl_array[(u8)index + 1].used) {
		direction = 1;
	}

	if (!direction) {
		index++;
		if (index == arr_len) {
			direction = 1;
		}
	} else {
		index--;
		if (!index) {
			direction = 0;
		}
	}
}

void tlt_leds_check_anim(void)
{
	ulong currentTick = get_timer(0);

	if (nextTimerVal == 0) {
		nextTimerVal = currentTick + (SHIFTREG_ANIMATION_TIME_STEP / arr_len);
	}

	if (flashing_active && nextTimerVal <= currentTick) {
		sr_led_animation();
		nextTimerVal = currentTick + (SHIFTREG_ANIMATION_TIME_STEP / arr_len);
	}
}

void tlt_leds_check_blink(void)
{
	static bool leds_on;
	ulong currentTick = get_timer(0);

	if (nextTimerVal == 0) {
		nextTimerVal = currentTick + SHIFTREG_BLINK_TIME_STEP;
	}

	if (failsafe_active && nextTimerVal <= currentTick) {
		if (leds_on) {
			tlt_leds_on();
		} else {
			tlt_leds_off();
		}

		leds_on	     = !leds_on;
		nextTimerVal = currentTick + SHIFTREG_BLINK_TIME_STEP;
	}
}

static void led_ctl_array_copy(struct led_ctl_entry copyFrom[], struct led_ctl_entry copyTo[], char size)
{
	int j = 0;
	for (int i = 0; i < size; i++) {
		if (copyFrom[i].used) {
			copyTo[i - j] = copyFrom[i];
		} else {
			j++;
		}
	}
}

void tlt_leds_set_flashing_state(int state)
{
	flashing_active = !!state;
	failsafe_active = 0;
}

void tlt_leds_set_failsafe_state(int state)
{
	failsafe_active = !!state;
	flashing_active = 0;
}

int tlt_leds_get_flashing_state(void)
{
	return flashing_active;
}

int tlt_leds_get_failsafe_state(void)
{
	return failsafe_active;
}

int tlt_get_rst_btn_status(void)
{
	int ret = gpio_get_value(rst_btn);
	/* Disable 'button press blinking' state if it was already enaled and if button is
	 * no longer pressed. This helps to identify if button was released before
	 * 5 second mark */
	if (btn_press_diff && ret) {
		btn_press_blink = 0;
	}

	return ret;
}

void init_led_conf(void)
{
	char mnf_name[256];
	char mnf_branch[4];
	char mnf_hwver_hi[5]	= { 0 };
	char mnf_hwver_lo[5]	= { 0 };
	unsigned int full_hwver = 0;

	mnf_get_field("name", mnf_name);
	mnf_get_field("branch", mnf_branch);
	mnf_get_field("hwver", mnf_hwver_hi);
	mnf_get_field("hwver_lo", mnf_hwver_lo);

	if (mnf_hwver_hi[0])
		full_hwver = 100 * (dectoul(mnf_hwver_hi, NULL) / 100);

	if (mnf_hwver_lo[0])
		full_hwver += dectoul(mnf_hwver_lo, NULL) / 100;

	prepare_gpio(SHIFT_OE, true);
	gpio_set_value(SHIFT_OE, GPIO_OUT_HIGH);
	if (!strncmp(mnf_name, "RUTN50", 6) || !strncmp(mnf_name, "RUTN54", 6)) {
		struct led_ctl_entry rutn50_anim_cfg[] = {
			LCE_SR(RUTN50_SR_GEN_GR_LED),
			LCE_SR(RUTN50_SR_SSID_GR_LED),
			LCE_SR(RUTN50_SR_WAN_GR_LED),
			LCE_SR(RUTN50_SR_USER_GR_LED),
		};

		arr_len = ARRAYSIZE(rutn50_anim_cfg);
		led_ctl_array_copy(rutn50_anim_cfg, led_ctl_array, arr_len);

		shiftreg_all_led_on  = RUTN50_SR_ALL_LEDS_ON;
		shiftreg_all_led_off = RUTN50_SR_ALL_LEDS_OFF;
	}

	reserve_gpios();
	eth_initialize();
}
