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
			disable_ctrlc(prev);	/* restore Ctrl-C checking */
	}
}

/* We come here after U-Boot is initialised and ready to process commands */
void main_loop(void)
{
	const char *s;
	int counter = 0;

	bootstage_mark_name(BOOTSTAGE_ID_MAIN_LOOP, "main_loop");

	if (IS_ENABLED(CONFIG_VERSION_VARIABLE))
		env_set("ver", version_string);  /* set version variable */

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
		printf("Press RESET button for more than 5 seconds to run web failsafe mode\n" );
		printf("RESET button is pressed for: %2d second(s)", counter);
		while (!tlt_get_rst_btn_status() && counter < 30) {
			tlt_leds_invert();
			counter++;
			printf("\b\b\b\b\b\b\b\b\b\b\b\b%2d second(s)", counter);
			udelay(1000000);
		}

		printf("\n");
		tlt_leds_on();
		if (counter < 5) {
			printf("RESET button wasn't pressed long enough!\n");
			printf("Continuing normal boot...\n");
		} else if (counter < 30) {
			printf("HTTP server is starting for firmware update...\n");
			wdt_stop_all();
			udelay(3000000);
			run_command("httpd", 0);
		} else {
			printf("RESET button was pressed for too long!\n");
			printf("Continuing normal boot...\n");
		}
	}

	s = bootdelay_process();
	if (cli_process_fdt(&s))
		cli_secure_boot_cmd(s);

	autoboot_command(s);

	cli_loop();
	panic("No CLI available");
}
