#include <tlt/fsupdate.h>
#include <tlt/fsb.h>
#include <mtdutils/ubiformat.h>

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

int fsb_update(const void *image, size_t size)
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
