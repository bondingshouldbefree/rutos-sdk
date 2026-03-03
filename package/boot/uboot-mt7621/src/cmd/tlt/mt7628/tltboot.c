#include <common.h>
#include <command.h>
#include <ctype.h>
#include <mtd.h>
#include <image.h>
#include <tlt/mnf_info.h>


static int boot_multidtb(const void *fit) {
	char code_str[32] = {0};
	char code_fixed[16] = {0};
	char hwver_str[32] = {0};
	char name[16], *conf_name = name;
	char bootargs[256];
	int ret;

	char mnf_name[16] = { 0 };
	ret = mnf_get_field("name", mnf_name);

	if (!ret && strlen(mnf_name) >= 6) {
		strncpy(code_fixed, mnf_name, 12);

		if (!strncmp(mnf_name, "RUTM", 4)){
			strncpy(code_str, mnf_name + 4, 2);
		}else {
			strncpy(code_str, mnf_name, 6);
			tolower(*code_str);
		}
	} else {
		strcpy(code_str, "08"); // fallback
		printf("\x1b[31mMDTB failed: MNF data seems incorrect\x1b[0m\n");
	}

	char mnf_hwver[16] = { 0 };
	char mnf_hwver_lo[16] = { 0 };
	char mnf_branch[16] = { 0 };

	ret = 0;
	ret |= mnf_get_field("branch", mnf_branch);
	ret |= mnf_get_field("hwver", mnf_hwver);
	ret |= mnf_get_field("hwver_lo", mnf_hwver_lo);

	if (ret) {
		printf("\x1b[31mMDTB failed: Failed to get full HW version\x1b[0m\n");
		goto mnf_done;
	}

	long hwver_hi = simple_strtol(mnf_hwver, NULL, 10);
	if (hwver_hi > 99) {
		hwver_hi /= 100;
	}

	long hwver_lo = simple_strtol(mnf_hwver_lo, NULL, 10);
	if (hwver_lo > 99) {
		hwver_lo /= 100;
	}

	hwver_hi = 100 * hwver_hi + hwver_lo;
	sprintf(hwver_str, "v%s%ld", mnf_branch, hwver_hi);

mnf_done:

	for (unsigned i = 1; i < 100; i++) {
		sprintf(name, "conf_mdtb@%d", i);

		int offset = fit_conf_get_node(fit, name);
		char *dtb_desc = NULL;
		char *dtb_hwver = NULL;
		if (offset < 0 || fit_get_desc(fit, offset, &dtb_desc)) {
			break;
		}

		fit_get_full_hwver(fit, offset, &dtb_hwver);

		if ((!dtb_hwver[0] && !strcasecmp(code_str, dtb_desc)) ||
				(dtb_hwver[0] && !strcasecmp(code_str, dtb_desc) &&
				 !strcasecmp(hwver_str, dtb_hwver))) {
			printf("\x1b[32mMDTB: suitable DTB found: %s, desc = %s, hwver = %s \x1b[0m\n",
					name, dtb_desc, dtb_hwver ? dtb_hwver : "none");
			goto bootm;
		}
	}

	printf("\x1b[31mMDTB failed: suitable DTB not found\x1b[0m\n");
	conf_name = "conf_mdtb@1";

bootm:
	snprintf(bootargs, sizeof(bootargs),
		 "%s%s %s%s hwver=%ld",
		 code_fixed[0] ? "device=" : "",
		 code_fixed[0] ? code_fixed : "",
		 mnf_branch[0] ? "hwbranch=" : "",
		 mnf_branch[0] ? mnf_branch: "",
		 hwver_hi);

	printf("using cmdline: %s\n", bootargs);
	env_set("bootargs", bootargs);

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

#define SQUASHFS_MAGIC  0x73717368
#define JFFS2_MAGIC     0x19852003
#define UBI_EC_MAGIC    0x55424923
#define EB_SIZE         65536

int mtd_check_rootfs_magic(struct mtd_info *mtd, size_t offset, char *wr_ptr)
{
	u32 magic;
	size_t retlen;
	int ret;
	const char *type;

	ret = mtd_read(mtd, offset, EB_SIZE, &retlen, wr_ptr);
	if (ret)
		return ret;

	if (retlen != EB_SIZE)
		return -EIO;

	magic = *(u32*)wr_ptr;

	if (le32_to_cpu(magic) == SQUASHFS_MAGIC) {
		type = "squashfs";
	} else if (magic == JFFS2_MAGIC) {
		type = "jffs2";
	} else if (be32_to_cpu(magic) == UBI_EC_MAGIC) {
		type = "ubifs";
	} else {
		return -EINVAL;
	}

	printf("Found rootfs(%s) found at 0x%x\n", type, offset);
	return 0;
}

static int mtd_find_rootfs_from(struct mtd_info *mtd,
			 size_t from,
			 size_t limit,
			 size_t *ret_offset,
			 char *wr_ptr)
{
	int err;

	for (size_t offset = 0; offset < limit; offset += EB_SIZE) {
		err = mtd_check_rootfs_magic(mtd, offset, wr_ptr + offset);
		if (err)
			continue;

		*ret_offset = offset;
		return 0;
	}

	return -ENODEV;
}

static int boot_nor(void)
{
	int ret;
	struct mtd_info *mtd;
	size_t rootfs_off;

	printf("Booting RutOS...\n");

	mtd_probe_devices();

	mtd = get_mtd_device_nm("firmware");
	if (IS_ERR_OR_NULL(mtd)) {
		eprintf("ERROR: Firmware MTD not found\n");
		return -ENODEV;
	}

	ret = mtd_find_rootfs_from(mtd, 0, mtd->size, &rootfs_off, (char *)CONFIG_SYS_LOAD_ADDR);
	if (ret < 0) {
		printf("\x1b[31mScan failed: rootfs not found\x1b[0m\n");
		return ret;
	}

	return boot_multidtb((const void *)CONFIG_SYS_LOAD_ADDR);
}

static int do_bootnor(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	boot_nor();
	return CMD_RET_FAILURE;
}

U_BOOT_CMD(bootnor, 1, 0, do_bootnor, "Boot RutOS from NOR", "");

