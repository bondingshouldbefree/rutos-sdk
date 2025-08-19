/* SPDX-License-Identifier:	GPL-2.0 */
/*
 * Copyright (C) 2019 MediaTek Inc. All Rights Reserved.
 *
 * Author: Weijie Gao <weijie.gao@mediatek.com>
 *
 */

#include <common.h>
#include <command.h>
#include <env.h>
#include <malloc.h>
#include <net.h>
#include <net/tcp.h>
#include <net/httpd.h>
#include <u-boot/md5.h>
#include <u-boot/crc.h>

#include <tlt/fwtool.h>
#include <tlt/leds.h>
#include <tlt/fsupdate.h>

#include "fs.h"

#define MIN_UPLOAD_SIZE 10240 //10 kB
#define MAX_UPLOAD_SIZE 104857600 //100 MB
#define CRC_LEN 10
#define VERSION_LEN 10
#define DEV_NAME_LEN 12

#if CONFIG_WEBUI_FAILSAFE_LEGACY == 1
	#define DO_UPDATE_FW(addr, size) \
		run_commandf("mtd erase firmware && " \
                            "mtd write firmware %x 0 %x\n", \
                            (size_t)addr, size)
#else
	#define DO_UPDATE_FW(addr, size) \
		fsb_update(addr, size)
#endif

enum upload_tp {
	UPL_UNKNOWN,
	UPL_UBOOT,
	UPL_FIRMWARE,
};

struct g_state_t {
	enum upload_tp upl_tp;
	u32 upload_data_id;
	const void *upload_data;
	size_t upload_size;
	int upgrade_success;
	u32 data_step;
	u32 data_offset;
	int data_size;
	void *flash;
	int err;
	int end;
};

static struct g_state_t g_state; 

extern int write_firmware_failsafe_sector(void *flash, size_t data_addr, uint32_t data_size, uint32_t data_offset);
extern uint32_t get_flash_sector_size(void *flash);
extern void* get_flash_pointer(void);

static int output_plain_file(struct httpd_response *response,
	const char *filename)
{
	const struct fs_desc *file;
	int ret = 0;

	file = fs_find_file(filename);

	response->status = HTTP_RESP_STD;

	if (file) {
		response->data = file->data;
		response->size = file->size;
	} else {
		response->data = "Error: file not found";
		response->size = strlen(response->data);
		ret = 1;
	}

	response->info.code = 200;
	response->info.connection_close = 1;
	response->info.content_type = "text/html";

	return ret;
}

static void index_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	if (status == HTTP_CB_NEW)
		output_plain_file(response, "index.html");
}

static void uboot_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	if (status == HTTP_CB_NEW)
		output_plain_file(response, "uboot.html");
}

static void flashing_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	struct httpd_form_value *fw;
	char *end_ptr, buf[DEV_NAME_LEN + 1] = {0};
	ulong crc, crc_current;
	
	if (status == HTTP_CB_NEW)
	{
		if ((fw = httpd_request_find_value(request, "firmware"))) {
			g_state.upl_tp = UPL_FIRMWARE;
		} else if ((fw = httpd_request_find_value(request, "uboot"))) {
			g_state.upl_tp = UPL_UBOOT;
		} else {
			response->info.code = 302;
			response->info.connection_close = 1;
			response->info.location = "/";
			g_state.upl_tp = UPL_UNKNOWN;
			return;
		}

		/*******************
		*  FW VALIDATION  *
		*******************/

		/* Skipping small files < 10 kB */
		if (fw->size < MIN_UPLOAD_SIZE) {
			printf("Found file of size: %u minimal file size allowed:%u\n", fw->size, MIN_UPLOAD_SIZE);
			goto err;
		}

		/* Skipping big files > 100 MB */
		if (fw->size > MAX_UPLOAD_SIZE) {
			printf("Found file of size: %u maximum file size allowed:%u\n", fw->size, MAX_UPLOAD_SIZE);
			goto err;
		}

		if (g_state.upl_tp == UPL_FIRMWARE) {
			/* Validating FW image */
			if (fwtool_validate_manifest((void *)fw->data, fw->size)) {
				printf("Uploaded file was not valid firmware image\n");
				goto err;
			}
		} else if (g_state.upl_tp == UPL_UBOOT) {
			strncpy(buf, (const char *)(fw->data + fw->size - CRC_LEN), CRC_LEN);

			end_ptr = buf;
			crc_current = simple_strtoll(buf, &end_ptr, 10);
			if (!crc_current || end_ptr == buf) {
				printf("Failed to parse crc string\n");
				goto err;
			}

			crc = crc32(0, (unsigned char *)fw->data, fw->size - CRC_LEN);

			if (crc != crc_current) {
				printf("Bad checksum\n");
				goto err;
			}

			printf("Checksum OK\n");

			strncpy(buf, (const char *)(fw->data + fw->size - DEV_NAME_LEN - VERSION_LEN - CRC_LEN), DEV_NAME_LEN);
			if (!strstr(buf, CONFIG_DEVICE_MODEL)) {
				printf("Incompatible device\n");
				goto err;
			}

			printf("Device model OK\n");


			fw->size = fw->size - CRC_LEN;
		}

		g_state.upload_data_id = upload_id;
		g_state.upload_data = fw->data;
		g_state.upload_size = fw->size;
		g_state.data_size = fw->size;
		g_state.upgrade_success = 0;
		g_state.data_offset = 0;
		g_state.flash = NULL;
		g_state.err = 0;
		g_state.end = 0;
		tlt_leds_set_flashing_state(1);
		output_plain_file(response, "flashing.html");
	}

	return;

err:
	g_state.err = 1;
	g_state.upl_tp = UPL_UNKNOWN;
	output_plain_file(response, "fail.html");
}

struct flashing_status {
	char buf[4096];
	int ret;
	int body_sent;
};


static const char* flash_error_m = "<h1 class=\\\"heading\\\" style=\\\"color:red;\\\">FLASHING FAILED</h1>";
static const char* flash_ok_m = "<h1 class=\\\"heading\\\" style=\\\"color:green;\\\">REBOOTING IN PROGRESS</h1>";
static const char* flash_error_d = "Something went wrong during flashing. Please, try again.";
static const char* flash_ok_d = "";

static int update_fw(void)
{
	printf("Updating firmware...");
	return DO_UPDATE_FW(g_state.upload_data, g_state.upload_size);
}

static int update_uboot(void)
{
	printf("Updating U-Boot...");
	int ret = run_commandf("mtd erase u-boot && "
			    "mtd write u-boot %x 0 %x\n",
			    (size_t)g_state.upload_data, g_state.data_size);

	if (!ret) {
		const char *vars[] = { "bootdelay" };
		env_set_default_vars(1, vars, 0);
		env_save();
	}

	return ret;
}

static void result_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	struct flashing_status *st;
	int answ_size;

	u32 size;

	if (status == HTTP_CB_NEW) {
		st = calloc(1, sizeof(*st));
		if (!st) {
			response->info.code = 500;
			return;
		}
		st->ret = -1;
		response->session_data = st;
		response->status = HTTP_RESP_CUSTOM;

		response->info.http_1_0 = 1;
		response->info.content_length = -1;
		response->info.connection_close = 1;
		response->info.content_type = "text/json";
		response->info.code = 200;

		size = http_make_response_header(&response->info,
			st->buf, sizeof(st->buf));

		response->data = st->buf;
		response->size = size;
		
   		return;
	}

	if (status == HTTP_CB_RESPONDING) {

		st = response->session_data;

		if (st->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}

		if (g_state.data_size > 0) {
			if ((g_state.upload_data_id == upload_id) && (g_state.err == 0)) {
				int ret = 1;
				/* FIXME: flashing firmare prevents
				 * this handler executing again with `status == HTTP_CB_RESPONDING`
				 * Thus, message whether flashing succeeded of failed does not
				 * get showed. Maybe fix this later */
				if (g_state.upl_tp == UPL_FIRMWARE) {
					ret = update_fw();
					response->info.connection_pending_close = 1;
				} else if (g_state.upl_tp == UPL_UBOOT) {
					ret = update_uboot();
					response->info.connection_pending_close = 1;
				}

				g_state.err = ret;
				g_state.end = 1;
			}
			else g_state.err = 1;	
		} 
		else g_state.end = 1;


		if ( g_state.err)
		{
			answ_size = snprintf(st->buf, sizeof(st->buf), "{\"finish\":true, \"success\":false, \"main\":\"%s\", \"details\":\"%s\"}", flash_error_m, flash_error_d);
			g_state.upload_data_id = rand();
			tlt_leds_set_flashing_state(0);
			g_state.upl_tp = UPL_UNKNOWN;
		}
		else
		{
			if (g_state.end)
			{
				answ_size = snprintf(st->buf, sizeof(st->buf), "{\"finish\":true, \"success\":true, \"main\":\"%s\", \"details\":\"%s\"}", flash_ok_m, flash_ok_d);
				g_state.upgrade_success = 1;
				g_state.upload_data_id = rand();
				tlt_leds_set_flashing_state(0);
				g_state.upl_tp = UPL_UNKNOWN;
			}
		}	
		
		response->data = st->buf;
		response->size = answ_size;
		st->body_sent = 1;
		return;
	}

	if (status == HTTP_CB_CLOSED) {
		st = response->session_data;
		
		free(response->session_data);
		
		if (g_state.upgrade_success)
			tcp_close_all_conn();
		
	}
}

static void style_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "style.css");
		response->info.content_type = "text/css";
	}
}

static void logo_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "logo.svg");
		response->info.content_type = "text/xml";
	}
}

static void not_found_handler(enum httpd_uri_handler_status status,
	struct httpd_request *request,
	struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "404.html");
		response->info.code = 404;
	}
}

static int start_web_failsafe(void)
{
	struct httpd_instance *inst;

	tlt_leds_set_failsafe_state(1);

	inst = httpd_find_instance(80);
	if (inst)
		httpd_free_instance(inst);

	inst = httpd_create_instance(80);
	if (!inst) {
		printf("Error: failed to create HTTP instance on port 80\n");
		return -1;
	}

	httpd_register_uri_handler(inst, "/", &index_handler, NULL);
	httpd_register_uri_handler(inst, "/index.html", &index_handler, NULL);
	httpd_register_uri_handler(inst, "/uboot.html", &uboot_handler, NULL);
	httpd_register_uri_handler(inst, "/cgi-bin/luci", &index_handler, NULL);
	httpd_register_uri_handler(inst, "/flashing", &flashing_handler, NULL);
	httpd_register_uri_handler(inst, "/result", &result_handler, NULL);
	httpd_register_uri_handler(inst, "/style.css", &style_handler, NULL);
	httpd_register_uri_handler(inst, "/logo.svg", &logo_handler, NULL);
	httpd_register_uri_handler(inst, "", &not_found_handler, NULL);

	net_loop(TCP);

	/* These 2 prevents leds blinking when `httpd` was killed and then
	 * data is being transfered using `tftp` */
	tlt_leds_set_flashing_state(0);
	tlt_leds_set_failsafe_state(0);

	/* Linght them up again */
	tlt_leds_on();

	return 0;
}

static int do_httpd(struct cmd_tbl *cmdtp, int flag, int argc,
	char *const argv[])
{
	int ret;

	printf("\nWeb failsafe UI started\n");
	
	ret = start_web_failsafe();
	if (g_state.upgrade_success)
		do_reset(NULL, 0, 0, NULL);

	return ret;
}

U_BOOT_CMD(httpd, 1, 0, do_httpd,
	"Start failsafe HTTP server", ""
);
