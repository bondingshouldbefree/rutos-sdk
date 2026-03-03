#include <common.h>

#include <linux/ctype.h>
#include <linux/time.h>
#include <tlt/mnf_info.h>
#include <rand.h>


#define CONFIG_MAC_VID_STR "001E42"

inline static int validate_num(mnf_field_t *field, const char *old)
{
	for (int i = 0; i < field->length; i++) {
		if (!isdigit(old[i]))
			return 1;
	}
	return 0;
}

static int validate_sn(mnf_field_t *field, const char *old)
{
	for (int i = 0; i < field->length; i++) {
		if (!((old[i] >= 'A' && old[i] <= 'Z') ||
			  (old[i] >= '0' && old[i] <= '9'))) {
			return 1;
		}
	}
	return 0;
}

/* Set to mac random mac address with our VID, skip if mac already has our VID */
static int restore_mac(mnf_field_t *field, const char *old, char *buf)
{
	unsigned nid;

	// using srand() doesn't work here, for whatever reason...
	unsigned seed = get_timer(0);
	nid = rand_r(&seed) & 0xffffff;

	sprintf(buf, "%s%06x", CONFIG_MAC_VID_STR, nid);

	for (int i = 0; i < strlen(buf); i++) {
		buf[i] = toupper(buf[i]);
	}

	return strncmp(old, CONFIG_MAC_VID_STR, strlen(CONFIG_MAC_VID_STR)) != 0;
}

/* Set to fixed fallback device, skip if field contains valid model number */
static int restore_name(mnf_field_t *field, const char *old, char *buf)
{
	memset(buf, '0', field->length);
	buf[field->length] = '\0';
	memcpy(buf, CONFIG_DEVICE_MODEL_MNF_DEFAULT, strlen(CONFIG_DEVICE_MODEL_MNF_DEFAULT));

	return strncmp(old, CONFIG_DEVICE_MODEL_MNF_DEFAULT, strlen(CONFIG_DEVICE_MODEL_MNF_DEFAULT));
}

/* Clear the field with 0's, skip if field contains only digits */
static int restore_num(mnf_field_t *field, const char *old, char *buf)
{
	memset(buf, '0', field->length);
	buf[field->length] = '\0';

	return validate_num(field, old);
}

/* Remove the -6 from lenght when moved to new system for serial number*/
static int restore_sn(mnf_field_t *field, const char *old, char *buf)
{
	memset(buf, '0', field->length-6);
	buf[field->length-6] = '\0';
	
	return validate_sn(field, old);
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
	{ 'n', "name",      "Model name",          0x10,  12, restore_name   , 0 },
	{ 'w', "wps",       "WPS PIN",             0x20,   8, clear          , 0 },
	{ 's', "sn",        "Serial number",       0x30,  16, restore_sn     , 0 },
	{ 'b', "batch",     "Batch number",        0x40,   4, restore_num    , 0 },
	{ 'H', "hwver",     "HW version (major)",  0x50,  4, restore_num     , 0 },
	{ 'L', "hwver_lo",  "HW version (minor)",  0x54,  4, restore_num     , 0 },
	{ 'B', "branch",    "HW branch",           0x58,   4, clear          , 0 },
	{ '1', "sim1",      "SIM 1 PIN",           0x70,   8, clear          , 0 },
	{ '2', "sim2",      "SIM 2 PIN",           0x78,   8, clear          , 0 },
	{ 'C', "simcfg",    "SIM config",         0x110,  32, clear          , 0 },
	{ 'P', "profiles",  "eSIM profiles",      0x130, 128, clear          , 0 },
	{ 'W', "wifi_pass", "WiFi password",       0x90,  16, clear          , 0 },
	{ 'x', "passwd",    "Linux password",      0xA0, 106, clear          , 0 },
	{ 'c', "mob_cfg",   "Mob config",          0x536,  4, clear          , 0 },
	{ 'I', "mob_vidpid","Mob VIDs PIDs",	   0x80,   8, clear          , MNF_FIELD_BINARY },
	{ '\0' }
};

