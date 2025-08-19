/* SPDX-License-Identifier: GPL-2.0-only */
#include <linux/slab.h>

#include "fsb.h"
#include "fsb_flash.h"

#define FSB_CONFIG_ARRAY_SIZE_MAX 4096

/*
 * Finds the last valid bootconfig present in `bcs`
 * 
 * Returns the index within `bcs`(as fsb_config[])
 * Returns -1 if none are found
 */
static int fsb_array_find_valid(fsb_config bcs[], size_t num_bcs,
				fsb_config *bc_out)
{
	int i;

	for (i = num_bcs - 1; i >= 0; i--) {
		fsb_config *bc = &bcs[i];

		if (bc->magic != FSB_CONFIG_MAGIC)
			continue;

		if (bc->crc32 != fsb_config_crc_calc(bc))
			continue;

		if (bc_out) {
			*bc_out = *bc;
		}
		return i;
	}

	return -1;
}

/*
 * Finds the first "free" index starting from `min_idx`
 * 
 * Returns the index within `bcs`(as fsb_config[])
 * Returns -1 if none are found
 */
static int fsb_array_find_free(fsb_config bcs[], size_t num_bcs, int min_idx)
{
	char cmpbuf[sizeof(fsb_config)];
	int i;

	memset(&cmpbuf, 0xff, sizeof(cmpbuf));

	for (i = min_idx; i < num_bcs; i++) {
		fsb_config *bc = &bcs[i];

		if (memcmp(bc, &cmpbuf, sizeof(fsb_config)) == 0) {
			return i;
		}
	}

	return -1;
}

static int fsb_partition_read(fsb_partition partition, fsb_config *bc_out)
{
	fsb_config *bcs;
	size_t num_bcs;
	int ret = 0;
	int bc_idx;

	bcs = (fsb_config *)kzalloc(
		sizeof(fsb_config) * FSB_CONFIG_ARRAY_SIZE_MAX, GFP_KERNEL);
	if (!bcs) {
		fsb_err("Failed to allocate array buffer\n");
		return 1;
	}

	ret = fsb_flash_read(partition, bcs, FSB_CONFIG_ARRAY_SIZE_MAX,
			     &num_bcs);
	if (ret) {
		fsb_err("fsb_flash_read() returned %d\n", ret);
		goto cleanup;
	}

	fsb_dbg("Retuned config array size: %zu\n", num_bcs);

	bc_idx = fsb_array_find_valid(bcs, num_bcs, bc_out);

	if (bc_idx < 0) {
		fsb_warn("No valid bootconfig found in %s partition\n",
			 fsb_partition_str(partition));
		ret = 1;
		goto cleanup;
	}

	fsb_info("Valid bootconfig found in %s partition, index %d\n",
		 fsb_partition_str(partition), bc_idx);

cleanup:
	kfree(bcs);
	return ret;
}

static int fsb_partition_write(fsb_partition partition, fsb_config *bc)
{
	fsb_config *bcs;
	size_t num_bcs;
	int new_idx;
	int ret;

	bcs = (fsb_config *)kzalloc(
		sizeof(fsb_config) * FSB_CONFIG_ARRAY_SIZE_MAX, GFP_KERNEL);
	if (!bcs) {
		fsb_err("Failed to allocate array buffer\n");
		return 1;
	}

	ret = fsb_flash_read(partition, bcs, FSB_CONFIG_ARRAY_SIZE_MAX,
			     &num_bcs);
	if (ret) {
		fsb_err("fsb_flash_read() returned %d\n", ret);
		goto cleanup;
	}

	fsb_dbg("Retuned config array size: %zu\n", num_bcs);

	new_idx = fsb_array_find_valid(bcs, num_bcs, NULL);
	new_idx = fsb_array_find_free(bcs, num_bcs, new_idx + 1);

	if (new_idx >= 0) { // Free spot found in flash
		fsb_dbg("Appending new config to %s partition at index %d\n",
			fsb_partition_str(partition), new_idx);

		ret = fsb_flash_write(partition, new_idx, bc);
		if (ret) {
			fsb_err("fsb_flash_write() returned %d\n", ret);
			goto cleanup;
		}
	} else { // No free space in flash
		fsb_dbg("No free space left in %s partition\n",
			fsb_partition_str(partition));

		ret = fsb_flash_erase(partition);
		if (ret) {
			fsb_err("fsb_flash_erase() returned %d\n", ret);
			goto cleanup;
		}

		ret = fsb_flash_write(partition, 0, bc);
		if (ret) {
			fsb_err("fsb_flash_write() returned %d\n", ret);
			goto cleanup;
		}
	}

cleanup:
	kfree(bcs);
	return ret;
}

static void fsb_config_load(fsb_config *bc_out)
{
	int ret;

	ret = fsb_partition_read(FSB_PARTITION_PRIMARY, bc_out);
	if (!ret)
		return;

	ret = fsb_partition_read(FSB_PARTITION_SECONDARY, bc_out);
	if (!ret)
		return;

	fsb_warn("using default bootconfig value...\n");
	fsb_config_default(bc_out);
}

static int fsb_config_save(fsb_config *bc)
{
	int ret;

	ret = fsb_partition_write(FSB_PARTITION_SECONDARY, bc);
	if (ret) {
		fsb_err("failed to save bootconfig to secondary partition (ret = %d)\n",
			ret);
		return ret;
	}

	ret = fsb_partition_write(FSB_PARTITION_PRIMARY, bc);
	if (ret) {
		fsb_err("failed to save bootconfig to primary partition (ret = %d)\n",
			ret);
		return ret;
	}

	return 0;
}

void fsb_context_load(fsb_context *ctx)
{
	fsb_config_load(&ctx->config_active);

	fsb_context_revert(ctx);
}

static void fsb_context_update(fsb_context *ctx)
{
	ctx->config_active = ctx->config_new;
}

int fsb_context_save(fsb_context *ctx)
{
	int ret;

	fsb_info("saving new failsafe boot config...\n");

	ctx->config_new.magic = FSB_CONFIG_MAGIC;
	fsb_config_crc_update(&(ctx->config_new));

	// Check if any changes occurred
	if (memcmp(&(ctx->config_new), &(ctx->config_active),
		   sizeof(fsb_config)) == 0) {
		fsb_dbg("No changes to bootconfig, skipping...\n");
		return 0;
	}

	ret = fsb_config_save(&ctx->config_new);
	if (ret) {
		fsb_err("fsb_config_save() returned %d\n", ret);
	}

	fsb_context_update(ctx);

	return ret;
}

int fsb_slotinfo_compare(fsb_slotinfo *a, fsb_slotinfo *b)
{
	// Higher force is better
	if (a->force != b->force)
		return b->force - a->force;

	// Higher priority is better
	if (a->priority != b->priority)
		return b->priority - a->priority;

	// Higher successful_boot value is better, in case of same priority
	if (a->successful_boot != b->successful_boot)
		return b->successful_boot - a->successful_boot;

	// Higher tries_remaining is better to ensure round-robin
	if (a->tries_remaining != b->tries_remaining)
		return b->tries_remaining - a->tries_remaining;

	return 0;
}

static int fsb_config_get_best_bootable_slot(fsb_config *bc)
{
	int chosen = -1;
	int i;

	for (i = 0; i < FSB_CONFIG_NUM_SLOTS; i++) {
		fsb_slotinfo *slot = &bc->slots[i];

		if (slot->priority == 0)
			continue;

		if (slot->tries_remaining == 0)
			continue;

		if (chosen < 0 ||
		    fsb_slotinfo_compare(slot, &bc->slots[chosen]) < 0) {
			chosen = i;
		}
	}

	return chosen;
}

int fsb_config_pick_slot(fsb_config *bc)
{
	int slot = fsb_config_get_best_bootable_slot(bc);

	if (slot < 0) { // No bootable slot was found.
		// If we get to this point, we're probably screwed.
		// So let's just pick last chosen slot

		fsb_warn("No bootable RutOS slot was found, attempting last slot...\n");
		slot = bc->chosen;
	}

	return slot;
}

void fsb_config_mark_slot(fsb_config *bc, int slot_idx)
{
	fsb_slotinfo *slot = &bc->slots[slot_idx];

	bc->chosen = slot_idx;
	slot->force = 0;

	if (slot->tries_remaining != 0 && slot->tries_remaining != 15) {
		slot->tries_remaining--;
	}
}
