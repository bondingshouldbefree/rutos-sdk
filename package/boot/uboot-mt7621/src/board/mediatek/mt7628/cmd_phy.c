#include <common.h>
#include <dm.h>
#include <net.h>
#include <command.h>

#define MT7628_PHY_CNT 5

int do_phy_power_set(struct cmd_tbl *cmd, int flag, int argc, char *const argv[])
{
#ifndef CONFIG_SPL_BUILD
	int phy;
	int power;
	struct udevice *dev;

	if (argc != 3) {
		return CMD_RET_USAGE;
	}

#ifdef CONFIG_NET_LAZY
	eth_lazy_init();
#endif

	dev = eth_get_dev();
	if (!dev) {
		return CMD_RET_FAILURE;
	}

	power = !!(argv[2][0] - '0');

	if (!strcmp(argv[1], "all")) {
		for (phy = 0; phy < MT7628_PHY_CNT; phy++) {
			eth_get_ops(dev)->link_set(dev, phy, power);
		}
	} else {
		phy = argv[1][0] - '0';

		if (phy < 0 || phy > MT7628_PHY_CNT) {
			return CMD_RET_USAGE;
		}

		eth_get_ops(dev)->link_set(dev, phy, power);
	}

#endif //CONFIG_SPL_BUILD
	return CMD_RET_SUCCESS;
}

U_BOOT_CMD(phy_power_set, 3, 1, do_phy_power_set, "set phy power state",
	   "id\n"
	   "	- phy to operate on. \"all\" or an integer\n"
	   "power\n"
	   "	- value to set the power to\n");
