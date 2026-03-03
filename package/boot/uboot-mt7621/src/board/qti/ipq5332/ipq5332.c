// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (c) 2023, Qualcomm Innovation Center, Inc. All rights reserved.
 */

#include <common.h>
#include <cpu_func.h>
#include <asm/cache.h>
#include <asm/global_data.h>
#include <sysreset.h>
#include <linux/psci.h>
#ifdef CONFIG_ARM64
#include <asm/armv8/mmu.h>
#endif

#include "../common/ipq_board.h"

#include <asm/io.h>
#include <linux/delay.h>

#define PLL_POWER_ON_AND_RESET			0x9B780
#define PLL_REFERENCE_CLOCK			0x9B784
#define FREQUENCY_MASK				0xfffffdf0
#define INTERNAL_48MHZ_CLOCK			0x7

DECLARE_GLOBAL_DATA_PTR;

static dram_bank_info_t ipq5332_dram_bank_info[CONFIG_NR_DRAM_BANKS] = {
	{
		.start = CFG_SYS_SDRAM_BASE,
		.size  = CFG_SYS_SDRAM_BASE_MAX_SZ,
	},
};

dram_bank_info_t * board_dram_bank_info = ipq5332_dram_bank_info;

void reset_cpu(void)
{
	psci_sys_reset(SYSRESET_COLD);
	return;
}

int print_cpuinfo(void)
{
        return 0;
}

void board_cache_init(void)
{
	ipq_smem_flash_info_t *sfi = get_ipq_smem_flash_info();
	icache_enable();
#if !CONFIG_IS_ENABLED(SYS_DCACHE_OFF)
	/* Disable L2 as TCM in recovery mode */
	if (!sfi->flash_type)
		writel(0x08000000, 0xB110010);

	dcache_enable();
#endif
}

void lowlevel_init(void)
{
	return;
}

void ipq_config_cmn_clock(void)
{
	unsigned int reg_val;
	/*
	 * Init CMN clock for ethernet
	 */
	reg_val = readl(PLL_REFERENCE_CLOCK);
	reg_val = (reg_val & FREQUENCY_MASK) | INTERNAL_48MHZ_CLOCK;
	/*Select clock source*/
	writel(reg_val, PLL_REFERENCE_CLOCK);

	/* Soft reset to calibration clocks */
	reg_val = readl(PLL_POWER_ON_AND_RESET);
	reg_val &= ~BIT(6);
	writel(reg_val, PLL_POWER_ON_AND_RESET);
	mdelay(1);
	reg_val |= BIT(6);
	writel(reg_val, PLL_POWER_ON_AND_RESET);
	mdelay(1);
}

#ifdef CONFIG_ARM64
/*
 * Set XN (PTE_BLOCK_PXN | PTE_BLOCK_UXN)bit for all dram regions
 * and Peripheral block except uboot code region
 */
static struct mm_region ipq5332_mem_map[] = {
	{
		/* Peripheral block */
		.virt = 0x0UL,
		.phys = 0x0UL,
		.size = CFG_SYS_SDRAM_BASE,
		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
			 PTE_BLOCK_NON_SHARE |
			 PTE_BLOCK_PXN | PTE_BLOCK_UXN

	}, {
		/* DDR region upto u-boot CONFIG_TEXT_BASE */
		.virt = CFG_SYS_SDRAM_BASE,
		.phys = CFG_SYS_SDRAM_BASE,
		.size = CONFIG_TEXT_BASE - CFG_SYS_SDRAM_BASE,
		.attrs = PTE_BLOCK_MEMTYPE(MT_NORMAL) |
			 PTE_BLOCK_INNER_SHARE |
			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
	}, {
		/* DDR region U-boot text base */
		.virt = CONFIG_TEXT_BASE,
		.phys = CONFIG_TEXT_BASE,
		.size = CONFIG_TEXT_SIZE,
		.attrs = PTE_BLOCK_MEMTYPE(MT_NORMAL) |
			 PTE_BLOCK_INNER_SHARE
	}, {
		/*
		 * DDR region after u-boot text base
		 * added dummy 0xBAD0FF5EUL,
		 * will update the actual DDR limit
		 */
		.virt = CONFIG_TEXT_BASE + CONFIG_TEXT_SIZE,
		.phys = CONFIG_TEXT_BASE + CONFIG_TEXT_SIZE,
		.size = 0x0UL,
		.attrs = PTE_BLOCK_MEMTYPE(MT_NORMAL) |
			 PTE_BLOCK_INNER_SHARE |
			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
	}, {
		/* List terminator */
		0,
	}
};

struct mm_region *mem_map = ipq5332_mem_map;
#endif
