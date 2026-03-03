
#include <common.h>
#include <env.h>
#include <init.h>

#include <tlt/leds.h>
#include <tlt/mnf_info.h>

#include "board.h"

#ifdef CONFIG_BOARD_LATE_INIT

int init_environment(void)
{
	char dev_name[13] = { 0 };

	if (mnf_get_field("name", dev_name)) {
		printf("Failed to read device name from mnf\n");
		printf("Defaulting to %s\n", CONFIG_DEVICE_MODEL_MNF_DEFAULT);
		env_set("mnf_name", CONFIG_DEVICE_MODEL_MNF_DEFAULT);
	}

	env_set("mnf_name", dev_name);

	return 0;
}

int board_late_init(void)
{
	init_environment();
	init_gpio_modes();
	init_led_conf();

	tlt_leds_on();

	return 0;
}
#endif
