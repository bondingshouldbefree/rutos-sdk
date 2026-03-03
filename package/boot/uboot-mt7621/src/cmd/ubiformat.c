#include <command.h>
#include <common.h>
#include <mtd.h>
#include <stdint.h>
#include <stdlib.h>
#include <mtdutils/ubiformat.h>

static int do_ubiformat(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[]) 
{
	const char* mtd_name;
	unsigned long addr;
	unsigned long len;
	int ret;
	
	struct ubiformat_args args = {
		.ubi_ver = 1, 
		.verbose = 0
	};

	if (argc != 4) {
		return CMD_RET_USAGE;
	}

	mtd_name = argv[1];

	ret = strict_strtoul(argv[2], 16, &addr);
	if (ret) {
		return CMD_RET_USAGE;
	}

	ret = strict_strtoul(argv[3], 16, &len);
	if (ret) {
		return CMD_RET_USAGE;
	}

	return ubiformat(mtd_name, (void*)addr, len, &args);
}

U_BOOT_CMD(ubiformat, 4, 0, do_ubiformat, "ubiformat", 
	"<mtd> <addr> <len>\n");