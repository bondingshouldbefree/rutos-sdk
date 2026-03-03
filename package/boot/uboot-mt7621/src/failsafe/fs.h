// SPDX-License-Identifier:	GPL-2.0
/*
 * Copyright (C) 2019 MediaTek Inc. All Rights Reserved.
 *
 * Author: Weijie Gao <weijie.gao@mediatek.com>
 *
 */

#ifndef _FAILSAFE_FS_H_
#define _FAILSAFE_FS_H_

struct fs_desc {
	unsigned int len;
	const void *data;
};

int fs_find_file(const char *path, struct fs_desc *file);

#endif /* _FAILSAFE_FS_H_ */
