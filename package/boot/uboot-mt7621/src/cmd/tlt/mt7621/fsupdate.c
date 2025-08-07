#include <common.h>
#include <command.h>
#include <tlt/fsupdate.h>

static int do_fsupdate(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[]) 
{
	unsigned long addr;
	unsigned long len;
	int ret;
	
	if (argc != 3) {
		return CMD_RET_USAGE;
	}

	ret = strict_strtoul(argv[1], 16, &addr);
	if (ret) {
		return CMD_RET_USAGE;
	}

	ret = strict_strtoul(argv[2], 16, &len);
	if (ret) {
		return CMD_RET_USAGE;
	}

	return fsb_update((void*)addr, len) != 0;
}

U_BOOT_CMD(fsupdate, 3, 0, do_fsupdate, "fail safe update", 
	"<addr> <len>\n");