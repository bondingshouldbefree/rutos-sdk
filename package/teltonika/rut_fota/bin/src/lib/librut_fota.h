#pragma once
#include <libubus.h>

typedef enum {
	LRUT_FOTA_OK,
	LRUT_FOTA_UBUS_ERR,
	LRUT_FOTA_ARGUMENT_ERR,
} lrut_fota_t;

struct lrut_fota_process_st {
	int percents;
	char *process;
};

#ifdef MOBILE_SUPPORT
struct lrut_fota_info_modem_st {
	char *id;
	char *modem;
	int modem_size;
	char *modem_version;
};
#endif

struct lrut_fota_info_st {
	char *fw;
	int fw_size;
	char *fw_date;
	char *fw_stable;
	char *fw_stable_date;
	int fw_stable_size;
#ifdef MOBILE_SUPPORT
	struct lrut_fota_info_modem_st *modems;
	int modems_count;
#endif
	char *conn_state;
	uint64_t timestamp;
	bool collect;
};

lrut_fota_t lrut_fota_get_process(struct ubus_context *ubus, struct lrut_fota_process_st *process);
lrut_fota_t lrut_fota_set_process(struct ubus_context *ubus, int percents, char *process);
lrut_fota_t lrut_fota_get_info(struct ubus_context *ubus, struct lrut_fota_info_st *info);
lrut_fota_t lrut_fota_set_conn_state(struct ubus_context *ubus, char *conn_state);
lrut_fota_t lrut_fota_set_fw_info(struct ubus_context *ubus, char *fw_size, char *fw, char *fw_date, char *stable_fw_size, char *stable_fw, char *stable_date, char *collect);
#ifdef MOBILE_SUPPORT
lrut_fota_t lrut_fota_set_modem_info(struct ubus_context *ubus, char *fw_size, char *fw, char *fw_ver, char *id);
#endif
lrut_fota_t lrut_fota_set_tap_info(struct ubus_context *ubus, char *mac, char *fw, char *fw_stable);
lrut_fota_t lrut_fota_reset_info(struct ubus_context *ubus);
lrut_fota_t lrut_fota_set_crontab(struct ubus_context *ubus, int enable);

/**
 * @brief Free info structure
 * 
 * @param info	pointer to info structure
 */
void lrut_free_info(struct lrut_fota_info_st *info);
