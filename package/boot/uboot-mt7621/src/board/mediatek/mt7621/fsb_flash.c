#include <mtd.h>

#include <tlt/fsb.h>
#include <tlt/fsb_flash.h>

#define FSB_PARTITION_0_NAME "bootconfig-a"
#define FSB_PARTITION_1_NAME "bootconfig-b"

static struct mtd_info *get_bc_mtd(fsb_partition partition)
{
	struct mtd_info *mtd;
	const char *mtd_name;

	switch (partition) {
	case FSB_PARTITION_PRIMARY:
		mtd_name = FSB_PARTITION_0_NAME;
		break;
	case FSB_PARTITION_SECONDARY:
		mtd_name = FSB_PARTITION_1_NAME;
		break;
	default:
		return NULL;
	}

	mtd_probe_devices();

	mtd = get_mtd_device_nm(mtd_name);
	if (IS_ERR_OR_NULL(mtd)) {
		fsb_err("MTD device %s not found, ret %ld\n", mtd_name, PTR_ERR(mtd));
		return NULL;
	}

	return mtd;
}

int fsb_flash_read(fsb_partition partition, fsb_config out[], size_t out_size, size_t *read)
{
	struct mtd_info *mtd = get_bc_mtd(partition);
	int ret;
	size_t retlen;
	int num_read;

	if (!mtd)
		return 1;

	num_read = min(out_size, (size_t)mtd->size / sizeof(fsb_config));

	ret = mtd_read(mtd, 0, num_read * sizeof(fsb_config), &retlen, (u_char *)out);
	if (ret)
		return ret;

	*read = num_read;
	return 0;
}

int fsb_flash_write(fsb_partition partition, size_t idx, fsb_config *bc)
{
	struct mtd_info *mtd = get_bc_mtd(partition);
	size_t retlen;
	size_t ofs = idx * sizeof(fsb_config);

	if (!mtd)
		return 1;

	return mtd_write(mtd, ofs, sizeof(fsb_config), &retlen, (u_char *)bc);
}

int fsb_flash_erase(fsb_partition partition)
{
	struct mtd_info *mtd = get_bc_mtd(partition);

	if (!mtd)
		return 1;

	struct erase_info erase_op = { .mtd = mtd, .addr = 0, .len = mtd->size };

	return mtd_erase(mtd, &erase_op);
}