/*
 * Copyright (C) 2008 Nokia Corporation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
 * the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/*
 * An utility to format MTD devices into UBI and flash UBI images.
 *
 * Author: Artem Bityutskiy
 */

/*
 * Maximum amount of consequtive eraseblocks which are considered as normal by
 * this utility. Otherwise it is assume that something is wrong with the flash
 * or the driver, and eraseblocks are stopped being marked as bad.
 */

#include <mtdutils/ubiformat.h>

#include <command.h>
#include <mapmem.h>
#include <mtd.h>
#include <stdint.h>
#include <stdlib.h>
#include <watchdog.h>

#define MAX_CONSECUTIVE_BAD_BLOCKS 4
#define PROGRAM_NAME    "ubiformat"

#include <mtdutils/ubi-media.h>
#include <mtdutils/libscan.h>
#include <mtdutils/libubigen.h>
#include <linux/crc32.h>
#include <mtdutils/common.h>

#include <tlt/leds.h>

static void print_bad_eraseblocks(const struct mtd_info *mtd,
				  const struct ubi_scan_info *si)
{
	int first = 1, eb;

	if (si->bad_cnt == 0)
		return;

	normsg_cont("%d bad eraseblocks found, numbers: ", si->bad_cnt);
	for (eb = 0; eb < mtd_eraseblock_count(mtd); eb++) {
		if (si->ec[eb] != EB_BAD)
			continue;
		if (first) {
			printf("%d", eb);
			first = 0;
		} else
			printf(", %d", eb);
	}
	printf("\n");
}

static int change_ech(struct ubi_ec_hdr *hdr, uint32_t image_seq,
		      long long ec)
{
	uint32_t crc;

	/* Check the EC header */
	if (be32_to_cpu(hdr->magic) != UBI_EC_HDR_MAGIC)
		return errmsg("bad UBI magic %#08x, should be %#08x",
			      be32_to_cpu(hdr->magic), UBI_EC_HDR_MAGIC);

	crc = crc32(UBI_CRC32_INIT, hdr, UBI_EC_HDR_SIZE_CRC);
	if (be32_to_cpu(hdr->hdr_crc) != crc)
		return errmsg("bad CRC %#08x, should be %#08x\n",
			      crc, be32_to_cpu(hdr->hdr_crc));

	hdr->image_seq = cpu_to_be32(image_seq);
	hdr->ec = cpu_to_be64(ec);
	crc = crc32(UBI_CRC32_INIT, hdr, UBI_EC_HDR_SIZE_CRC);
	hdr->hdr_crc = cpu_to_be32(crc);

	return 0;
}

static int drop_ffs(const struct mtd_info *mtd, const void *buf, int len)
{
	int i;

        for (i = len - 1; i >= 0; i--)
		if (((const uint8_t *)buf)[i] != 0xFF)
		      break;

        /* The resulting length must be aligned to the minimum flash I/O size */
        len = i + 1;
	len = (len + mtd->writesize - 1) / mtd->writesize;
	len *=  mtd->writesize;
        return len;
}

/*
 * Returns %-1 if consecutive bad blocks exceeds the
 * MAX_CONSECUTIVE_BAD_BLOCKS and returns %0 otherwise.
 */
static int consecutive_bad_check(int eb, struct ubiformat_args *args)
{
	static int consecutive_bad_blocks = 1;
	static int prev_bb = -1;

	if (prev_bb == -1)
		prev_bb = eb;

	if (eb == prev_bb + 1)
		consecutive_bad_blocks += 1;
	else
		consecutive_bad_blocks = 1;

	prev_bb = eb;

	if (consecutive_bad_blocks >= MAX_CONSECUTIVE_BAD_BLOCKS) {
		if (!args->quiet)
			printf("\n");
		return errmsg("consecutive bad blocks exceed limit: %d, bad flash?",
		              MAX_CONSECUTIVE_BAD_BLOCKS);
	}

	return 0;
}

/* Patterns to write to a physical eraseblock when torturing it */
static uint8_t patterns[] = {0xa5, 0x5a, 0x0};

/**
 * check_pattern - check if buffer contains only a certain byte pattern.
 * @buf: buffer to check
 * @patt: the pattern to check
 * @size: buffer size in bytes
 *
 * This function returns %0 if there are only @patt bytes in @buf, and %-1 if
 * something else was also found.
 */
static int check_pattern(const void *buf, uint8_t patt, int size)
{
	int i;

	for (i = 0; i < size; i++)
		if (((const uint8_t *)buf)[i] != patt)
			return -1;
	return 0;
}

int mtd_torture(struct mtd_info *mtd, int eb)
{
	int err, i, patt_count;
	void *buf;

	normsg("run torture test for PEB %d", eb);
	patt_count = ARRAY_SIZE(patterns);

	buf = malloc(mtd->erasesize);

	for (i = 0; i < patt_count; i++) {
		struct erase_info einfo;
		size_t retlen;

		einfo.mtd = mtd;
		einfo.addr = eb * mtd->erasesize;
		einfo.len = mtd->erasesize;
		err = mtd_erase(mtd, &einfo);
		if (err)
			goto out;

		/* Make sure the PEB contains only 0xFF bytes */
		err = mtd_read(mtd, eb * mtd->erasesize, mtd->erasesize, &retlen, buf);
		if (err)
			goto out;

		err = check_pattern(buf, 0xFF, mtd->erasesize);
		if (err) {
			errmsg("erased PEB %d, but a non-0xFF byte found", eb);
			errno = EIO;
			goto out;
		}

		/* Write a pattern and check it */
		memset(buf, patterns[i], mtd->erasesize);
		err = mtd_write(mtd, eb * mtd->erasesize, mtd->erasesize, &retlen, buf);
		if (err)
			goto out;

		memset(buf, ~patterns[i], mtd->erasesize);
		err = mtd_read(mtd, eb * mtd->erasesize, mtd->erasesize, &retlen, buf);
		if (err)
			goto out;

		err = check_pattern(buf, patterns[i], mtd->erasesize);
		if (err) {
			errmsg("pattern %x checking failed for PEB %d",
				patterns[i], eb);
			errno = EIO;
			goto out;
		}
	}

	err = 0;
	normsg("PEB %d passed torture test, do not mark it a bad", eb);

out:
	free(buf);
	return err;
}

static int mark_bad(struct mtd_info *mtd, struct ubi_scan_info *si, int eb, struct ubiformat_args *args)
{
	int err;

	if (!args->quiet)
		normsg_cont("marking block %d bad", eb);

	if (!args->quiet)
		printf("\n");

	err = mtd_block_markbad(mtd, eb * mtd->erasesize);
	if (err)
		return err;

	si->bad_cnt += 1;
	si->ec[eb] = EB_BAD;

	return consecutive_bad_check(eb, args);
}

static int flash_image(struct mtd_info *mtd,
		       const struct ubigen_info *ui, struct ubi_scan_info *si, const void *image, size_t image_len, struct ubiformat_args *args)
{
	int img_ebs, eb, written_ebs = 0, divisor, skip_data_read = 0;
	size_t image_ofs = 0;

	img_ebs = image_len / mtd->erasesize;

	if (img_ebs > si->good_cnt) {
		sys_errmsg("image is too large (%d bytes)",
			   image_len);
		goto out_close;
	}

	if (image_len % mtd->erasesize) {
		sys_errmsg("image (size %d bytes) is not multiple of ""eraseblock size (%d bytes)",
			   image_len, mtd->erasesize);
		goto out_close;
	}

	verbose(args->verbose, "will write %d eraseblocks", img_ebs);
	divisor = img_ebs;
	for (eb = 0; eb < mtd_eraseblock_count(mtd); eb++) {
		int err, new_len;
		char buf[mtd->erasesize];
		long long ec;
		struct erase_info einfo;
		size_t retlen;

		tlt_leds_check_anim();

		if (!args->quiet && !args->verbose) {
			printf("\r" PROGRAM_NAME ": flashing eraseblock %d -- %2lld %% complete  ",
			       eb, (long long)(eb + 1) * 100 / divisor);
		}

		if (si->ec[eb] == EB_BAD) {
			divisor += 1;
			continue;
		}

		if (args->verbose) {
			normsg_cont("eraseblock %d: erase", eb);
		}

		einfo.mtd = mtd;
		einfo.addr = eb * mtd->erasesize;
		einfo.len = mtd->erasesize;
		err = mtd_erase(mtd, &einfo);
		if (err) {
			if (!args->quiet)
				printf("\n");
			sys_errmsg("failed to erase eraseblock %d", eb);

			if (errno != EIO)
				goto out_close;

			if (mark_bad(mtd, si, eb, args))
				goto out_close;

			continue;
		}

		if (!skip_data_read) {
			memcpy(buf, image + image_ofs, mtd->erasesize);
			image_ofs += mtd->erasesize;
		}
		skip_data_read = 0;

		if (args->override_ec)
			ec = args->ec;
		else if (si->ec[eb] <= EC_MAX)
			ec = si->ec[eb] + 1;
		else
			ec = si->mean_ec;

		if (args->verbose) {
			printf(", change EC to %lld", ec);
		}

		err = change_ech((struct ubi_ec_hdr *)buf, ui->image_seq, ec);
		if (err) {
			errmsg("bad EC header at eraseblock %d",
			       written_ebs);
			goto out_close;
		}

		if (args->verbose) {
			printf(", write data\n");
		}

		new_len = drop_ffs(mtd, buf, mtd->erasesize);

		err = mtd_write(mtd, eb * mtd->erasesize, new_len, &retlen, buf);
		if (err) {
			sys_errmsg("cannot write eraseblock %d", eb);

			if (errno != EIO)
				goto out_close;

			err = mtd_torture(mtd, eb);
			if (err) {
				if (mark_bad(mtd, si, eb, args))
					goto out_close;
			}

			/*
			 * We have to make sure that we do not read next block
			 * of data from the input image or stdin - we have to
			 * write buf first instead.
			 */
			skip_data_read = 1;
			continue;
		}
		if (++written_ebs >= img_ebs)
			break;
	}

	if (!args->quiet && !args->verbose)
		printf("\n");
	return eb + 1;

out_close:
	return -1;
}

static int mem_cmp(ulong addr1, ulong addr2, ulong bytes, ulong *good)
{
	ulong ngood;
	int rcode = 0;
	const void *buf1, *buf2, *base;
	ulong word1, word2;

	base = buf1 = map_sysmem(addr1, bytes);
	buf2	    = map_sysmem(addr2, bytes);
	for (ngood = 0; ngood < bytes; ++ngood) {
		word1 = *(u8 *)buf1;
		word2 = *(u8 *)buf2;

		if (word1 != word2) {
			ulong offset = buf1 - base;
			errmsg("byte at 0x%08lx (%#0*lx) != byte at 0x%08lx (%#0*lx)",
			       (ulong)(addr1 + offset), 1, word1, (ulong)(addr2 + offset), 1, word2);
			rcode = 1;
			break;
		}

		buf1++;
		buf2++;

		if ((ngood % (64 << 10)) == 0)
			WATCHDOG_RESET();
	}
	unmap_sysmem(buf1);
	unmap_sysmem(buf2);

	*good += ngood;
	return rcode;
}

int verify_image(struct mtd_info *mtd, const void *image, size_t size)
{
	int ret	    = 0;
	int eb	    = 0;
	ulong bytes = 0;
	size_t retlen;

	static const int off = 0x1000;
	static const ulong verif_addr = 0x86000000;

	if (size % mtd->erasesize) {
		size = round_down(size, mtd->erasesize);
	}

	normsg("reading %d byte(s)", size);
	ret = mtd_read(mtd, 0, size, &retlen, (u_char *)verif_addr);
	if (ret) {
		errmsg("failed to read MTD device (rc = %d)", ret);
		return ret;
	}

	for (eb = 0; eb < (int)(size / mtd->erasesize); eb++) {
		ret = mem_cmp(verif_addr + eb * mtd->erasesize + off,
			      (ulong)image + eb * mtd->erasesize + off, mtd->erasesize - off, &bytes);
		if (ret) {
			break;
		}
	}

	normsg("total of %ld byte(s) (%d eraseblock(s)) were the same", bytes, eb);

	return ret;
}

static int format(struct mtd_info *mtd,
		  const struct ubigen_info *ui, struct ubi_scan_info *si,
		  int start_eb, int novtbl, struct ubiformat_args *args)
{
	int eb, err, write_size;
	struct ubi_ec_hdr *hdr;
	struct ubi_vtbl_record *vtbl;
	int eb1 = -1, eb2 = -1;
	long long ec1 = -1, ec2 = -1;
	int ret = -1;

	write_size = UBI_EC_HDR_SIZE + mtd_subpage_size(mtd) - 1;
	write_size /= mtd_subpage_size(mtd);
	write_size *= mtd_subpage_size(mtd);
	hdr = malloc(write_size);
	if (!hdr)
		return sys_errmsg("cannot allocate %d bytes of memory", write_size);
	memset(hdr, 0xFF, write_size);

	for (eb = start_eb; eb < mtd_eraseblock_count(mtd); eb++) {
		long long ec;
		struct erase_info einfo;
		size_t retlen;

		tlt_leds_check_anim();

		if (!args->quiet && !args->verbose) {
			printf("\r" PROGRAM_NAME ": formatting eraseblock %d -- %2lld %% complete  ",
			       eb, (long long)(eb + 1 - start_eb) * 100 / (mtd_eraseblock_count(mtd) - start_eb));
		}

		if (si->ec[eb] == EB_BAD)
			continue;

		if (args->override_ec)
			ec = args->ec;
		else if (si->ec[eb] <= EC_MAX)
			ec = si->ec[eb] + 1;
		else
			ec = si->mean_ec;
		ubigen_init_ec_hdr(ui, hdr, ec);

		if (args->verbose) {
			normsg_cont("eraseblock %d: erase", eb);
		}

		einfo.mtd = mtd;
		einfo.addr = eb * mtd->erasesize;
		einfo.len = mtd->erasesize;
		err = mtd_erase(mtd, &einfo);
		if (err) {
			if (!args->quiet)
				printf("\n");

			sys_errmsg("failed to erase eraseblock %d", eb);
			if (errno != EIO)
				goto out_free;

			if (mark_bad(mtd, si, eb, args))
				goto out_free;
			continue;
		}

		if ((eb1 == -1 || eb2 == -1) && !novtbl) {
			if (eb1 == -1) {
				eb1 = eb;
				ec1 = ec;
			} else if (eb2 == -1) {
				eb2 = eb;
				ec2 = ec;
			}
			if (args->verbose)
				printf(", do not write EC, leave for vtbl\n");
			continue;
		}

		if (args->verbose) {
			printf(", write EC %lld\n", ec);
		}

		err = mtd_write(mtd, eb * mtd->erasesize, write_size, &retlen, (u_char*) hdr);
		if (err) {
			if (!args->quiet && !args->verbose)
				printf("\n");
			sys_errmsg("cannot write EC header (%d bytes buffer) to eraseblock %d",
				   write_size, eb);

			if (errno != EIO) {
				goto out_free;
			}

			err = mtd_torture(mtd, eb);
			if (err) {
				if (mark_bad(mtd, si, eb, args))
					goto out_free;
			}
			continue;

		}
	}

	if (!args->quiet && !args->verbose)
		printf("\n");

	if (novtbl) {
		ret = 0;
		goto out_free;
	}

	if (eb1 == -1 || eb2 == -1) {
		errmsg("no eraseblocks for volume table");
		goto out_free;
	}

	verbose(args->verbose, "write volume table to eraseblocks %d and %d", eb1, eb2);
	vtbl = ubigen_create_empty_vtbl(ui);
	if (!vtbl)
		goto out_free;

	err = ubigen_write_layout_vol(mtd, ui, eb1, eb2, ec1,  ec2, vtbl);
	free(vtbl);
	if (err) {
		errmsg("cannot write layout volume");
		goto out_free;
	}

	free(hdr);
	return 0;

out_free:
	free(hdr);
	return ret;
}

int ubiformat(const char *mtd_name, const void *image, size_t image_len, struct ubiformat_args *args)
{
	int err, verbose;
	struct mtd_info *mtd;
	struct ubigen_info ui;
	struct ubi_scan_info *si;

	tlt_leds_check_anim();

	mtd_probe_devices();
	mtd = get_mtd_device_nm(mtd_name);

	tlt_leds_check_anim();

	if (IS_ERR_OR_NULL(mtd)) {
		sys_errmsg("cannot find mtd device \"%s\"", mtd_name);
		goto out_close_mtd;
	}

	if (!is_power_of_2(mtd->writesize)) {
		errmsg("min. I/O size is %d, but should be power of 2",
		       mtd->writesize);
		goto out_close_mtd;
	}

	/* Round down image size to be a multiple of eb size, this let's us ignore any trailing metadata */
	if (image_len % mtd->erasesize) { 
		image_len = round_down(image_len, mtd->erasesize);
		warnmsg("image size is not multiple of eraseblock size, rounding down to 0x%08x bytes...", image_len);
	}

	/* Validate VID header offset if it was specified */
	if (args->vid_hdr_offs != 0) {
		if (args->vid_hdr_offs % 8) {
			errmsg("VID header offset has to be multiple of min. I/O unit size");
			goto out_close;
		}
		if (args->vid_hdr_offs + (int)UBI_VID_HDR_SIZE > mtd->erasesize) {
			errmsg("bad VID header offset");
			goto out_close;
		}
	}

	if (!(mtd->flags & MTD_WRITEABLE)) {
		errmsg("mtd%d (%s) is a read-only device", mtd->index, mtd->name);
		goto out_close;
	}

	if (!args->quiet) {
		normsg_cont("mtd%d (%s)", mtd->index, mtd->name);
		printf(", %d eraseblocks of %dkB", mtd_eraseblock_count(mtd), mtd->erasesize >> 10);
		printf(", min. I/O size %d bytes\n", mtd->writesize);
	}

	if (args->quiet)
		verbose = 0;
	else if (args->verbose)
		verbose = 2;
	else
		verbose = 1;
	err = ubi_scan(mtd, &si, verbose);
	if (err) {
		errmsg("failed to scan mtd%d (%s)", mtd->index, mtd->name);
		goto out_close;
	}

	if (si->good_cnt == 0) {
		errmsg("all %d eraseblocks are bad", si->bad_cnt);
		goto out_free;
	}

	if (si->good_cnt < 2) {
		errmsg("too few non-bad eraseblocks (%d) on mtd%d",
		       si->good_cnt, mtd->index);
		goto out_free;
	}

	if (!args->quiet) {
		if (si->ok_cnt)
			normsg("%d eraseblocks have valid erase counter, mean value is %lld",
			       si->ok_cnt, si->mean_ec);
		if (si->empty_cnt)
			normsg("%d eraseblocks are supposedly empty", si->empty_cnt);
		if (si->corrupted_cnt)
			normsg("%d corrupted erase counters", si->corrupted_cnt);
		print_bad_eraseblocks(mtd, si);
	}

	if (si->alien_cnt) {
		if (!args->quiet)
			warnmsg("%d of %d eraseblocks contain non-UBI data",
				si->alien_cnt, si->good_cnt);
	}

	if (!args->override_ec && si->empty_cnt < si->good_cnt) {
		int percent = (si->ok_cnt * 100) / si->good_cnt;

		/*
		 * Make sure the majority of eraseblocks have valid
		 * erase counters.
		 */
		if (percent < 50) {
			if (!args->quiet) {
				warnmsg("only %d of %d eraseblocks have valid erase counter",
					si->ok_cnt, si->good_cnt);
				normsg("erase counter 0 will be used for all eraseblocks");
				normsg("note, arbitrary erase counter value may be specified using -e option");
			}
			args->ec = 0;
			args->override_ec = 1;
		} else if (percent < 95) {
			if (!args->quiet) {
				warnmsg("only %d of %d eraseblocks have valid erase counter",
					si->ok_cnt, si->good_cnt);
				normsg("mean erase counter %lld will be used for the rest of eraseblock",
				       si->mean_ec);
			}
			args->ec = si->mean_ec;
			args->override_ec = 1;
		}
	}

	if (!args->quiet && args->override_ec)
		normsg("use erase counter %lld for all eraseblocks", args->ec);

	ubigen_info_init(&ui, mtd->erasesize, mtd->writesize, mtd_subpage_size(mtd),
			 args->vid_hdr_offs, args->ubi_ver, args->image_seq);

	if (si->vid_hdr_offs != -1 && ui.vid_hdr_offs != si->vid_hdr_offs) {
		/*
		 * Hmm, what we read from flash and what we calculated using
		 * min. I/O unit size and sub-page size differs.
		 */
		if (!args->quiet) {
			warnmsg("VID header and data offsets on flash are %d and %d, "
				"which is different to requested offsets %d and %d",
				si->vid_hdr_offs, si->data_offs, ui.vid_hdr_offs,
				ui.data_offs);
		}
		normsg("use offsets %d and %d",  ui.vid_hdr_offs, ui.data_offs);
	}

	if (image) {
		err = flash_image(mtd, &ui, si, image, image_len, args);
		if (err < 0)
			goto out_free;

		/*
		 * ubinize has create a UBI_LAYOUT_VOLUME_ID volume for image.
		 * So, we don't need to create again.
		 */
		err = format(mtd, &ui, si, err, 1, args);
		if (err)
			goto out_free;

		err = verify_image(mtd, image, image_len);
		if (err)
			goto out_free;
	} else {
		err = format(mtd, &ui, si, 0, 0, args);
		if (err)
			goto out_free;
	}

	ubi_scan_free(si);
	return 0;

out_free:
	ubi_scan_free(si);
out_close:
out_close_mtd:
	return -1;
}
