#include <common.h>
#include <command.h>
#include <mtd.h>
#include <image.h>
#include <tlt/fsb.h>
#include <tlt/mnf_info.h>
#include <mapmem.h>
#include <mmc.h>

#define MMC_DEV 0
#define TLT_SLOT_0	  "rutos-a"
#define TLT_SLOT_1	  "rutos-b"
#define TLT_HWPART_0	  4 // GPP1
#define TLT_HWPART_1	  5 // GPP2
#define TLT_RECOVERY_SLOT "recovery"
#define FDT_MAX_IMAGE_SIZE	  0x100000

static int fit_find_tlt_compat_node(const void *fit, int noffset, const void **fdt, 
				    int *compat_noffset, int images_noffset)
{
	const char *kfdt_name;
	int kfdt_noffset;
	int len;
	size_t sz;

	if (fdt_getprop(fit, noffset, FIT_TLT_COMPAT_PROP, NULL)) {
		*fdt = (void *)fit;		  /* search in FIT image */
		*compat_noffset = noffset; /* search under config node */
		return 0;
	}

	kfdt_name = fdt_getprop(fit, noffset, "fdt", &len);
	if (!kfdt_name) {
		debug("No fdt property found.\n");
		return -1;
	}

	kfdt_noffset = fdt_subnode_offset(fit, images_noffset, kfdt_name);
	if (kfdt_noffset < 0) {
		debug("No image node named \"%s\" found.\n", kfdt_name);
		return -1;
	}

	if (!fit_image_check_comp(fit, kfdt_noffset, IH_COMP_NONE)) {
		debug("Can't extract compat from \"%s\" (compressed)\n", kfdt_name);
		return -1;
	}

	if (fit_image_get_data_and_size(fit, kfdt_noffset, fdt, &sz)) {
		debug("Failed to get fdt \"%s\".\n", kfdt_name);
		return -1;
	}
	*compat_noffset = 0;  /* search kFDT under root node */

	return 0;
}

static int fit_check_match(const void *fdt, int compat_noffset, const char *mnf_name, 
			   const char *mnf_hw_branch)
{
	int comp_noffset = 0, tlt_compat_noffset = -1, comp_depth = 0;
	int mnf_name_len = mnf_name ? strlen(mnf_name) : 0;
	int mnf_hw_branch_len = mnf_hw_branch ? strlen(mnf_hw_branch) : 0;
	int ret = -1;

	tlt_compat_noffset = fdt_subnode_offset(fdt, compat_noffset, FIT_TLT_COMPAT_PROP);

	if (tlt_compat_noffset < 0) {
		return -1;
	}

	for (comp_noffset = fdt_next_node(fdt, tlt_compat_noffset, &comp_depth);
	     (comp_noffset >= 0) && (comp_depth > 0);
	     comp_noffset = fdt_next_node(fdt, comp_noffset, &comp_depth))
	{
		int dtb_name_len = 0, dtb_hw_branch_len = 0;
		const char *dtb_devname = NULL, *dtb_hw_branch = NULL;

		if (comp_depth > 1) {
			continue;
		}
		dtb_devname = fdt_getprop(fdt, comp_noffset, FIT_DEVNAME_PROP, &dtb_name_len);

		// fdt_getprop returns string length including null terminator
		dtb_name_len--;

		if (!dtb_devname || mnf_name_len < dtb_name_len ||
		    strncmp(dtb_devname, mnf_name, dtb_name_len)) {
			continue;
		}

		if (ret < 1) {
			ret = 1;
		}
		dtb_hw_branch = fdt_getprop(fdt, comp_noffset, FIT_HWBRANCH_PROP, &dtb_hw_branch_len);
		dtb_hw_branch_len--;

		// if mnf_hw_branch is empty, prefer config with empty hw-branch 
		if (!mnf_hw_branch && !dtb_hw_branch) {
			ret = 2;
			return ret;
		}

		if (!dtb_hw_branch) {
			continue;
		}

		if (dtb_hw_branch_len == mnf_hw_branch_len &&
		    !strncmp(dtb_hw_branch, mnf_hw_branch, mnf_hw_branch_len)) {
			ret = 3;
			return ret;
		}
	}

	return ret;
}

static const char *fit_find_best_match(const void *fit, const char *name, const char *hw_branch)
{
	int ndepth = 0;
	int noffset, confs_noffset, images_noffset;
	int best_match_offset = -1, best_match = -1, ret = 0;

	confs_noffset = fdt_path_offset(fit, FIT_CONFS_PATH);
	images_noffset = fdt_path_offset(fit, FIT_IMAGES_PATH);

	if (confs_noffset < 0 || images_noffset < 0) {
		printf("FIT: can't find configurations or images nodes.\n");
		return NULL;
	}

	for (noffset = fdt_next_node(fit, confs_noffset, &ndepth);
	     (noffset >= 0) && (ndepth > 0);
	     noffset = fdt_next_node(fit, noffset, &ndepth))
	{
		const void *fdt = NULL;
		int compat_noffset = -1;

		if (ndepth > 1) {
			continue;
		}

		if (fit_find_tlt_compat_node(fit, noffset, &fdt, &compat_noffset, images_noffset) < 0) {
			continue;
		}
		ret = fit_check_match(fdt, compat_noffset, name, hw_branch);

		if (ret > best_match) {
			best_match_offset = noffset;
			best_match = ret;
		}
	}

	if (best_match_offset < 0) {
		return NULL;
	}

	return fdt_get_name(fit, best_match_offset, NULL);
}

static int boot_multidtb(const void *fit)
{
	char mnf_name[16]  = { 0 };
	char mnf_hwbranch[8] = { 0 };
	const char *conf_name;
	int ret;

	ret = mnf_get_field("name", mnf_name);

	if (ret) {
		printf("\x1b[31mMDTB: MNF name seems incorrect\x1b[0m\n");
		strcpy(mnf_name, CONFIG_DEVICE_MODEL_MNF_DEFAULT); // fallback
	}
	mnf_get_field("branch", mnf_hwbranch);

	if (!(conf_name = fit_find_best_match(fit, mnf_name, mnf_hwbranch))) {
		printf("\x1b[31mMDTB failed: using default configuration\x1b[0m\n");
		return run_commandf("bootm %x", (size_t)fit);
	}

	return run_commandf("bootm %x#%s", (size_t)fit, conf_name);
}

static int do_bootmdtb(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	unsigned long addr;
	int ret;

	if (argc == 2) {
		ret = strict_strtoul(argv[1], 16, &addr);
		if (ret) {
			return CMD_RET_USAGE;
		}
	} else {
		addr = CONFIG_SYS_LOAD_ADDR;
	}

	return boot_multidtb((const void *)addr);
}

U_BOOT_CMD(bootmdtb, 2, 0, do_bootmdtb, "Boot from MultiDTB FIT image", "<addr>");

static struct mmc *tlt_init_mmc_device(int dev, bool force_init,
				     enum bus_mode speed_mode)
{
	struct mmc *mmc;
	mmc = find_mmc_device(dev);
	if (!mmc) {
		printf("no mmc device at slot %x\n", dev);
		return NULL;
	}

	if (!mmc_getcd(mmc))
		force_init = true;

	if (force_init)
		mmc->has_init = 0;

	if (IS_ENABLED(CONFIG_MMC_SPEED_MODE_SET))
		mmc->user_speed_mode = speed_mode;

	if (mmc_init(mmc))
		return NULL;

#ifdef CONFIG_BLOCK_CACHE
	struct blk_desc *bd = mmc_get_blk_desc(mmc);
	blkcache_invalidate(bd->uclass_id, bd->devnum);
#endif

	return mmc;
}

static int tlt_mmc_read(struct mmc *mmc, void *addr, size_t size)
{
	ulong cnt = DIV_ROUND_UP(size, mmc->read_bl_len);
	ulong blk = 0;
	ulong n;

	printf("\nMMC read: block # %ld, count %ld ... ", blk, cnt);

	n = blk_dread(mmc_get_blk_desc(mmc), blk, cnt, addr);
	printf("%ld blocks read: %s\n", n, (n == cnt) ? "OK" : "ERROR");

	return (n == cnt) ? CMD_RET_SUCCESS : CMD_RET_FAILURE;
}

static int boot_emmc(int slot)
{
	char *part_name;
	int hwpart;
	int ret;
	size_t total_size = 0;
	void *fit;
	struct mmc *mmc;
	size_t fdt_hdrlen;

	printf("Loading RutOS from eMMC slot %d...\n", slot);

	if (!(slot == 0 || slot == 1)) {
		eprintf("ERROR: Invalid eMMC slot\n");
		return CMD_RET_FAILURE;
	}

	part_name = (slot == 0) ? TLT_SLOT_0 : TLT_SLOT_1;
	hwpart = (slot == 0) ? TLT_HWPART_0 : TLT_HWPART_1;

	env_set("rutos_part", part_name);

	mmc = tlt_init_mmc_device(MMC_DEV, true, MMC_MODES_END);
	if (!mmc)
		return CMD_RET_FAILURE;

	ret = blk_select_hwpart_devnum(UCLASS_MMC, MMC_DEV, hwpart);
	printf("switch to partitions #%d, %s\n",
	       hwpart, (!ret) ? "OK" : "ERROR");
	if (ret)
		return CMD_RET_FAILURE;
	
	// Read FDT header
	ret = tlt_mmc_read(mmc, (void *)CONFIG_SYS_LOAD_ADDR, sizeof(struct fdt_header));
	if (ret)
		return CMD_RET_FAILURE;

	fdt_hdrlen = fdt_totalsize((struct fdt_header *)CONFIG_SYS_LOAD_ADDR);
	fdt_hdrlen = min(fdt_hdrlen, (size_t)FDT_MAX_IMAGE_SIZE);

	// Read FDT blob
	ret = tlt_mmc_read(mmc, (void *)CONFIG_SYS_LOAD_ADDR, fdt_hdrlen);
	if (ret)
		return CMD_RET_FAILURE;

	// Read FDT with all external data
	fit = (void *)map_sysmem(CONFIG_SYS_LOAD_ADDR, 0);
	total_size = fit_get_totalsize(fit);
	unmap_sysmem(fit);

	ret = tlt_mmc_read(mmc, (void *)CONFIG_SYS_LOAD_ADDR, total_size);
	if (ret)
		return CMD_RET_FAILURE;

	return boot_multidtb((const void *)CONFIG_SYS_LOAD_ADDR);
}

static int do_bootemmc(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	if (argc != 2)
		return CMD_RET_USAGE;

	return boot_emmc(simple_strtol(argv[1], NULL, 10));
}

U_BOOT_CMD(bootemmc, 2, 0, do_bootemmc, "Boot RutOS eMMC slot", "<slot>\n\n<slot> must be 0 or 1\n");

static int boot_recovery(void)
{
	struct mtd_info *mtd;
	int ret;
	size_t retlen;

	printf("Booting RutOS from NOR recovery ramdisk...\n");

	mtd_probe_devices();

	mtd = get_mtd_device_nm(TLT_RECOVERY_SLOT);
	if (IS_ERR_OR_NULL(mtd)) {
		eprintf("ERROR: MTD device %s not found, ret %ld\n", TLT_RECOVERY_SLOT, PTR_ERR(mtd));
		return PTR_ERR(mtd);
	}

	ret = mtd_read(mtd, 0, mtd->size, &retlen, (u_char *)CONFIG_SYS_LOAD_ADDR);
	if (ret) {
		eprintf("ERROR: Failed to read MTD device (rc = %d)\n", ret);
		return ret;
	}

	return run_commandf("bootm %x", (size_t)CONFIG_SYS_LOAD_ADDR);
}

static int do_bootrecovery(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	if (argc != 1)
		return CMD_RET_USAGE;

	boot_recovery();

	return CMD_RET_FAILURE;
}

U_BOOT_CMD(bootrecovery, 1, 0, do_bootrecovery, "Boot RutOS NOR recovery ramdisk", "\n");

static int boot_failsafe(void)
{
	fsb_context fsb_ctx;
	int slot;

	fsb_context_load(&fsb_ctx);
	fsb_config_dbg(&fsb_ctx.config_active);

	slot = fsb_config_pick_slot(&fsb_ctx.config_active);
	fsb_info("Chosen slot: %s\n", fsb_slot_str(slot));
	fsb_info("Attempts remaining: %d\n", fsb_ctx.config_active.slots[slot].tries_remaining);

	fsb_config_mark_slot(&fsb_ctx.config_new, slot);
	fsb_context_save(&fsb_ctx);

	switch (slot) {
	case 0:
	case 1:
		return boot_emmc(slot);
		break;
	case 2:
		boot_recovery();
		break;
	default:
		fsb_err("Unknown RutOS slot %d\n", slot);
		return 1;
	}

	// If we are still here, it means that booting one of the slots failed on our side.
	return CMD_RET_FAILURE;
}

static int do_bootfailsafe(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	if (argc != 1)
		return CMD_RET_USAGE;

	return boot_failsafe();
}

U_BOOT_CMD(bootfailsafe, 1, 1, do_bootfailsafe, "Failsafe RutOS boot", "\n");
