#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <libubus.h>

typedef enum {
	LGPS_SUCCESS,
	LGPS_ERROR_UBUS,
	LGPS_ERROR,
} lgps_err_t;

typedef enum {
	LGPS_FIX_Q_INVALID,
	LGPS_FIX_Q_GPS,
	LGPS_FIX_Q_DGPS,
	LGPS_FIX_Q_UNKNOWN,
} lgps_fix_quality_t;

typedef enum {
	LGPS_FIX_SET_MODE_MANUAL,
	LGPS_FIX_SET_MODE_AUTO,
	LGPS_FIX_SET_MODE_UNKNOWN,
} lgps_fix_set_mode_t;

typedef enum {
	LGPS_FIX_CURR_MODE_NONE = 1,
	LGPS_FIX_CURR_MODE_2D,
	LGPS_FIX_CURR_MODE_3D,
	LGPS_FIX_CURR_MODE_UNKNOWN,
} lgps_fix_curr_mode_t;

typedef struct {
	double longitude;
	double latitude;
	double altitude;
	double angle;
	double speed;
	double accuracy;
	double pdop;
	double hdop;
	double vdop;
	double tmg_true; /* Track made good, degrees True */
	double tmg_magnetic; /* Track made good, degrees Magnetic */
	double speed_vtg_knots;
	double speed_vtg_kmh;
	uint32_t satellites;
	lgps_fix_quality_t fix_quality;
	lgps_fix_set_mode_t fix_set_mode;
	lgps_fix_curr_mode_t fix_curr_mode;
	uint32_t fix_status;
	uint64_t timestamp;
	uint64_t utc_timestamp;
	char constellation[2]; // Example: GP, GA, BD, GL
} lgps_t;

typedef struct lgps_subscriber lgps_subscriber_t;

typedef void (*lgps_position_handler_t)(
	struct ubus_context *ctx,
	lgps_subscriber_t *subscriber,
	lgps_t *position // Position can be NULL. If it is NULL, infer that GPS is not available  
);

typedef struct lgps_subscriber {
	bool initialized;

	bool subscribed;
	struct ubus_subscriber ubus_sub;
	struct ubus_event_handler object_add_handler;

	lgps_position_handler_t position_handler;
	// TODO: Maybe add a user `void*`?
} lgps_subscriber_t;

lgps_err_t lgps_get_tmo(struct ubus_context *ctx, lgps_t *gps, int timeout);
lgps_err_t lgps_get(struct ubus_context *ctx, lgps_t *gps);

lgps_err_t lgps_subscribe(
	struct ubus_context *ctx,
	lgps_subscriber_t *subscriber,
	lgps_position_handler_t position_handler
);
void lgps_unsubscribe(struct ubus_context *ctx, lgps_subscriber_t *subscriber);

const char *lgps_strerror(lgps_err_t err);
const char *lgps_fix_quality_to_str(lgps_fix_quality_t fix_quality);
lgps_fix_quality_t lgps_fix_quality_from_str(char fix_quality);
const char *lgps_fix_curr_mode_to_str(lgps_fix_curr_mode_t fix_mode);
lgps_fix_curr_mode_t lgps_fix_curr_mode_from_str(char fix_mode);
const char *lgps_fix_set_mode_to_str(lgps_fix_set_mode_t fix_mode);
lgps_fix_set_mode_t lgps_fix_set_mode_from_str(char fix_mode);

#ifdef __cplusplus
}
#endif
