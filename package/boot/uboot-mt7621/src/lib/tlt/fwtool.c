#include <common.h>
#include <linux/ctype.h>
#include <exports.h>
#include <tlt/fwtool.h>
#include "tlt/mnf_info.h"

#define FWIMAGE_MAGIC		0x46577830 /* FWx0 */

struct fwimage_trailer {
	uint32_t magic;
	uint32_t crc32;
	uint8_t type;
	uint8_t __pad[3];
	uint32_t size;
};

static int check_modX_blv1(const char *ptr)
{
	const char mob_cfg[8] = { 0 };

	mnf_get_field("mob_cfg", mob_cfg);

	if (strcmp("0001", mob_cfg)) {
		return 0;
	}

	while ((ptr = strstr(ptr, "\"mod"))) {
		ptr += 4; // Move past "mod"

		// Ensure next characters are digits (X in modX)
		if (!isdigit(*ptr))
			continue;
		while (isdigit(*ptr))
			ptr++; // Skip all digits

		if (!strncmp(ptr, "\": \"blv1\"", 9)) {
			return 0;
		}
	}

	return 1;
}

static int validate_hw_mods(char *buf)
{
	if (check_modX_blv1(buf))
		return 1;

	return 0;
}

int fwtool_validate_manifest(void *ptr, unsigned int length)
{
	struct fwimage_trailer tr = { 0 };
	char buffer[4096] = { 0 };
	int offset, len;

	if (sizeof(tr) * 2 > length) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	// read signature trailer first
	offset = length - sizeof(tr);
	memcpy(&tr, ptr + offset, sizeof(tr));

	if (cpu_to_be32(tr.magic) != FWIMAGE_MAGIC ||
	    cpu_to_be32(tr.size) >= length) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	// read manifest trailer
	offset = length - sizeof(tr) - cpu_to_be32(tr.size);
	memcpy(&tr, ptr + offset, sizeof(tr));

	if (cpu_to_be32(tr.magic) != FWIMAGE_MAGIC ||
	    cpu_to_be32(tr.size) >= length) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	// read manifest trailer
	offset -= cpu_to_be32(tr.size) - sizeof(tr) - 8;
	len = cpu_to_be32(tr.size) - sizeof(tr);
	len = (len > sizeof(buffer)) ? sizeof(buffer) : len;
	memcpy(&buffer[0], ptr + offset, len);

	buffer[len - 1] = '\0';

	if (!strstr(buffer, "supported_devices")) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	if (!strstr(buffer, "teltonika,")) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	if (!strstr(buffer, CONFIG_DEVICE_MODEL_MANIFEST)) {
		return FWTOOL_ERROR_INVALID_FILE;
	}

	if (validate_hw_mods(buffer)) {
		printf("Unsupported hw\n");
		return FWTOOL_ERROR_INVALID_FILE;
	}

	return FWTOOL_FIRMWARE_VALID;
}
