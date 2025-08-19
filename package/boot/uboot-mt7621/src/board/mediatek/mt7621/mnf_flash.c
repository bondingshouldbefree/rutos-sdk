#include <tlt/mnf_info.h>
#include <mtd.h>
#include <string.h>

#define MNF_MTD_PARTITION "config"
#define MNF_INFO_SIZE	  0x10000

static char mnf_cache[MNF_INFO_SIZE];

static struct mtd_info *get_mtd_part(void)
{
	struct mtd_info *mtd;

	mtd_probe_devices();

	mtd = get_mtd_device_nm(MNF_MTD_PARTITION);
	if (IS_ERR_OR_NULL(mtd))
		return NULL;

	return mtd;
}

extern int mnf_flash_read(const mnf_field_t *field, char *result)
{
	struct mtd_info *mtd = get_mtd_part();
	size_t retlen;

	if (!mtd)
		return -ENODEV;

	return mtd_read(mtd, field->offset, field->length, &retlen, (u_char *)result);
}

extern int mnf_flash_write_init(void)
{
	struct mtd_info *mtd = get_mtd_part();
	size_t retlen;

	if (!mtd)
		return -ENODEV;

	return mtd_read(mtd, 0, MNF_INFO_SIZE, &retlen, (u_char *)mnf_cache);
}

extern int mnf_flash_write(const mnf_field_t *field, const char *buf)
{
	memcpy(mnf_cache + field->offset, buf, field->length);
	return 0;
}

extern int mnf_flash_write_finalize(void)
{
	struct mtd_info *mtd = get_mtd_part();
	struct erase_info erase_op = { .mtd = mtd, .addr = 0, .len = mtd->size };
	size_t retlen;
	int ret;

	if (!mtd)
		return -ENODEV;

	ret = mtd_erase(mtd, &erase_op);
	if (ret)
		return ret;

	return mtd_write(mtd, 0, MNF_INFO_SIZE, &retlen, (u_char *)mnf_cache);
}