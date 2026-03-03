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
static ulong btn_press_diff					   = 0;
static ulong btn_first_press					   = 0;
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
unsigned rst_btn	= RESET_BUTTON_10;

unsigned factory_din_pin = -1;

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
	if (shiftreg_inv_leds || shiftreg_eth_leds || shiftreg_all_led_on) {
		prepare_gpio(shiftreg_clk, true);
		prepare_gpio(shiftreg_data, true);
		prepare_gpio(shiftreg_latch, true);
	}
	prepare_gpio(rst_btn, false);
	if (factory_din_pin != -1) {
		prepare_gpio(factory_din_pin, false);
	}

	for (u32 i = 0; i < 64; i++) {
		if ((1LL << i) & gpio_all_leds) {
			prepare_gpio(i, true);
		} else if ((1LL << i) & gpio_eth_leds) {
			prepare_gpio(i, true);
		}
	}
}

static void control_gp(u64 mask, u8 val)
{
	for (u32 i = 0; i < 64; i++) {
		if ((1LL << i) & mask) {
			gpio_set_value(i, val);
		}
	}
}

static void control_stm(u16 mask, u8 val)
{
	for (u16 i = 0; i < 16; i++) {
		if ((1LL << i) & mask) {
			gpio_set_value(96 + i, val);
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

static void tlt_pulse_reset_gp(u32 rst_gpio) {
	gpio_set_value(rst_gpio, GPIO_OUT_LOW);
	udelay(50 * 1000);
	gpio_set_value(rst_gpio, GPIO_OUT_HIGH);
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
		if (shiftreg_inv_leds || shiftreg_eth_leds || shiftreg_all_led_on) {
			control_reg(shiftreg_all_led_off);
		}
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
	for (int i = 0; i < size; i++) {
		copyTo[i] = copyFrom[i];
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

#ifdef CONFIG_DIN_SERIAL
int tlt_get_din_pin_status(void)
{
	int ret = 1; // active_low
	if(factory_din_pin != -1)
		ret = gpio_get_value(factory_din_pin);
	return ret;
}
#endif // CONFIG_DIN_SERIAL

void init_gpio_modes(void)
{
	u32 clean_mask = SYSCTL_GPIO1_MODE_UART1_MASK | SYSCTL_GPIO1_MODE_I2S_MASK | SYSCTL_GPIO1_MODE_WDT_MASK;

	MT7621_REG(SYSCTL_GPIO1_MODE) &= ~clean_mask;
	MT7621_REG(SYSCTL_GPIO1_MODE) |= (clean_mask & SYSCTL_GPIO1_MODE_GPIO_FUNC_MASK);
}

void init_led_conf(void)
{
	char mnf_name[256];
	char mnf_hwver[5]  = { 0 };
	unsigned int hwver = 0;

	mnf_get_field("name", mnf_name);
	mnf_get_field("hwver", mnf_hwver);

	if (mnf_hwver[0] != '0' || mnf_hwver[1] != '0') {
		hwver = (mnf_hwver[0] - '0') * 10 + (mnf_hwver[1] - '0');
	} else if (mnf_hwver[2] != '0' || mnf_hwver[3] != '0') {
		hwver = (mnf_hwver[2] - '0') * 10 + (mnf_hwver[3] - '0');
	}

	if (!strncmp(mnf_name, "RUT202", 6)) {
		struct led_ctl_entry rut202_anim_cfg[] = {
			LCE_GP(RUT202_GP_2G_LED),     LCE_GP(RUT202_GP_3G_LED),
			LCE_GP(RUT202_GP_4G_LED),     LCE_GP(RUT202_SR_SSID_1_LED),
			LCE_GP(RUT202_SR_SSID_2_LED), LCE_GP(RUT202_SR_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rut202_anim_cfg);
		led_ctl_array_copy(rut202_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	= RUT202_GP_ALL_LEDS;
		gpio_inv_leds	= RUT202_GP_INV_LEDS;
		rst_btn			= RESET_BUTTON_46;
	} else if (!strncmp(mnf_name, "RUT204", 6)) {
		struct led_ctl_entry rut204_anim_cfg[] = {
			LCE_GP(RUT204_GP_GEN_GR_LED),
			LCE_GP(RUT204_GP_SSID_GR_LED),
		};

		arr_len = ARRAYSIZE(rut204_anim_cfg);
		led_ctl_array_copy(rut204_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUT204_GP_ALL_LEDS;
		gpio_inv_leds	     = RUT204_GP_INV_LEDS;
		rst_btn		     = RUT204_GP_RST_BTN;

		prepare_gpio(RUT204_GP_STM_BOOT, true);
		gpio_set_value(RUT204_GP_STM_BOOT, GPIO_OUT_LOW);
		prepare_gpio(RUT204_GP_STM_RESET, true);
		tlt_pulse_reset_gp(RUT204_GP_STM_RESET);
		udelay(100 * 1000); // Wait STM go up
		prepare_gpio(RUT204_STM_TPM_RST, true);
		tlt_pulse_reset_gp(RUT204_STM_TPM_RST);

		prepare_gpio(RUT204_GP_POWER_LED, true);
		gpio_set_value(RUT204_GP_POWER_LED, GPIO_OUT_LOW);
	} else if (!strncmp(mnf_name, "RUT206", 6) || !strncmp(mnf_name, "RUT286", 6)) {
		struct led_ctl_entry rut206_anim_cfg[] = {
			LCE_GP(RUT206_GP_2G_LED),     LCE_GP(RUT206_GP_3G_LED),
			LCE_GP(RUT206_GP_4G_LED),     LCE_SR(RUT206_SR_SSID_1_LED),
			LCE_SR(RUT206_SR_SSID_2_LED), LCE_SR(RUT206_SR_SSID_3_LED),
		};

		if (!strncmp(mnf_name, "RUT286", 6)) {
			prepare_gpio(RUT286_GP_TPM_RESET, true);
			tlt_tpm_reset_gp(RUT286_GP_TPM_RESET);
		}

		arr_len = ARRAYSIZE(rut206_anim_cfg);
		led_ctl_array_copy(rut206_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUT206_GP_ALL_LEDS;
		gpio_inv_leds	     = RUT206_GP_INV_LEDS;
		shiftreg_all_led_on  = RUT206_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUT206_SR_ALL_LED_OFF;
		rst_btn		     = RUT206_RST_BTN;
	} else if (!strncmp(mnf_name, "RUT276", 6)) {
		struct led_ctl_entry rut276_anim_cfg[] = {
			LCE_GP(RUT276_GP_4G_LED),     LCE_GP(RUT276_GP_5G_LED),
		    LCE_SR(RUT276_SR_SSID_1_LED), 	LCE_SR(RUT276_SR_SSID_2_LED),
			LCE_SR(RUT276_SR_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rut276_anim_cfg);
		led_ctl_array_copy(rut276_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUT276_GP_ALL_LEDS;
		gpio_inv_leds	     = RUT276_GP_INV_LEDS;
		shiftreg_all_led_on  = RUT276_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUT276_SR_ALL_LED_OFF;
		rst_btn		     = RUT276_RST_BTN;
	} else if (!strncmp(mnf_name, "RUT261", 6)) {
		struct led_ctl_entry rut261_anim_cfg[] = {
			LCE_GP(RUT261_GP_3G_LED),     LCE_GP(RUT261_GP_4G_LED),
			LCE_GP(RUT261_SR_SSID_1_LED), LCE_GP(RUT261_SR_SSID_2_LED),
			LCE_GP(RUT261_SR_SSID_3_LED), LCE_GP(RUT261_SR_SSID_4_LED),
			LCE_GP(RUT261_SR_SSID_5_LED),
		};

		prepare_gpio(RUT261_POWER_LED, true);
		gpio_set_value(RUT261_POWER_LED, GPIO_OUT_LOW);
		arr_len = ARRAYSIZE(rut261_anim_cfg);
		led_ctl_array_copy(rut261_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds = RUT261_GP_ALL_LEDS;
		gpio_inv_leds = RUT261_GP_INV_LEDS;
		rst_btn	      = RESET_BUTTON_46;
	} else if (!strncmp(mnf_name, "RUT271", 6) || !strncmp(mnf_name, "RUT281", 6)) {
		struct led_ctl_entry rut271_anim_cfg[] = {
			LCE_GP(RUT271_GP_2G_LED),     LCE_GP(RUT271_GP_3G_LED),
			LCE_GP(RUT271_GP_4G_LED),     LCE_GP(RUT271_GP_SSID_1_LED),
			LCE_GP(RUT271_GP_SSID_2_LED), LCE_GP(RUT271_GP_SSID_3_LED),
			LCE_GP(RUT271_GP_SSID_4_LED), LCE_GP(RUT271_GP_SSID_5_LED),
		};

		arr_len = ARRAYSIZE(rut271_anim_cfg);
		led_ctl_array_copy(rut271_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds = RUT271_GP_ALL_LEDS;
		gpio_inv_leds = RUT271_GP_INV_LEDS;
		rst_btn	      = RESET_BUTTON_46;
		factory_din_pin = RUT271_DIN_4_PIN_V5;
		if (hwver < 5 && !strncmp(mnf_name, "RUT271", 6)) {
			factory_din_pin = RUT271_DIN_4_PIN_V0;
		}

		if (!strncmp(mnf_name, "RUT281", 6)) {
			prepare_gpio(RUT281_TPM_RST, true);
			tlt_pulse_reset_gp(RUT281_TPM_RST);
		}

	} else if (!strncmp(mnf_name, "RUT971", 6) || !strncmp(mnf_name, "RUT976", 6) ||
		   !strncmp(mnf_name, "RUT981", 6) || !strncmp(mnf_name, "RUT986", 6)) {
		struct led_ctl_entry rut976_anim_cfg[] = {
			LCE_SR(RUT976_SR_SSID_1_LED), LCE_SR(RUT976_SR_SSID_2_LED),
			LCE_SR(RUT976_SR_SSID_3_LED), LCE_SR(RUT976_SR_SSID_4_LED),
			LCE_SR(RUT976_SR_SSID_5_LED),
		};

		arr_len = ARRAYSIZE(rut976_anim_cfg);
		led_ctl_array_copy(rut976_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUT976_GP_ALL_LEDS;
		gpio_inv_leds	     = RUT976_GP_INV_LEDS;
		shiftreg_all_led_on  = RUT976_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUT976_SR_ALL_LED_OFF;
		rst_btn		     = RUT976_RST_BTN;
		factory_din_pin	     = RUT976_DIN_4_PIN;
	} else if (!strncmp(mnf_name, "OTD144", 6)) {
		struct led_ctl_entry otd144_anim_cfg[] = {
			LCE_GP(OTD144_GP_2G_LED),     LCE_GP(OTD144_GP_3G_LED),	    LCE_GP(OTD144_GP_4G_LED),
			LCE_GP(OTD144_GP_SSID_1_LED), LCE_GP(OTD144_GP_SSID_2_LED), LCE_GP(OTD144_GP_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(otd144_anim_cfg);
		led_ctl_array_copy(otd144_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds = OTD144_GP_ALL_LEDS;
		gpio_inv_leds = OTD144_GP_INV_LEDS;
		rst_btn	      = RESET_BUTTON_46;
	} else {
		printf("Unknown device name: %s\n", mnf_name);
	}

	reserve_gpios();
}
