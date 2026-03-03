// SPDX-License-Identifier: GPL-2.0+
/*
 * Copyright (c) 2013, 2015-2017, 2020 The Linux Foundation. All rights reserved.
 *
 * Copyright (c) 2023, Qualcomm Innovation Center, Inc. All rights reserved.
 *
 * Based on smem.c from lk.
 *
 * Copyright (c) 2009, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/err.h>
#include <asm/byteorder.h>
#include <memalign.h>
#include <command.h>
#include <env.h>
#include <linux/delay.h>
#include <dm.h>
#include <smem.h>
#include <common.h>
#include <lmb.h>
#include <net.h>
#ifdef CONFIG_ARM64
#include <asm/armv8/mmu.h>
#endif
#include <cpu_func.h>
#include <asm/cache.h>
#include <asm/io.h>

#include "ipq_board.h"

DECLARE_GLOBAL_DATA_PTR;

uint32_t g_board_machid;

struct udevice *smem;

ipq_smem_flash_info_t ipq_smem_flash_info;
struct smem_ptable *ptable;
socinfo_t ipq_socinfo;

extern int ipq_smem_get_socinfo(void);

__weak void ipq_config_cmn_clock(void)
{
	return;
}

__weak void board_cache_init(void)
{
	icache_enable();
#if !CONFIG_IS_ENABLED(SYS_DCACHE_OFF)
	dcache_enable();
#endif
}

ipq_smem_flash_info_t * get_ipq_smem_flash_info(void)
{
	return &ipq_smem_flash_info;
}

socinfo_t * get_socinfo(void)
{
	return &ipq_socinfo;
}

void *smem_get_item(unsigned int item) {

	int ret = 0;
	struct udevice *smem_tmp;
	const char *name = "smem";
	size_t size;
	unsigned long int reloc_flag = (gd->flags & GD_FLG_RELOC);

	if (reloc_flag == 0)
		ret = uclass_get_device_by_name(UCLASS_SMEM, name, &smem_tmp);
	else if(!smem)
		ret = uclass_get_device_by_name(UCLASS_SMEM, name, &smem);

	if (ret < 0) {
		printf("Failed to find SMEM node. Check device tree %d\n", ret);
		return 0;
	}

	return smem_get(reloc_flag ? smem : smem_tmp, -1, item, &size);

}

__weak int get_soc_hw_version(void)
{
        return readl(CONFIG_SOC_HW_VERSION_REG);
}

int board_init(void)
{
	ipq_smem_bootconfig_info_t *ipq_smem_bootconfig_info;
	ipq_smem_flash_info_t *sfi = &ipq_smem_flash_info;
	uint32_t *flash_type;
	uint32_t *flash_chip_select;
	uint32_t *primary_mibib;
	uint32_t *flash_index;
	uint32_t *flash_block_size;
	uint32_t *flash_density;

	gd->bd->bi_boot_params = BOOT_PARAMS_ADDR;

	flash_type = smem_get_item(SMEM_BOOT_FLASH_TYPE);
	if (IS_ERR_OR_NULL(flash_type)) {
		debug("Failed to get SMEM item: SMEM_BOOT_FLASH_TYPE\n");
		flash_type = NULL;
	}

	flash_index = smem_get_item(SMEM_BOOT_FLASH_INDEX);
	if (IS_ERR_OR_NULL(flash_index)) {
		debug("Failed to get SMEM item: SMEM_BOOT_FLASH_INDEX\n");
		flash_index = NULL;
	}

	flash_chip_select = smem_get_item(SMEM_BOOT_FLASH_CHIP_SELECT);
	if (IS_ERR_OR_NULL(flash_chip_select)) {
		debug("Failed to get SMEM item: SMEM_BOOT_FLASH_CHIP_SELECT\n");
		flash_chip_select = NULL;
	}

	flash_block_size = smem_get_item(SMEM_BOOT_FLASH_BLOCK_SIZE);
	if (IS_ERR_OR_NULL(flash_block_size)) {
		debug("Failed to get SMEM item: SMEM_BOOT_FLASH_BLOCK_SIZE\n");
		flash_block_size = NULL;
	}

	flash_density = smem_get_item(SMEM_BOOT_FLASH_DENSITY);
	if (IS_ERR_OR_NULL(flash_density)) {
		debug("Failed to get SMEM item: SMEM_BOOT_FLASH_DENSITY\n");
		flash_density = NULL;
	}

	primary_mibib = smem_get_item(SMEM_PARTITION_TABLE_OFFSET);
	if (IS_ERR_OR_NULL(primary_mibib)) {
		debug("Failed to get SMEM item: " \
				"SMEM_PARTITION_TABLE_OFFSET\n");
		primary_mibib = NULL;
	}

	ipq_smem_bootconfig_info = smem_get_item(SMEM_BOOT_DUALPARTINFO);
	if (IS_ERR_OR_NULL(ipq_smem_bootconfig_info) ||
		(ipq_smem_bootconfig_info->magic_start !=
			_SMEM_DUAL_BOOTINFO_MAGIC_START) ||
		(ipq_smem_bootconfig_info->magic_end !=
			_SMEM_DUAL_BOOTINFO_MAGIC_END)) {
		debug("Failed to get SMEM item: SMEM_BOOT_DUALPARTINFO\n");
		ipq_smem_bootconfig_info = NULL;
	}

	sfi->flash_type = (!flash_type ? SMEM_BOOT_NO_FLASH : *flash_type);
	sfi->flash_index = (!flash_index ? 0 : *flash_index);
	sfi->flash_chip_select = (!flash_chip_select ? 0 : *flash_chip_select);
	sfi->flash_block_size = (!flash_block_size ? 0: *flash_block_size);
	sfi->flash_density = (!flash_density ? 0 : *flash_density);
	sfi->primary_mibib = (!primary_mibib ? 0 : *primary_mibib);
	sfi->ipq_smem_bootconfig_info = ipq_smem_bootconfig_info;

	/*
	 * get soc_version, cpu_type, machid
	 */
	ipq_smem_get_socinfo();

	return 0;
}

int ipq_smem_get_socinfo()
{
	union ipq_platform *platform_type;

	platform_type = smem_get_item(SMEM_HW_SW_BUILD_ID);
	if (IS_ERR_OR_NULL(platform_type)) {
		debug("Failed to get SMEM item: SMEM_HW_SW_BUILD_ID\n");
		return -ENODEV;
	}

	ipq_socinfo.cpu_type = platform_type->v1.id;
	ipq_socinfo.version = platform_type->v1.version;
	ipq_socinfo.soc_version_major =
				SOCINFO_VERSION_MAJOR(ipq_socinfo.version);
	ipq_socinfo.soc_version_minor =
				SOCINFO_VERSION_MINOR(ipq_socinfo.version);
	ipq_socinfo.machid = g_board_machid;

	return 0;

}

/*
 * This function is called in the very beginning.
 * Retreive the machtype info from SMEM and map the board specific
 * parameters. Shared memory region at Dram address
 * contains the machine id/ board type data polulated by SBL.
 */
int board_early_init_f(void)
{
#ifdef CONFIG_SMEM_VERSION_C
	union ipq_platform *platform_type;

	platform_type = smem_get_item(SMEM_HW_SW_BUILD_ID);
	if (IS_ERR_OR_NULL(platform_type)) {
		debug("Failed to get SMEM item: SMEM_HW_SW_BUILD_ID\n");
		return -ENODEV;
	}

	g_board_machid = ((platform_type->v1.hw_platform << 24) |
			  ((SOCINFO_VERSION_MAJOR(
				platform_type->v1.platform_version)) << 16) |
			  ((SOCINFO_VERSION_MINOR(
				platform_type->v1.platform_version)) << 8) |
			  (platform_type->v1.hw_platform_subtype));
	return 0;
#else
	struct smem_machid_info *machid_info;
	machid_info = smem_get_item(SMEM_MACHID_INFO_LOCATION);
	if (IS_ERR_OR_NULL(machid_info)) {
		debug("Failed to get SMEM item: SMEM_MACHID_INFO_LOCATION\n");
		return -ENODEV;
	}

	g_board_machid = machid_info->machid;
#endif

	return 0;
}

void setup_board_default_env(void)
{
	ulong soc_hw_version;

	/*
	 * setup machid
	 */
	env_set_hex("machid", gd->bd->bi_arch_number);

	/*
	 * set soc hw version in env
	 */
	soc_hw_version = get_soc_hw_version();
	if (soc_hw_version)
		env_set_hex("soc_hw_version", soc_hw_version);

	env_set_ulong("soc_version_major", ipq_socinfo.soc_version_major);
	env_set_ulong("soc_version_minor", ipq_socinfo.soc_version_minor);
}

int board_late_init(void)
{
#ifdef CONFIG_QTI_NSS_SWITCH
	/*
	 * configure CMN clock for ethernet
	 */
	ipq_config_cmn_clock();
#endif

	/*
	 * setup default env
	 */
	setup_board_default_env();
	tlt_board_late_init();

	return 0;
}

int dram_init(void)
{
	int i, ret = CMD_RET_SUCCESS;
	int count = 0;
	struct smem_ram_ptable *ram_ptable;
	struct smem_ram_ptn *p;

	ram_ptable = smem_get_item(SMEM_USABLE_RAM_PARTITION_TABLE);
	if (IS_ERR_OR_NULL(ram_ptable)) {
		debug("Failed to get SMEM item: " \
				"SMEM_USABLE_RAM_PARTITION_TABLE\n");
		ret = -ENODEV;
	}

	gd->ram_size = 0;
	/* Check validy of RAM */
	for (i = 0; i < CONFIG_RAM_NUM_PART_ENTRIES; i++) {
		p = &ram_ptable->parts[i];
		if (p->category == RAM_PARTITION_SDRAM &&
					p->type == RAM_PARTITION_SYS_MEMORY) {
			gd->ram_size += p->size;
			debug("Detected memory bank %u: "
				"start: 0x%llx size: 0x%llx\n",
					count, p->start, p->size);
			count++;
		}
        }

	if (!count) {
		printf("Failed to detect any memory bank\n");
		ret = CMD_RET_FAILURE;
	}

	return ret;
}

phys_size_t get_effective_memsize(void)
{
	phys_size_t ram_size = min(gd->ram_size, board_dram_bank_info[0].size);

#ifndef CONFIG_ARM64
	if (((uint64_t)gd->ram_base + ram_size) > ULONG_MAX)
		ram_size = ULONG_MAX - gd->ram_base;
#endif
	return ram_size;
}

int dram_init_banksize(void)
{
	uint8_t i = 0;
	gd->bd->bi_dram[i].start = board_dram_bank_info[i].start;
	gd->bd->bi_dram[i].size = get_effective_memsize();

#if (CONFIG_NR_DRAM_BANKS > 1)
	phys_size_t total_dram_sz = gd->ram_size - gd->bd->bi_dram[i].size;

	for (i = 1; i < CONFIG_NR_DRAM_BANKS; i++) {
		if (!total_dram_sz)
			break;
		gd->bd->bi_dram[i].start = board_dram_bank_info[i].start;
		gd->bd->bi_dram[i].size = min(total_dram_sz,
				board_dram_bank_info[i].size);
		total_dram_sz -= gd->bd->bi_dram[i].size;
	}
#endif

	return 0;
}

void *env_sf_get_env_addr(void)
{
        return NULL;
}

void board_lmb_reserve(struct lmb *lmb)
{
	if (lmb)
		lmb->reserved.region[0].size = (CONFIG_TEXT_BASE -
				lmb->reserved.region[0].base);
}

void enable_caches(void)
{
#ifdef CONFIG_ARM64
	int i;
	uint8_t bidx = 0;

	/* Now Update the real DDR size based on Board configuration */
	for (i = 0; mem_map[i].size || mem_map[i].attrs; i++) {
		if (mem_map[i].size == 0x0UL) {
			if (!bidx)	/* For DDR bank 0 */
				mem_map[i].size =
					gd->ram_top - mem_map[i].virt;
			else		/* For remaining DDR banks */
				mem_map[i].size =
					gd->bd->bi_dram[bidx].size;
			bidx++;
		}
	}
#endif
	board_cache_init();
}

int ft_system_setup(void *blob, struct bd_info *bd)
{
	const u32 *media_handle_p;
	int chosen, len, ret;
	const char *media;
	char fdt_propname[64] = { 0 };
	u32 media_handle;

	media = env_get("rutos_part");
	snprintf(fdt_propname, sizeof(fdt_propname), "rootdisk-%s", media);

	chosen = fdt_path_offset(blob, "/chosen");
	if (chosen <= 0)
		return 0;

	media_handle_p = fdt_getprop(blob, chosen, fdt_propname, &len);
	if (media_handle_p <= 0 || len != 4)
		return 0;

	media_handle = *media_handle_p;
	ret = fdt_setprop(blob, chosen, "rootdisk", &media_handle, sizeof(media_handle));
	if (ret) {
		printf("cannot set media phandle %s as rootdisk /chosen node\n", fdt_propname);
		return ret;
	}

	printf("set /chosen/rootdisk to bootrom media: %s (phandle 0x%08x)\n", fdt_propname, fdt32_to_cpu(media_handle));

	return 0;
}
