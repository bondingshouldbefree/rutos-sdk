#ifndef __MTDUTILS_UBIFORMAT_H__
#define __MTDUTILS_UBIFORMAT_H__

#include <common.h>

/* The variables below are set by command line arguments */
struct ubiformat_args {
	unsigned int quiet:1;
	unsigned int verbose:1;
	unsigned int override_ec:1;
	int vid_hdr_offs;
	int ubi_ver;
	uint32_t image_seq;
	long long ec;
};

int ubiformat(const char *mtd_name, const void *image, size_t image_len, struct ubiformat_args *args);

#endif