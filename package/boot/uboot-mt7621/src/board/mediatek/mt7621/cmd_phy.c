#include <command.h>
#include <common.h>
#include <linux/string.h>
#include <net.h>

struct mtk_eth_priv;
extern int mt7530_set_link(struct mtk_eth_priv *priv, int port, bool enable);
extern struct mtk_eth_priv *mtk_global_priv;
#define MT7621_PHY_CNT 5

int do_phy_power_set(struct cmd_tbl *cmd, int flag, int argc, char *const argv[])
{
	int phy;
	int power;

	if (argc != 3) {
		return CMD_RET_USAGE;
	}

	eth_lazy_init();

        if (mtk_global_priv == NULL) {
                printf("Error: no mt7621 ethernet device probed\n");
                return CMD_RET_FAILURE;
        }

	power = argv[2][0] - '0';

	if (!strcmp(argv[1], "all")) {
		for (phy = 0; phy < MT7621_PHY_CNT; phy++) {
			mt7530_set_link(mtk_global_priv, phy, power);
		}
	} else {
                phy = argv[1][0] - '0';

		if (phy < 0 || phy > MT7621_PHY_CNT) {
			return CMD_RET_USAGE;
		}

		mt7530_set_link(mtk_global_priv, phy, power);
	}

	return CMD_RET_SUCCESS;
}

U_BOOT_CMD(phy_power_set, 3, 1, do_phy_power_set,
	"set phy power state",
	"id\n"
	"	- phy to operate on. \"all\" or an integer\n"
	"power\n"
	"	- value to set the power to\n"
);