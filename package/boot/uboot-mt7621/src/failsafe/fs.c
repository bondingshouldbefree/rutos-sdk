/* SPDX-License-Identifier:	GPL-2.0 */
/*
 * Copyright (C) 2019 MediaTek Inc. All Rights Reserved.
 *
 * Author: Weijie Gao <weijie.gao@mediatek.com>
 *
 */

#include <common.h>

#include "fs.h"
#include "fsdata.h"

static u8_t fs_strcmp(const char *str1, const char *str2)
{
	u8_t i;
	i = 0;
loop:

	if (str2[i] == 0 || str1[i] == '\r' || str1[i] == '\n') {
		return 0;
	}

	if (str1[i] != str2[i]) {
		return 1;
	}

	++i;
	goto loop;
}

int fs_find_file(const char *path, struct fs_desc *file)
{
	struct fsdata_file_noconst *f;

	for (f = (struct fsdata_file_noconst *)FS_ROOT; f != NULL; f = (struct fsdata_file_noconst *)f->next) {
		if (fs_strcmp(path, f->name) == 0) {
			file->data = f->data;
			file->len  = f->len;
			return 1;
		}
	}

	return 0;
}
