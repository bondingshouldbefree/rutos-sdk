#include <common.h>
#include <command.h>
#include <ubi_uboot.h>
#include <mtd.h>
#include <image.h>
#include <tlt/fsb.h>
#include <tlt/mnf_info.h>

#define TLT_NAND_SLOT_0	  "rutos-a"
#define TLT_NAND_SLOT_1	  "rutos-b"
#define TLT_RECOVERY_SLOT "recovery"

static int boot_multidtb(const void *fit)
{
	char mnf_name[256];
	char desc[16] = { 0 };
	int ret;

	ret = mnf_get_field("name", mnf_name);

	if (!ret && strlen(mnf_name) >= 6) {
		if (!strncmp(mnf_name, "RUTM", 4)){
			strncpy(desc, mnf_name + 4, 2);
		}else {
			strncpy(desc, mnf_name, 6);
		}
	} else {
		strcpy(desc, "08"); // fallback
		printf("\x1b[31mMDTB failed: MNF data seems incorrect\x1b[0m\n");
	}

	char name[16], *conf_name = name;
	for (unsigned i = 1; i < 100; i++) {
		sprintf(name, "conf_mdtb@%d", i);

		int offset = fit_conf_get_node(fit, name);
		char *dtb_desc;
		if (offset < 0 || fit_get_desc(fit, offset, &dtb_desc)) {
			break;
		}

		// printf("\tdtb\tname=%s\tdesc=%s\tdtb_desc=%s\n", name, desc, dtb_desc);

		if (!strcasecmp(desc, dtb_desc)) {
			printf("MDTB: suitable DTB found: %s, desc = %s\n", name, dtb_desc);
			goto bootm;
		}
	}

	printf("\x1b[31mMDTB failed: suitable DTB not found\x1b[0m\n");
	conf_name = "conf_mdtb@1";

bootm:
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

static int boot_nand(int slot)
{
	char *mtd_name;
	int ret;
	char bootargs[256];

	printf("Booting RutOS from nand slot %d...\n", slot);

	if (!(slot == 0 || slot == 1)) {
		eprintf("ERROR: Invalid nand slot\n");
		return 1;
	}

	mtd_name = (slot == 0) ? TLT_NAND_SLOT_0 : TLT_NAND_SLOT_1;

	ret = ubi_part(mtd_name, NULL);
	if (ret)
		return ret;

	ret = ubi_volume_read("kernel", (char *)CONFIG_SYS_LOAD_ADDR, 0);
	if (ret)
		return ret;

	snprintf(bootargs, sizeof(bootargs),
		 "ubi.mtd=%s "
		 "ubi.block=0,1 "
		 "root=/dev/ubiblock0_1 "
		 "rootfstype=squashfs "
		 "console=ttyS0,115200n8",
		 mtd_name);

	env_set("bootargs", bootargs);

	printf("using cmdline: %s\n", bootargs);
	return boot_multidtb((const void *)CONFIG_SYS_LOAD_ADDR);
}

static int do_bootnand(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	if (argc != 2)
		return CMD_RET_USAGE;

	boot_nand(simple_strtol(argv[1], NULL, 10));

	return CMD_RET_FAILURE;
}

U_BOOT_CMD(bootnand, 2, 0, do_bootnand, "Boot RutOS nand slot", "<slot>\n\n<slot> must be 0 or 1\n");

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
		boot_nand(slot);
		break;
	case 2:
		boot_recovery();
		break;
	default:
		fsb_err("Unknown RutOS slot %d\n", slot);
		return 1;
	}

	// If we are still here, it means that booting one of the slots failed on our side.
	return 1;
}

static int do_bootfailsafe(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
{
	if (argc != 1)
		return CMD_RET_USAGE;

	boot_failsafe();

	return CMD_RET_FAILURE;
}

U_BOOT_CMD(bootfailsafe, 1, 1, do_bootfailsafe, "Failsafe RutOS boot", "\n");
