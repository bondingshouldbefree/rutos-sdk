/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef __TLT_FSB_FLASH_H__
#define __TLT_FSB_FLASH_H__

#include "fsb.h"

typedef enum {
	FSB_PARTITION_PRIMARY,
	FSB_PARTITION_SECONDARY,
} fsb_partition;

static inline const char *fsb_partition_str(fsb_partition partition)
{
	switch (partition) {
	case FSB_PARTITION_PRIMARY:
		return "primary";
	case FSB_PARTITION_SECONDARY:
		return "secondary";
	default:
		return "<invalid>";
	}
}

/*
 * Read entire specified bootconfig partition into `out`
 */
int fsb_flash_read(fsb_partition partition, fsb_config out[], size_t out_size, size_t *read);

/*
 * Write fsb_config struct into flash at specified index
 */
int fsb_flash_write(fsb_partition partition, size_t idx, fsb_config *bc);

/*
 * Erase flash partition
 */
int fsb_flash_erase(fsb_partition partition);

#endif
