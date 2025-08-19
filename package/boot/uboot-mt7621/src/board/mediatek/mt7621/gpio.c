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
#ifdef CONFIG_DEVICE_MODEL_ATRM50
unsigned watchdog_clk	= ATRM50_WD_CLK;
#endif

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
#ifdef CONFIG_DEVICE_MODEL_ATRM50
	prepare_gpio(watchdog_clk, true);
#endif
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

#ifdef CONFIG_DEVICE_MODEL_ATRM50
static void tlt_clock_watchdog(void)
{
	static u8 val = GPIO_OUT_LOW;
	gpio_set_value(watchdog_clk, val ^= 1);
}
#endif

void tlt_leds_on(void)
{
	// Don't shift if value is initialized to zero
	if (shiftreg_inv_leds || shiftreg_eth_leds || shiftreg_all_led_on) {
		control_reg(shiftreg_all_led_on);
	}

	control_gp((gpio_all_leds | gpio_eth_leds) & ~gpio_inv_leds, GPIO_OUT_HIGH);
	control_gp((gpio_all_leds | gpio_eth_leds) & gpio_inv_leds, GPIO_OUT_LOW);
#ifdef CONFIG_DEVICE_MODEL_ATRM50
	tlt_clock_watchdog();
#endif
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

static void tlt_tpm_reset_gp(u32 tpm_rst_gpio) {
	gpio_set_value(tpm_rst_gpio, GPIO_OUT_LOW);
	udelay(50 * 1000);
	gpio_set_value(tpm_rst_gpio, GPIO_OUT_HIGH);
}

static void sr_led_animation(void)
{
	static char index     = 0;
	static char direction = 0;

#ifdef CONFIG_DEVICE_MODEL_ATRM50
	tlt_clock_watchdog();
#endif

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
	return gpio_get_value(RST_BTN);
}

void init_gpio_modes(void)
{
	u32 clean_mask = SYSCTL_GPIO_MODE_SDXC_MASK | SYSCTL_GPIO_MODE_UART3_MASK |
			 SYSCTL_GPIO_MODE_UART2_MASK | SYSCTL_GPIO_MODE_JTAG_MASK | SYSCTL_GPIO_MODE_WDT_MASK;

	MT7621_REG(SYSCTL_GPIO_MODE) &= ~clean_mask;
	MT7621_REG(SYSCTL_GPIO_MODE) |= (clean_mask & SYSCTL_GPIO_MODE_GPIO_FUNC_MASK);
}

void init_led_conf(void)
{
#if defined(CONFIG_DEVICE_MODEL_RUTM)
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

	if (!strncmp(mnf_name, "RUTM08", 6)) {
		prepare_gpio(RUTM08_GP_SHIFT_OE, true);
		gpio_set_value(RUTM08_GP_SHIFT_OE, GPIO_OUT_LOW);
		shiftreg_eth_leds = RUTM08_SR_ETH_LEDS;
	} else if (!strncmp(mnf_name, "RUTM09", 6)) {

		prepare_gpio(RUTM09_GP_SHIFT_OE, true);
		gpio_set_value(RUTM09_GP_SHIFT_OE, GPIO_OUT_LOW);
		struct led_ctl_entry rutm09_anim_cfg[] = {
			LCE_GP(RUTM09_GP_SIM1_LED),    LCE_GP(RUTM09_GP_SIM2_LED),
			LCE_GP(RUTM09_GP_WAN_ETH_LED), LCE_SR(RUTM09_SR_2G_LED),
			LCE_SR(RUTM09_SR_3G_LED),      LCE_SR(RUTM09_SR_4G_LED),
			LCE_SR(RUTM09_SR_SSID_1_LED),  LCE_SR(RUTM09_SR_SSID_2_LED),
			LCE_SR(RUTM09_SR_SSID_3_LED),  LCE_SR(RUTM09_SR_SSID_4_LED),
			LCE_SR(RUTM09_SR_SSID_5_LED),
		};

		arr_len = ARRAYSIZE(rutm09_anim_cfg);
		led_ctl_array_copy(rutm09_anim_cfg, led_ctl_array, arr_len);
		shiftreg_all_led_on  = RUTM09_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM09_SR_ALL_LED_OFF;
		gpio_all_leds	     = RUTM09_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM09_SR_ETH_LEDS;
	} else if (!strncmp(mnf_name, "RUTM10", 6)) {
		prepare_gpio(RUTM10_GP_SHIFT_OE, true);
		gpio_set_value(RUTM10_GP_SHIFT_OE, GPIO_OUT_LOW);
		struct led_ctl_entry rutm10_anim_cfg[] = {
			LCE_GP(RUTM10_GP_WIFI_24_LED),
			LCE_GP(RUTM10_GP_WIFI_5_LED),
		};

		arr_len = ARRAYSIZE(rutm10_anim_cfg);
		led_ctl_array_copy(rutm10_anim_cfg, led_ctl_array, arr_len);
		shiftreg_eth_leds = RUTM10_SR_ETH_LEDS;
		gpio_all_leds	  = RUTM10_GP_ALL_LEDS;
	} else if (!strncmp(mnf_name, "RUTM11", 6)) {
		prepare_gpio(RUTM11_GP_SHIFT_OE, true);
		gpio_set_value(RUTM11_GP_SHIFT_OE, GPIO_OUT_LOW);
		struct led_ctl_entry rutm11_anim_cfg[] = {
			LCE_GP(RUTM11_GP_SIM1_LED),
			LCE_GP(RUTM11_GP_SIM2_LED),
			LCE_GP(RUTM11_GP_WAN_WIFI_WIFI_24_LED),
			LCE_GP(RUTM11_GP_WAN_ETH_WIFI_5_LED),
			LCE_SR(RUTM11_SR_2G_LED),
			LCE_SR(RUTM11_SR_3G_LED),
			LCE_SR(RUTM11_SR_4G_LED),
			LCE_SR(RUTM11_SR_SSID_1_LED),
			LCE_SR(RUTM11_SR_SSID_2_LED),
			LCE_SR(RUTM11_SR_SSID_3_LED),
			LCE_SR(RUTM11_SR_SSID_4_LED),
			LCE_SR(RUTM11_SR_SSID_5_LED),
		};

		arr_len = ARRAYSIZE(rutm11_anim_cfg);
		led_ctl_array_copy(rutm11_anim_cfg, led_ctl_array, arr_len);
		shiftreg_all_led_on  = RUTM11_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM11_SR_ALL_LED_OFF;
		gpio_all_leds	     = RUTM11_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM11_SR_ETH_LEDS;

	} else if (!strncmp(mnf_name, "RUTM12", 6)) {
		struct led_ctl_entry rutm12_anim_cfg[] = {
			LCE_GP(RUTM12_GP_SIM1_LED),	   LCE_GP(RUTM12_GP_SIM2_LED),
			LCE_SR(RUTM12_SR_WAN_WIFI_LED),	   LCE_GP(RUTM12_GP_WAN_WIFI_24_LED),
			LCE_GP(RUTM12_GP_WAN_WIFI_50_LED), LCE_GP(RUTM12_GP_WAN_ETH_LED),
			LCE_GP(RUTM12_GP_3G_1_LED),	   LCE_GP(RUTM12_GP_4G_1_LED),
			LCE_GP(RUTM12_GP_SSID_1_1_LED),	   LCE_GP(RUTM12_GP_SSID_2_1_LED),
			LCE_GP(RUTM12_GP_SSID_3_1_LED),	   LCE_SR(RUTM12_SR_3G_2_LED),
			LCE_SR(RUTM12_SR_4G_2_LED),	   LCE_SR(RUTM12_SR_SSID_1_2_LED),
			LCE_SR(RUTM12_SR_SSID_2_2_LED),	   LCE_SR(RUTM12_SR_SSID_3_2_LED),
		};

		arr_len = ARRAYSIZE(rutm12_anim_cfg);
		led_ctl_array_copy(rutm12_anim_cfg, led_ctl_array, arr_len);
		shiftreg_all_led_on  = RUTM12_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM12_SR_ALL_LED_OFF;
		gpio_all_leds	     = RUTM12_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM12_SR_ETH_LEDS;
		/* TODO: May have inverted eth leds <05-12-22, yourname> */

	} else if (!strncmp(mnf_name, "RUTM13", 6)) {
		prepare_gpio(RUTM13_GP_SHIFT_OE, true);
		gpio_set_value(RUTM13_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm13_anim_cfg[] = {
			LCE_GP(RUTM13_GP_SIM1_LED),   LCE_GP(RUTM13_GP_SIM2_LED),
			LCE_SR(RUTM13_SR_VDSL_LED),   LCE_SR(RUTM13_SR_3G_LED),
			LCE_SR(RUTM13_SR_4G_LED),     LCE_SR(RUTM13_SR_SSID_1_LED),
			LCE_SR(RUTM13_SR_SSID_2_LED), LCE_SR(RUTM13_SR_SSID_3_LED),
			LCE_SR(RUTM13_SR_SSID_4_LED), LCE_SR(RUTM13_SR_SSID_5_LED),
		};

		arr_len = ARRAYSIZE(rutm13_anim_cfg);
		led_ctl_array_copy(rutm13_anim_cfg, led_ctl_array, arr_len);
		shiftreg_all_led_on  = RUTM13_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM13_SR_ALL_LED_OFF;
		gpio_all_leds	     = RUTM13_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM13_SR_ETH_LEDS;

	} else if (!strncmp(mnf_name, "RUTM14", 6)) {
		/* TODO:  <05-12-22, yourname> */

		/*u32 rutm14_anim_cfg[] = {*/
		/*RUTM14_SR_SIM1_LED,	      RUTM14_SR_SIM2_LED,   RUTM14_SR_WAN_WIFI_WIFI_24_LED,*/
		/*RUTM14_SR_WAN_ETH_WIFI_5_LED, RUTM14_SR_3G_LED,	    RUTM14_SR_4G_LED,*/
		/*RUTM14_SR_SSID_1_LED,	      RUTM14_SR_SSID_2_LED, RUTM14_SR_SSID_3_LED*/
		/*};*/

		/*led_ctl_array_copy(rutm14_anim_cfg, led_ctl_array,*/
		/*ARRAYSIZE(rutm14_anim_cfg));*/
		/*shiftreg_all_led_on  = RUTM14_SR_ALL_LED_ON;*/
		/*shiftreg_all_led_off = RUTM14_SR_ALL_LED_OFF;*/
	} else if (!strncmp(mnf_name, "RUTM20", 6)) {
		struct led_ctl_entry rutm20_anim_cfg[] = {
			LCE_GP(RUTM20_GP_GEN_GR_LED),
			LCE_GP(RUTM20_GP_SSID_GR_LED),
		};

		arr_len = ARRAYSIZE(rutm20_anim_cfg);
		led_ctl_array_copy(rutm20_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds = RUTM20_GP_ALL_LEDS;
		gpio_eth_leds = RUTM20_GP_ETH_LEDS;
		gpio_inv_leds = RUTM20_GP_INV_LEDS;
	} else if (!strncmp(mnf_name, "RUTM30", 6) || !strncmp(mnf_name, "RUTM31", 6)) {
		struct led_ctl_entry rutm30_anim_cfg[] = {
			LCE_GP(RUTM30_GP_GEN_GR_LED),
			LCE_GP(RUTM30_GP_SSID_GR_LED),
		};

		arr_len = ARRAYSIZE(rutm30_anim_cfg);
		led_ctl_array_copy(rutm30_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds = RUTM30_GP_ALL_LEDS;
		gpio_eth_leds = RUTM30_GP_ETH_LEDS;
		gpio_inv_leds = RUTM30_GP_INV_LEDS;
	} else if (!strncmp(mnf_name, "RUTM50", 6) || !strncmp(mnf_name, "RUTM51", 6)) {
		prepare_gpio(RUTM50_GP_SHIFT_OE, true);
		gpio_set_value(RUTM50_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm50_anim_cfg[] = {
			LCE_GP(RUTM50_GP_SIM1_LED),	LCE_GP(RUTM50_GP_SIM2_LED),
			LCE_GP(RUTM50_GP_WAN_WIFI_LED), LCE_SR(RUTM50_SR_WIFI_24_LEDS),
			LCE_SR(RUTM50_SR_WIFI_5_LEDS),	LCE_GP(RUTM50_GP_WAN_ETH_LED),
			LCE_GP(RUTM50_GP_3G_LED),	LCE_GP(RUTM50_GP_4G_LED),
			LCE_GP(RUTM50_GP_5G_LED),	LCE_GP(RUTM50_GP_SSID_1_LED),
			LCE_GP(RUTM50_GP_SSID_2_LED),	LCE_GP(RUTM50_GP_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rutm50_anim_cfg);
		led_ctl_array_copy(rutm50_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUTM50_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM50_SR_ETH_LEDS;
		shiftreg_all_led_on  = RUTM50_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM50_SR_ALL_LED_OFF;
		if (!strncmp(mnf_branch, "A", 1) && full_hwver < 202) {
			shiftreg_inv_leds    = RUTM50_BR_A_SR_INV_LEDS;
		} else {
			shiftreg_inv_leds    = RUTM50_SR_INV_LEDS;
		}
	} else if (!strncmp(mnf_name, "RUTM52", 6)) {
		prepare_gpio(RUTM52_GP_SHIFT_OE, true);
		gpio_set_value(RUTM52_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm52_anim_cfg[] = {
			LCE_SR(RUTM52_SR_SIM1_LED),	LCE_SR(RUTM52_SR_SIM2_LED),
			LCE_SR(RUTM52_SR_WAN_WIFI_LED), LCE_GP(RUTM52_GP_WIFI_24_LEDS),
			LCE_GP(RUTM52_GP_WIFI_50_LEDS), LCE_SR(RUTM52_SR_WAN_ETH_LED),
			LCE_SR(RUTM52_SR_3G_1_LED),	LCE_SR(RUTM52_SR_4G_1_LED),
			LCE_SR(RUTM52_SR_5G_1_LED),	LCE_SR(RUTM52_SR_SSID_1_1_LED),
			LCE_SR(RUTM52_SR_SSID_2_1_LED), LCE_SR(RUTM52_SR_SSID_3_1_LED),
			LCE_SR(RUTM52_SR_3G_2_LED),	LCE_SR(RUTM52_SR_4G_2_LED),
			LCE_SR(RUTM52_SR_5G_2_LED),	LCE_SR(RUTM52_SR_SSID_1_2_LED),
			LCE_SR(RUTM52_SR_SSID_2_2_LED), LCE_SR(RUTM52_SR_SSID_3_2_LED),
		};

		arr_len = ARRAYSIZE(rutm52_anim_cfg);
		led_ctl_array_copy(rutm52_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUTM52_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM52_SR_ETH_LEDS;
		shiftreg_inv_leds    = RUTM52_SR_INV_LEDS;
		shiftreg_all_led_on  = RUTM52_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM52_SR_ALL_LED_OFF;
	} else if (!strncmp(mnf_name, "RUTM54", 6)) {
		prepare_gpio(RUTM54_GP_SHIFT_OE, true);
		gpio_set_value(RUTM54_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm54_anim_cfg[] = {
			LCE_GP(RUTM54_GP_SIM1_LED),	LCE_GP(RUTM54_GP_SIM2_LED),
			LCE_GP(RUTM54_GP_WAN_WIFI_LED), LCE_SR(RUTM54_SR_WIFI_24_LEDS),
			LCE_SR(RUTM54_SR_WIFI_50_LEDS), LCE_GP(RUTM54_GP_WAN_ETH_LED),
			LCE_GP(RUTM54_GP_3G_LED),	LCE_GP(RUTM54_GP_4G_LED),
			LCE_GP(RUTM54_GP_5G_LED),	LCE_GP(RUTM54_GP_SSID_1_LED),
			LCE_GP(RUTM54_GP_SSID_2_LED),	LCE_GP(RUTM54_GP_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rutm54_anim_cfg);
		led_ctl_array_copy(rutm54_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUTM54_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM54_SR_ETH_LEDS;
		shiftreg_all_led_on  = RUTM54_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM54_SR_ALL_LED_OFF;
	} else if (!strncmp(mnf_name, "RUTM55", 6)) {
		prepare_gpio(RUTM55_GP_SHIFT_OE, true);
		gpio_set_value(RUTM55_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm55_anim_cfg[] = {
			LCE_SR(RUTM55_SR_3G_LED),     LCE_SR(RUTM55_SR_4G_LED),
			LCE_SR(RUTM55_SR_5G_LED),     LCE_SR(RUTM55_SR_SSID_1_LED),
			LCE_SR(RUTM55_SR_SSID_2_LED), LCE_SR(RUTM55_SR_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rutm55_anim_cfg);
		led_ctl_array_copy(rutm55_anim_cfg, led_ctl_array, arr_len);
		shiftreg_eth_leds    = RUTM55_SR_ETH_LEDS;
		shiftreg_all_led_on  = RUTM55_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM55_SR_ALL_LED_OFF;

		shiftreg_data = RUTM55_SHIFTREG_DATA;
		shiftreg_clk  = RUTM55_SHIFTREG_CLK;
		shiftreg_latch = RUTM55_SHIFTREG_LATCH;
	} else if (!strncmp(mnf_name, "RUTM56", 6)) {
		prepare_gpio(RUTM56_GP_TPM_RESET, true);
		tlt_tpm_reset_gp(RUTM56_GP_TPM_RESET);

		struct led_ctl_entry rutm56_anim_cfg[] = {
			LCE_SR(RUTM56_SR_SIM1_LED),	LCE_SR(RUTM56_SR_SIM2_LED),
			LCE_SR(RUTM56_SR_WAN_WIFI_LED), LCE_GP(RUTM56_GP_WIFI_24_LEDS),
			LCE_GP(RUTM56_GP_WIFI_50_LEDS), LCE_SR(RUTM56_SR_WAN_ETH_LED),
			LCE_SR(RUTM56_SR_3G_1_LED),	LCE_SR(RUTM56_SR_4G_1_LED),
			LCE_SR(RUTM56_SR_5G_1_LED),	LCE_SR(RUTM56_SR_SSID_1_1_LED),
			LCE_SR(RUTM56_SR_SSID_2_1_LED), LCE_SR(RUTM56_SR_SSID_3_1_LED),
			LCE_SR(RUTM56_SR_2G_2_LED),	LCE_SR(RUTM56_SR_3G_2_LED),
			LCE_SR(RUTM56_SR_4G_2_LED),	LCE_SR(RUTM56_SR_SSID_1_2_LED),
			LCE_SR(RUTM56_SR_SSID_2_2_LED), LCE_SR(RUTM56_SR_SSID_3_2_LED),
		};

		arr_len = ARRAYSIZE(rutm56_anim_cfg);
		led_ctl_array_copy(rutm56_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUTM56_GP_ALL_LEDS;
		gpio_eth_leds	     = RUTM56_GP_ETH_LEDS;
		shiftreg_eth_leds    = RUTM56_SR_ETH_LEDS;
		shiftreg_inv_leds    = RUTM56_SR_INV_LEDS;
		shiftreg_all_led_on  = RUTM56_SR_ALL_LED_ON;
		shiftreg_all_led_off = RUTM56_SR_ALL_LED_OFF;

	} else if (!strncmp(mnf_name, "RUTM59", 6)) {
		prepare_gpio(RUTM59_GP_SHIFT_OE, true);
		gpio_set_value(RUTM59_GP_SHIFT_OE, GPIO_OUT_LOW);

		struct led_ctl_entry rutm59_anim_cfg[] = {
			LCE_GP(RUTM59_GP_SIM1_LED),    LCE_GP(RUTM59_GP_SIM2_LED),
			LCE_GP(RUTM59_GP_WAN_ETH_LED), LCE_GP(RUTM59_GP_3G_LED),
			LCE_GP(RUTM59_GP_4G_LED),      LCE_GP(RUTM59_GP_5G_LED),
			LCE_GP(RUTM59_GP_SSID_1_LED),  LCE_GP(RUTM59_GP_SSID_2_LED),
			LCE_GP(RUTM59_GP_SSID_3_LED),
		};

		arr_len = ARRAYSIZE(rutm59_anim_cfg);
		led_ctl_array_copy(rutm59_anim_cfg, led_ctl_array, arr_len);
		gpio_all_leds	     = RUTM59_GP_ALL_LEDS;
		shiftreg_eth_leds    = RUTM59_SR_ETH_LEDS;
		shiftreg_inv_leds    = RUTM59_SR_INV_LEDS;
	} else if (!strncmp(mnf_name, "RUTMR1", 6)) {
		/* TODO:  <05-12-22, yourname> */

		/*u32 rutmR1_anim_cfg[] = { RUTMR1_SIM1_LED,   RUTMR1_SIM2_LED,  RUTMR1_SSID_1_LED, RUTMR1_SSID_2_LED,*/
		/*RUTMR1_SSID_3_LED, RUTMR1_3G_4G_LED, RUTMR1_ETH_MOB_LED };*/

		/*led_ctl_array_copy(rutmR1_anim_cfg, led_ctl_array,*/
		/*ARRAYSIZE(rutmR1_anim_cfg));*/
		/*shiftreg_all_led_on  = RUTMR1_ALL_LED_ON;*/
		/*shiftreg_all_led_off = RUTMR1_ALL_LED_OFF;*/
	}
#elif defined(CONFIG_DEVICE_MODEL_TAP200)
	struct led_ctl_entry tap200_anim_cfg[] = {
		LCE_GP(TAP200_GP_POWER_LED),
		LCE_GP(TAP200_GP_ETH_LEDS),
	};
	arr_len = ARRAYSIZE(tap200_anim_cfg);
	led_ctl_array_copy(tap200_anim_cfg, led_ctl_array, arr_len);
	gpio_all_leds = TAP200_GP_ALL_LEDS;
	gpio_inv_leds = TAP200_GP_POWER_LED;
#elif defined(CONFIG_DEVICE_MODEL_ATRM50)

struct led_ctl_entry atrm50_anim_cfg[] = {
		LCE_SR(ATRM50_SR_SIM1_LED),    LCE_SR(ATRM50_SR_SIM2_LED),     LCE_SR(ATRM50_SR_WAN_WIFI_LED),
		LCE_SR(ATRM50_SR_WAN_ETH_LED), LCE_SR(ATRM50_SR_WIFI_24_LEDS), LCE_SR(ATRM50_SR_WIFI_5_LEDS),
		LCE_SR(ATRM50_SR_3G_LED),      LCE_SR(ATRM50_SR_4G_LED),       LCE_SR(ATRM50_SR_5G_LED),
		LCE_SR(ATRM50_SR_SSID_1_LED),  LCE_SR(ATRM50_SR_SSID_2_LED),   LCE_SR(ATRM50_SR_SSID_3_LED),
	};

	arr_len = ARRAYSIZE(atrm50_anim_cfg);
	led_ctl_array_copy(atrm50_anim_cfg, led_ctl_array, arr_len);

	shiftreg_inv_leds    = ATRM50_SR_INV_LEDS;
	shiftreg_all_led_on  = ATRM50_SR_ALL_LED_ON;
	shiftreg_all_led_off = ATRM50_SR_ALL_LED_OFF;
	shiftreg_eth_leds    = ATRM50_SR_ETH_LEDS;

	prepare_gpio(ATRM50_GP_SHIFT_OE, true);
	gpio_set_value(ATRM50_GP_SHIFT_OE, GPIO_OUT_LOW);

	prepare_gpio(ATRM50_GP_TPM_RESET, true);
	tlt_tpm_reset_gp(ATRM50_GP_TPM_RESET);

	shiftreg_latch = ATRM50_SHIFTREG_LATCH;

#elif defined(CONFIG_DEVICE_MODEL_OTD5)
	struct led_ctl_entry otd500_anim_cfg[] = {
		LCE_GP(OTD500_GP_3G_LED),     LCE_GP(OTD500_GP_4G_LED),	    LCE_GP(OTD500_GP_5G_LED),
		LCE_GP(OTD500_GP_SSID_1_LED), LCE_GP(OTD500_GP_SSID_2_LED), LCE_GP(OTD500_GP_SSID_3_LED),
	};

	arr_len = ARRAYSIZE(otd500_anim_cfg);
	led_ctl_array_copy(otd500_anim_cfg, led_ctl_array, arr_len);
	gpio_all_leds = OTD500_GP_ALL_LEDS;

#else
	/*Reserved*/
#endif

	reserve_gpios();
}
