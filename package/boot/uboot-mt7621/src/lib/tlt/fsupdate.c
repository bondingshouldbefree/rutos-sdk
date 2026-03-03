#include <tlt/fsupdate.h>
#include <tlt/fsb.h>
#include <mtdutils/ubiformat.h>
#include <mmc.h>
#include <linux/libfdt.h>

static int getprimary(fsb_context *ctx)
{
	return (fsb_config_pick_slot(&(ctx->config_new)) == FSB_SLOT_NAND_B) ? FSB_SLOT_NAND_A :
									       FSB_SLOT_NAND_B;
}

static int getsecondary(int primary)
{
	return (primary == FSB_SLOT_NAND_B) ? FSB_SLOT_NAND_A : FSB_SLOT_NAND_B;
}

static void mark_update_begin(fsb_context *ctx, int primary)
{
	int secondary = getsecondary(primary);

	ctx->config_new.slots[FSB_SLOT_RECOVERY].force = 0;
	if (ctx->config_new.slots[FSB_SLOT_RECOVERY].priority >= 9) {
		ctx->config_new.slots[FSB_SLOT_RECOVERY].priority = 1;
	}

	ctx->config_new.slots[secondary].force = 0;
	if (ctx->config_new.slots[secondary].priority >= 9) {
		ctx->config_new.slots[secondary].priority = 8;
	}

	ctx->config_new.slots[primary].force	       = 0;
	ctx->config_new.slots[primary].priority	       = 0;
	ctx->config_new.slots[primary].successful_boot = 0;
	ctx->config_new.slots[primary].tries_remaining = 1;

	fsb_context_save(ctx);
}

static void mark_update_end(fsb_context *ctx, int primary)
{
	ctx->config_new.slots[primary].priority = 9;

	fsb_context_save(ctx);
}

#ifdef CONFIG_TLT_NAND_BOOTCMDS
int fsb_update_nand(const void *image, size_t size)
{
	fsb_context ctx;
	int primary;
	int ret;
	struct ubiformat_args args = {
		.ubi_ver = 1,
	};

	fsb_context_load(&ctx);
	primary = getprimary(&ctx);
	mark_update_begin(&ctx, primary);

	ret = ubiformat(fsb_slot_str(primary), image, size, &args);
	if (ret) {
		return ret;
	}

	mark_update_end(&ctx, primary);

	return 0;
}
#endif

#ifdef CONFIG_TLT_EMMCGPP_BOOTCMDS

#define MMC_DEV 0
#define TLT_HWPART_0	  4 // GPP1
#define TLT_HWPART_1	  5 // GPP2

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

static int tlt_mmc_erase(struct mmc *mmc, size_t size)
{
	ulong cnt = DIV_ROUND_UP(size, mmc->read_bl_len);
	ulong blk = 0;
	ulong n;

	// Round down to nearest erase group
	cnt = cnt & ~(mmc->erase_grp_size - 1);

	printf("\nMMC erase: block # %ld, count %ld ... ", blk, cnt);

	if (mmc_getwp(mmc) == 1) {
		printf("Error: card is write protected!\n");
		return -EPERM;
	}
	n = blk_derase(mmc_get_blk_desc(mmc), blk, cnt);
	printf("%ld blocks erased: %s\n", n, (n == cnt) ? "OK" : "ERROR");

	return (n == cnt) ? 0 : -EIO;
}

static int tlt_mmc_write(struct mmc *mmc, const void *addr, size_t size)
{
	ulong cnt = DIV_ROUND_UP(size, mmc->read_bl_len);
	ulong blk = 0;
	ulong n;

	printf("\nMMC write: block # %ld, count %ld ... ", blk, cnt);

	if (mmc_getwp(mmc) == 1) {
		printf("Error: card is write protected!\n");
		return -EPERM;
	}
	n = blk_dwrite(mmc_get_blk_desc(mmc), blk, cnt, addr);
	printf("%ld blocks written: %s\n", n, (n == cnt) ? "OK" : "ERROR");

	return (n == cnt) ? 0 : -EIO;
}

int fsb_update_emmcgpp(const void *image, size_t size)
{
	fsb_context ctx;
	int primary;
	int ret;
	int hwpart;
	struct mmc *mmc;

	if (fdt_check_header(image) != 0) {
		fsb_err("Incorrect image format, expected FIT\n");
		return -EINVAL;
	}

	fsb_context_load(&ctx);
	primary = getprimary(&ctx);
	mark_update_begin(&ctx, primary);

	fsb_info("chosen FSB slot %s\n", fsb_slot_str(primary));
	hwpart = (primary == 0) ? TLT_HWPART_0 : TLT_HWPART_1;

	mmc = tlt_init_mmc_device(MMC_DEV, true, MMC_MODES_END);
	if (!mmc)
		return -ENOENT;

	ret = blk_select_hwpart_devnum(UCLASS_MMC, MMC_DEV, hwpart);
	printf("switch to partitions #%d, %s\n",
	       hwpart, (!ret) ? "OK" : "ERROR");
	if (ret)
		return -EINVAL;

	ret = tlt_mmc_erase(mmc, mmc->capacity_gp[hwpart - 4]);
	if (ret)
		return ret;
	
	ret = tlt_mmc_write(mmc, image, size);
	if (ret)
		return ret;

	mark_update_end(&ctx, primary);

	return 0;
}
#endif // CONFIG_TLT_EMMCGPP_BOOTCMDS

int fsb_update(const void *image, size_t size)
{
#ifdef CONFIG_TLT_EMMCGPP_BOOTCMDS
	return fsb_update_emmcgpp(image, size);
#elif defined(CONFIG_TLT_NAND_BOOTCMDS)
	return fsb_update_nand(image, size);
#else
	return -ENOTSUPP;
#endif
}
