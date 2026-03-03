// SPDX-License-Identifier: GPL-2.0+
/*
 * (C) Copyright 2000
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 */

/* #define	DEBUG	*/

#include <common.h>
#include <autoboot.h>
#include <bootstage.h>
#include <cli.h>
#include <command.h>
#include <console.h>
#include <env.h>
#include <init.h>
#include <net.h>
#include <version_string.h>
#include <efi_loader.h>
#include <linux/delay.h>
#include <wdt.h>

#include <tlt/leds.h>

static void run_preboot_environment_command(void)
{
	char *p;

	p = env_get("preboot");
	if (p != NULL) {
		int prev = 0;

		if (IS_ENABLED(CONFIG_AUTOBOOT_KEYED))
			prev = disable_ctrlc(1); /* disable Ctrl-C checking */

		run_command_list(p, -1, 0);

		if (IS_ENABLED(CONFIG_AUTOBOOT_KEYED))
			disable_ctrlc(prev); /* restore Ctrl-C checking */
	}
}

/* We come here after U-Boot is initialised and ready to process commands */
void main_loop(void)
{
	const char *s;
	int press_time_s = 0;

	bootstage_mark_name(BOOTSTAGE_ID_MAIN_LOOP, "main_loop");

	if (IS_ENABLED(CONFIG_VERSION_VARIABLE))
		env_set("ver", version_string); /* set version variable */

	cli_init();

	if (IS_ENABLED(CONFIG_USE_PREBOOT))
		run_preboot_environment_command();

	if (IS_ENABLED(CONFIG_UPDATE_TFTP))
		update_tftp(0UL, NULL, NULL);

	if (IS_ENABLED(CONFIG_EFI_CAPSULE_ON_DISK_EARLY)) {
		/* efi_init_early() already called */
		if (efi_init_obj_list() == EFI_SUCCESS)
			efi_launch_capsules();
	}

	if (!tlt_get_rst_btn_status()) {
		printf("Press RESET button for more than 5 seconds to run web failsafe mode\n");
		printf("RESET button is pressed for: %2d second(s)", press_time_s);
		printf("Pre-starting network\n");
		/* Set button press blinking state. This helps to prevent slow blinking while
		 * network is being set up when 'httpd' command is triggerend from console */
		tlt_btn_press_blink_set(1);
		tlt_leds_check_btn_blink();
		demand_net_init();
		press_time_s = tlt_leds_check_btn_blink();
		while (!tlt_get_rst_btn_status() && (press_time_s = tlt_leds_check_btn_blink()) < 30) {
			printf("\b\b\b\b\b\b\b\b\b\b\b\b%2d second(s)", press_time_s);
			udelay(100000);
		}

		tlt_btn_press_blink_set(0);
		printf("\nButton held for %d second(s)\n", press_time_s);

		tlt_leds_on();
		if (press_time_s < 5) {
			printf("RESET button wasn't pressed long enough!\n");
			printf("Continuing normal boot...\n");
		} else if (press_time_s < 30) {
			printf("HTTP server is starting for firmware update...\n");
			env_set("httpd_timeout_enabled", "0");
			run_command("httpd", 0);
		} else {
			printf("RESET button was pressed for too long!\n");
#ifdef CONFIG_WDT
			wdt_stop_all();
#endif // CONFIG_WDT
			printf("Continuing normal boot...\n");
		}
	}

#ifdef CONFIG_DIN_SERIAL
	if (!tlt_get_din_pin_status()) {
		printf("HTTP server is starting...\n");
		env_set("httpd_timeout_enabled", "1");
		run_command("httpd", 0);
	}
#endif // CONFIG_DIN_SERIAL

	s = bootdelay_process();
	if (cli_process_fdt(&s))
		cli_secure_boot_cmd(s);

	autoboot_command(s);

	cli_loop();
	panic("No CLI available");
}
