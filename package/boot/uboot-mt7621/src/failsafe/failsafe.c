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

#include "asm/global_data.h"
#include <time.h>

#define MIN_UPLOAD_SIZE 10240 //10 kB
#define MAX_UPLOAD_SIZE 104857600 //100 MB
#define CRC_LEN		10
#define VERSION_LEN	10
#define DEV_NAME_LEN	12

int fs_allow_external_tcp_loop_execution	  = 0;
int fs_start_fw_flashing			  = 0;
static int fs_client_was_informed_of_flashing_end = 0;
extern int fs_finished_responding_to_all_requests;

#ifdef CONFIG_TLT_NAND_BOOTCMDS
extern int fs_nand_image_writing_progress;
extern int fs_nand_erase_block_scan_progress;
extern int fs_nand_formatting_progress;
extern int fs_nand_reading_progress;
#define DO_UPDATE_FW(addr, size) fsb_update(addr, size)

#elif CONFIG_TLT_EMMCGPP_BOOTCMDS
extern int fs_mmc_erasing_progress;
extern int fs_mmc_image_writing_progress;
#define DO_UPDATE_FW(addr, size) fsb_update(addr, size)

#elif CONFIG_WEBUI_FAILSAFE_LEGACY
extern int fs_nor_erasing_progress;
extern int fs_nor_image_writing_progress;
#define DO_UPDATE_FW(addr, size)                                                                             \
	run_commandf("mtd erase firmware && "                                                                \
		     "mtd write firmware %x 0 %x\n",                                                         \
		     (size_t)addr, size)
#endif

// Gives access to a global uboot data struct
DECLARE_GLOBAL_DATA_PTR;

enum upload_tp {
	UPL_UNKNOWN,
	UPL_UBOOT,
	UPL_FIRMWARE,
};

enum image_validation_status {
	OK,
	BAD_FW_DEV_MODEL,
	BAD_FW_MANIFEST,
	BAD_UBOOT_CHECKSUM,
	BAD_UBOOT_DEV_MODEL,
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
	enum image_validation_status image_validation_status;
	int image_flashing_err;
	int end;
};

static struct g_state_t g_state;

extern int write_firmware_failsafe_sector(void *flash, size_t data_addr, uint32_t data_size,
					  uint32_t data_offset);
extern uint32_t get_flash_sector_size(void *flash);
extern void *get_flash_pointer(void);

static int output_plain_file(struct httpd_response *response, const char *filename)
{
	struct fs_desc file = { 0 };
	int ret		    = 0;

	ret = fs_find_file(filename, &file);

	response->status = HTTP_RESP_STD;

	if (ret) {
		response->data = file.data;
		response->size = file.len;
	} else {
		response->data = "Error: file not found";
		response->size = strlen(response->data);
		ret	       = 1;
	}

	response->info.code		= 200;
	response->info.connection_close = 1;
	response->info.content_type	= "text/html";

	return ret;
}

static void index_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			  struct httpd_response *response)
{
	if (status == HTTP_CB_NEW)
		output_plain_file(response, "/index.html");
}

static void uboot_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			  struct httpd_response *response)
{
	if (status == HTTP_CB_NEW)
		output_plain_file(response, "/uboot.html");
}

/*  A response to a request that is sent by the client from /index.html or /uboot.html after submit button is pressed.
 *  Here we ensure that the uploaded image is valid. If it is we proceed to load /flashing.html from where /update_image
 *  is requested
 */

static void flashing_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			     struct httpd_response *response)
{
	struct httpd_form_value *fw;
	char *end_ptr, buf[DEV_NAME_LEN + 1] = { 0 };
	ulong crc, crc_current;
	int ret;

	if (status == HTTP_CB_NEW) {
		if ((fw = httpd_request_find_value(request, "firmware"))) {
			g_state.upl_tp = UPL_FIRMWARE;
		} else if ((fw = httpd_request_find_value(request, "uboot"))) {
			g_state.upl_tp = UPL_UBOOT;
		} else {
			response->info.code		= 302;
			response->info.connection_close = 1;
			response->info.location		= "/";
			g_state.upl_tp			= UPL_UNKNOWN;
			return;
		}

		if (g_state.upl_tp == UPL_FIRMWARE) {
			ret = fwtool_validate_manifest((void *)fw->data, fw->size);
			if (ret == FWTOOL_NAME_MISMATCH) {
				printf("Using firmware image meant for another device\n");
				printf("You need %s*\n", CONFIG_DEVICE_MODEL_MANIFEST);
				g_state.image_validation_status = BAD_FW_DEV_MODEL;
				goto err;
			} else if (ret == FWTOOL_ERROR_INVALID_FILE) {
				printf("Uploaded file was not a valid firmware image\n");
				g_state.image_validation_status = BAD_FW_MANIFEST;
				goto err;
			}
		} else if (g_state.upl_tp == UPL_UBOOT) {
			strncpy(buf, (const char *)(fw->data + fw->size - CRC_LEN), CRC_LEN);

			end_ptr	    = buf;
			crc_current = simple_strtoll(buf, &end_ptr, 10);
			if (!crc_current || end_ptr == buf) {
				printf("Failed to parse crc string\n");
				g_state.image_validation_status = BAD_UBOOT_CHECKSUM;
				goto err;
			}

			crc = crc32(0, (unsigned char *)fw->data, fw->size - CRC_LEN);

			if (crc != crc_current) {
				printf("Bad checksum\n");
				g_state.image_validation_status = BAD_UBOOT_CHECKSUM;
				goto err;
			}

			printf("Checksum OK\n");

			strncpy(buf,
				(const char *)(fw->data + fw->size - DEV_NAME_LEN - VERSION_LEN - CRC_LEN),
				DEV_NAME_LEN);
			if (!strstr(buf, CONFIG_DEVICE_MODEL)) {
				printf("Incompatible device\n");
				g_state.image_validation_status = BAD_UBOOT_DEV_MODEL;
				goto err;
			}

			printf("Device model OK\n");

			fw->size = fw->size - CRC_LEN;
		}

		g_state.upload_data_id		= upload_id;
		g_state.upload_data		= fw->data;
		g_state.upload_size		= fw->size;
		g_state.data_size		= fw->size;
		g_state.data_offset		= 0;
		g_state.flash			= NULL;
		g_state.image_validation_status = OK;
		fs_start_fw_flashing = 0;
		g_state.image_flashing_err	= 0;
		tlt_leds_set_flashing_state(1);
		output_plain_file(response, "/flashing.html");
	}

	return;

err:
	g_state.upl_tp = UPL_UNKNOWN;
	output_plain_file(response, "/fail.html");
}

struct response {
	char buf[4096];
	int body_sent;
};

/*  A response to a request that is sent by the client from /fail.html in case a selected image
 *  does not pass validation steps
 */

static void validation_status_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
				      struct httpd_response *response)
{
	struct response *resp;

	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->info.code		= 200;
		response->status		= HTTP_RESP_CUSTOM;
		response->info.http_1_0		= 1;
		response->info.connection_close = 1;
		response->info.content_length = -1;
		response->info.content_type   = "text/json";
		char header_buf[128];
		u32 size       = http_make_response_header(&response->info, header_buf, sizeof(header_buf));
		response->data = header_buf;
		response->size = size;
		return;
	} else if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;
		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}
		char error_clarification[10] = "";
		if (g_state.image_validation_status == BAD_FW_DEV_MODEL) {
			snprintf(error_clarification, sizeof(error_clarification), "%s",
				 CONFIG_DEVICE_MODEL_MANIFEST);
		} else if (g_state.image_validation_status == BAD_UBOOT_DEV_MODEL) {
			snprintf(error_clarification, sizeof(error_clarification), "%s", CONFIG_DEVICE_MODEL);
		}
		response->size = snprintf(resp->buf, sizeof(resp->buf),
					  "{\"flash_error\":\"%d\", \"error_clarification\":\"%s*\"}",
					  g_state.image_validation_status, error_clarification);

		response->info.connection_pending_close = 1;
		response->data	= resp->buf;
		resp->body_sent = 1;
		return;
	} else if (status == HTTP_CB_CLOSED) {
		free(response->session_data);
		return;
	}
}

/*  A response to a request that is sent by the client as submit button is pressed. We respond with device's
 *  RAM size so that on client side we could ensure that the client does not upload an image that does not fit into RAM
 */

static void ram_size_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			     struct httpd_response *response)
{
	struct response *resp;

	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->info.code		= 200;
		response->status		= HTTP_RESP_CUSTOM;
		response->info.http_1_0		= 1;
		response->info.connection_close = 1;
		response->info.content_length = -1;
		response->info.content_type   = "text/json";
		char header_buf[128];
		u32 size       = http_make_response_header(&response->info, header_buf, sizeof(header_buf));
		response->data = header_buf;
		response->size = size;
		return;
	} else if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;
		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}
		response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"ram_size\":%u}", gd->ram_size);
		response->info.connection_pending_close = 1;
		response->data	= resp->buf;
		resp->body_sent = 1;
		return;
	} else if (status == HTTP_CB_CLOSED) {
		free(response->session_data);
		return;
	}
}

/*  A response to a request that is sent by the client periodically the moment flashing process begins.
 *  Used to bring the info on flashing progress back to the client.
 */

static void progress_status_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
				    struct httpd_response *response)
{
	struct response *resp;
	static int definitive_result_was_sent = 0;

	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->status       = HTTP_RESP_CUSTOM;
		response->info.http_1_0		= 1;
		response->info.content_length 	= -1;
		response->info.connection_close = 1;
		response->info.content_type	= "text/json";
		response->info.code		= 200;

		u32 size = http_make_response_header(&response->info, resp->buf, sizeof(resp->buf));
		response->data = resp->buf;
		response->size = size;
		return;
	} else if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;
		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}
		if (definitive_result_was_sent){
			fs_client_was_informed_of_flashing_end = 1;
		}
		definitive_result_was_sent = 0;
		char result[10]			      = "unknown";
		if (g_state.image_flashing_err) {
			snprintf(result, sizeof(result), "failed");
			definitive_result_was_sent = 1;

		#ifdef CONFIG_TLT_EMMCGPP_BOOTCMDS
			} else if (fs_mmc_erasing_progress == 100 && fs_mmc_image_writing_progress == 100) {
				snprintf(result, sizeof(result), "success");
				definitive_result_was_sent = 1;
			}

			response->size = snprintf(
			resp->buf, sizeof(resp->buf),
			"{\"erase_progress\":\"%d\",\"writing_progress\":\"%d\",\"result\":\"%s\"}",
			fs_mmc_erasing_progress, fs_mmc_image_writing_progress, result);

		#elif CONFIG_TLT_NAND_BOOTCMDS
			} else if (fs_nand_image_writing_progress == 100 &&
				fs_nand_erase_block_scan_progress == 100 && fs_nand_formatting_progress == 100 &&
				fs_nand_reading_progress == 100) {
				snprintf(result, sizeof(result), "success");
				definitive_result_was_sent = 1;
			}

			response->size = snprintf(
			resp->buf, sizeof(resp->buf),
			"{\"scanning_progress\":\"%d\", \"writing_progress\":\"%d\", \"formatting_progress\":\"%d\", \"reading_progress\":\"%d\", \"result\":\"%s\"}",
			fs_nand_erase_block_scan_progress, fs_nand_image_writing_progress, fs_nand_formatting_progress,
			fs_nand_reading_progress, result);

		#elif CONFIG_WEBUI_FAILSAFE_LEGACY
			} else if (fs_nor_erasing_progress == 100 && fs_nor_image_writing_progress == 100) {
				snprintf(result, sizeof(result), "success");
				definitive_result_was_sent = 1;
			}
			
			response->size = snprintf(
			resp->buf, sizeof(resp->buf),
			"{\"erase_progress\":\"%d\",\"writing_progress\":\"%d\",\"result\":\"%s\"}",
			fs_nor_erasing_progress, fs_nor_image_writing_progress, result);
		#endif
		response->info.connection_pending_close = 1;
		response->data				= resp->buf;
		resp->body_sent				= 1;
	}
	if (status == HTTP_CB_CLOSED) {
		free(response->session_data);
		return;
	}
}

/* A response to a request that is sent by the client as flashing.html page is loaded.
 * Used to bring back the info on whether uboot or firmware image was uploaded.
 * Needed for client side logic.
 */

static void image_type_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			       struct httpd_response *response)
{
	struct response *resp;
	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->info.code		= 200;
		response->status		= HTTP_RESP_CUSTOM;
		response->info.http_1_0		= 1;
		response->info.connection_close = 1;
		response->info.content_length = -1;
		response->info.content_type   = "text/json";
		char header_buf[128];
		u32 size       = http_make_response_header(&response->info, header_buf, sizeof(header_buf));
		response->data = header_buf;
		response->size = size;
		return;
	} else if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;
		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}
		if (g_state.upl_tp == UPL_UBOOT) {
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"image_type\":\"uboot\"}");
			fs_allow_external_tcp_loop_execution = 0;
		} else if (g_state.upl_tp == UPL_FIRMWARE) {
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"image_type\":\"firmware\"}");
			fs_allow_external_tcp_loop_execution = 1;
		}
		response->info.connection_pending_close = 1;
		response->data				= resp->buf;
		resp->body_sent = 1;
		return;
	} if (status == HTTP_CB_CLOSED) {
		free(response->session_data);
		return;
	}
}

/* A response to a request that is sent by the client as flashing.html page is loaded.
 * Used to bring back the info on the type of memory device uses. Based on that progress bars will show up
 * If it has NAND - 4 progress bars and eMMC or NOR - 2 bars.
 */

static void dev_memory_type_handler(enum httpd_uri_handler_status status,
					       struct httpd_request *request, struct httpd_response *response)
{
	struct response *resp;

	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->info.code		= 200;
		response->status		= HTTP_RESP_CUSTOM;
		response->info.http_1_0		= 1;
		response->info.connection_close = 1;
		response->info.content_length = -1;
		response->info.content_type   = "text/json";
		char header_buf[128];
		u32 size       = http_make_response_header(&response->info, header_buf, sizeof(header_buf));
		response->data = header_buf;
		response->size = size;
	} else if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;
		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}
		
		#ifdef CONFIG_WEBUI_FAILSAFE_LEGACY
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"dev_memory_type\":\"NOR\"}");
		#elif CONFIG_TLT_EMMCGPP_BOOTCMDS
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"dev_memory_type\":\"MMC\"}");
		#elif CONFIG_TLT_NAND_BOOTCMDS
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"dev_memory_type\":\"NAND\"}");
		#endif

		response->info.connection_pending_close = 1;
		response->data				= resp->buf;
		resp->body_sent = 1;
		return;
	} if (status == HTTP_CB_CLOSED) {
		free(response->session_data);
		return;
	}
}

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
		const char *const vars[] = { "bootdelay" };
		env_set_default_vars(1, (char *const *)vars, 0);
		env_save();
	}

	return ret;
}

/* A response to a request that is sent by the client after /flashing.html page is loaded.
 * Here the flashing process is only executed for u-boot. In case of FW, it only sets a flag
 * that FW flashing can commence.
 */

static void update_image_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
				 struct httpd_response *response)
{
	struct response *resp;
	if (status == HTTP_CB_NEW) {
		resp = calloc(1, sizeof(*resp));
		if (!resp) {
			response->info.code = 500;
			return;
		}
		response->session_data = resp;
		response->status       = HTTP_RESP_CUSTOM;

		response->info.http_1_0		= 1;
		response->info.content_length 	= -1;
		response->info.connection_close = 1;
		response->info.content_type	= "text/json";
		response->info.code		= 200;

		u32 size = http_make_response_header(&response->info, resp->buf, sizeof(resp->buf));

		response->data = resp->buf;
		response->size = size;

		return;
	}

	if (status == HTTP_CB_RESPONDING) {
		resp = response->session_data;

		if (resp->body_sent) {
			response->status = HTTP_RESP_NONE;
			return;
		}

		if ((g_state.upload_data_id == upload_id) && (g_state.image_validation_status == OK)) {
			if (g_state.upl_tp == UPL_FIRMWARE) {
				fs_start_fw_flashing = 1;
				response->info.connection_pending_close = 1;
			} else if (g_state.upl_tp == UPL_UBOOT) {
				if (update_uboot()) {
					g_state.image_flashing_err = 1;
				}
				response->info.connection_pending_close = 1;
			}
		} else {
			g_state.image_flashing_err = 1;
		}

		if (g_state.upl_tp == UPL_FIRMWARE) {
			response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"outcome\":\"flashing_starting\"}");
			response->data = resp->buf;
			resp->body_sent = 1;
		}

		if (g_state.upl_tp == UPL_UBOOT) {
			if (g_state.image_flashing_err) {
				response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"outcome\":\"failed\"}");
			} else {
				g_state.upgrade_success = 1;
				response->size = snprintf(resp->buf, sizeof(resp->buf), "{\"outcome\":\"succeeded\"}");
			}
			response->data = resp->buf;
			resp->body_sent  = 1;
		}
		return;
	}

	if (status == HTTP_CB_CLOSED) {
		if (g_state.upl_tp == UPL_FIRMWARE) {
			free(response->session_data);
		}

		if (g_state.upl_tp == UPL_UBOOT) {
			free(response->session_data);
			if (g_state.upgrade_success) {
				tcp_close_all_conn();
			}
		}

		return;
	}
}

/*
 * This function does FW flashing and is called inside of the net loop when certain flags are raised.
 * Note that we explicitly included request handling inside of the fw flashing functions such as
 * format() or flash_image(). That is done so that during fw image flashing process
 * the server would still respond to /progress_status requests
 */

void try_to_flash_new_fw_image(void){
	if (g_state.upgrade_success || g_state.image_flashing_err)
		return;
	if ((g_state.upload_data_id != upload_id) || (g_state.image_validation_status != OK) || (update_fw())) {
		fs_start_fw_flashing = 0;
		g_state.image_flashing_err = 1;
		tlt_leds_set_failsafe_state(1);
		tcp_close_all_conn();

		fs_client_was_informed_of_flashing_end = 0;

		#ifdef CONFIG_WEBUI_FAILSAFE_LEGACY
			fs_nor_erasing_progress = 0;
			fs_nor_image_writing_progress = 0;

		#elif CONFIG_TLT_EMMCGPP_BOOTCMDS
			fs_mmc_erasing_progress = 0;
			fs_mmc_image_writing_progress = 0;

		#elif CONFIG_TLT_NAND_BOOTCMDS
			fs_nand_image_writing_progress = 0;
			fs_nand_erase_block_scan_progress = 0;
			fs_nand_formatting_progress = 0;
			fs_nand_reading_progress = 0;
		#endif
		return;
	}
	
	fs_start_fw_flashing = 0;
	g_state.upload_data_id = rand();
	tlt_leds_set_flashing_state(0);

	unsigned long start_time = get_timer_us_long(0);
	while (!fs_client_was_informed_of_flashing_end && get_timer_us_long(start_time) < 5000000) {
		execute_tcp_net_loop_once();
	}

	if (!g_state.image_flashing_err) {
		g_state.upgrade_success = 1;
	}
	
	/* In some net configurations one tcp connection does not close after a successful
	 * fw flash, therefore we just reset all connections and in such a way exit the net (http) loop
	 */
	tcp_reset_all_conn(); 
	return;
}

static void style_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			  struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "/style.css");
		response->info.content_type = "text/css";
	}
}

static void js_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
		       struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "/failsafe.js");
		response->info.content_type = "text/javascript";
	}
}

static void logo_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			 struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "/logo.svg");
		response->info.content_type = "text/xml";
	}
}

static void not_found_handler(enum httpd_uri_handler_status status, struct httpd_request *request,
			      struct httpd_response *response)
{
	if (status == HTTP_CB_NEW) {
		output_plain_file(response, "/404.html");
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
	httpd_register_uri_handler(inst, "/update_image", &update_image_handler, NULL);
	httpd_register_uri_handler(inst, "/style.css", &style_handler, NULL);
	httpd_register_uri_handler(inst, "/logo.svg", &logo_handler, NULL);
	httpd_register_uri_handler(inst, "/validation_status", &validation_status_handler, NULL);
	httpd_register_uri_handler(inst, "/ram_size", &ram_size_handler, NULL);
	httpd_register_uri_handler(inst, "/progress_status", &progress_status_handler, NULL);
	httpd_register_uri_handler(inst, "/image_type", &image_type_handler, NULL);
	httpd_register_uri_handler(inst, "/dev_memory_type", &dev_memory_type_handler, NULL);
	httpd_register_uri_handler(inst, "/failsafe.js", &js_handler, NULL);
	httpd_register_uri_handler(inst, "", &not_found_handler, NULL);

	g_state.upgrade_success = 0;
	while (!g_state.upgrade_success) {
		if (net_loop(TCP) == -EINTR)
			break;
	}
	fs_allow_external_tcp_loop_execution = 0;

	/* These 2 prevents leds blinking when `httpd` was killed and then
	 * data is being transfered using `tftp` */
	tlt_leds_set_flashing_state(0);
	tlt_leds_set_failsafe_state(0);

	/* Light them up again */
	tlt_leds_on();

	return 0;
}

// **Web Failsafe:** A request-response structure where client HTTP calls trigger
// server actions defined in specific handlers (see start_web_failsafe).

static int do_httpd(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	int ret;

	printf("\nWeb failsafe UI started\n");

	ret = start_web_failsafe();
	if (g_state.upgrade_success)
		do_reset(NULL, 0, 0, NULL);

	return ret;
}

U_BOOT_CMD(httpd, 1, 0, do_httpd, "Start failsafe HTTP server", "");
