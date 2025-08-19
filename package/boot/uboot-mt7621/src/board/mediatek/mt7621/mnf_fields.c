#include <common.h>
#include <linux/ctype.h>
#include <linux/time.h>
#include <tlt/mnf_info.h>
#include <rand.h>

#define CONFIG_MAC_VID_STR "001E42"

static int validate_num(mnf_field_t *field, const char *old)
{
	for (int i = 0; i < field->length; i++) {
		if (!isdigit(old[i]))
			return 1;
	}
	return 0;
}

/* Set to mac random mac address with our VID, skip if mac already has our VID */
static int restore_mac(mnf_field_t *field, const char *old, char *buf)
{
	unsigned nid;
	srand(get_timer(0));
	nid = rand() & 0xffffff;

	sprintf(buf, "%s%06x", CONFIG_MAC_VID_STR, nid);

	for (int i = 0; i < strlen(buf); i++) {
		buf[i] = toupper(buf[i]);
	}

	return strncmp(old, CONFIG_MAC_VID_STR, strlen(CONFIG_MAC_VID_STR)) != 0;
}

/* Set to fixed fallback device, skip if field contains valid model number */
static int restore_name(mnf_field_t *field, const char* old, char *buf)
{
#ifdef CONFIG_DEVICE_MODEL_RUTM
	const char *good_models[] = { "RUTM08", "RUTM09", "RUTM10", "RUTM11", "RUTM12", "RUTM13",
				      "RUTM14", "RUTM20", "RUTM30", "RUTM31", "RUTMR1", "RUTM50",
				      "RUTM51","RUTM52", "RUTM54", "RUTM55", "RUTM56", "RUTM59" };
#else
	const char *good_models[] = { CONFIG_DEVICE_MODEL };
#endif

	strcpy(buf, CONFIG_DEVICE_MODEL_MNF_DEFAULT);

	for (int i = 0; i < ARRAY_SIZE(good_models); i++) {
		if (!strncmp(old, good_models[i], strlen(good_models[i])))
			return 0;
	}
	return 1;
}

/* Clear the field with 0's, skip if field contains only digits */
static int restore_num(mnf_field_t *field, const char *old, char *buf)
{
	memset(buf, '0', field->length);
	buf[field->length] = '\0';

	return validate_num(field, old);
}

/* Clear the field with 0xff's, don't overwrite by default */
static int clear(mnf_field_t *field, const char *old, char *buf)
{
	strcpy(buf, "");

	return 0;
}

mnf_field_t mnf_fields[] = {
//	short/long name,     description,        offset, len, restore func   , flags
	{ 'm', "mac",       "MAC address",         0x00,   6, restore_mac    , MNF_FIELD_BINARY },
	{ 'n', "name",      "Model name",          0x10,  12, restore_name   },
	{ 'w', "wps",       "WPS PIN",             0x20,   8, clear          },
	{ 's', "sn",        "Serial number",       0x30,  10, restore_num    },
	{ 'b', "batch",     "Batch number",        0x40,   4, restore_num    },
	{ 'H', "hwver",     "HW version (major)",  0x50,   4, restore_num    },
	{ 'L', "hwver_lo",  "HW version (minor)",  0x54,   4, restore_num    },
	{ 'B', "branch",    "HW branch",           0x58,   4, clear          },
	{ 'W', "wifi_pass", "WiFi password",       0x90,  16, clear          },
	{ 'x', "passwd",    "Linux password",      0xA0, 106, clear          },
	{ 'C', "simcfg",    "SIM configuration",  0x110,  32, clear          },
	{ 'P', "profiles",  "eSIM profiles",      0x130, 128, clear          },
	{ 'c', "mob_cfg",   "Mob config",          0x66,   4, clear          },
	{ '\0' }
};
