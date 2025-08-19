#ifndef __TLT_FSB_H__
#define __TLT_FSB_H__

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <stddef.h>
#include <linux/crc32.h>

// #define DEBUG

#ifndef __STR
#define __STR(x) #x
#endif
#ifndef STR
#define STR(x) __STR(x)
#endif

#define LINESTR STR(__LINE__)

#ifdef DEBUG
	#define fsb_info(...) fprintf(stdout, "INFO\t"  __FILE__ ":" LINESTR ":\t" __VA_ARGS__ )
	#define fsb_warn(...) fprintf(stderr, "WARN\t"  __FILE__ ":" LINESTR ":\t" __VA_ARGS__ )
	#define fsb_err(...)  fprintf(stderr, "ERROR\t" __FILE__ ":" LINESTR ":\t" __VA_ARGS__ )
	#define fsb_dbg(...)  fprintf(stdout, "DEBUG\t" __FILE__ ":" LINESTR ":\t" __VA_ARGS__ )
#else
	#define fsb_info(...) fprintf(stdout, __VA_ARGS__ )
	#define fsb_warn(...) fprintf(stderr, "WARN: " __VA_ARGS__ )
	#define fsb_err(...)  fprintf(stderr, "ERROR: " __VA_ARGS__ )
	#define fsb_dbg(...)  do {} while(0)
#endif

#define FSB_CONFIG_NUM_SLOTS 3

#define FSB_CONFIG_MAGIC   0xBABAB0E1
#define FSB_CONFIG_VERSION 0x01

typedef struct fsb_slotinfo_s {
	// Slot priority with 15 meaning highest priority, 1 lowest
	// priority and 0 the slot is unbootable.
	// Other than that, certain priority values have extra meanings:
	// 1 - recovery ramdisk
	// 2 - default nand slot, indicates bootconfig was reset
	// 8 - nand secondary partition
	// 9 - nand primary partition
	uint8_t priority : 4;
	// Number of times left attempting to boot this slot.
	// If this is 0, the slot is considered as failed to boot
	// If this is 15, this counter is not decremented and
	// the boot fallback feature is considered disabled
	uint8_t tries_remaining : 4;
	// If the firmware in this slot has booted successfully at least once,
	// this is set to 1, otherwise this value is left as 0
	uint8_t successful_boot : 1;
	// Indicates this slot should be booted first
	// This will be set back to 0 on boot
	uint8_t force : 1;
	// Reserved for future use
	uint8_t reserved : 6;
} __attribute__((packed)) fsb_slotinfo;

#define FSB_SLOT_NAND_A     0
#define FSB_SLOT_NAND_B	    1
#define FSB_SLOT_RECOVERY   2

/* Bootconfig metadata
 * 
 * This struct is stored directly in NOR-flash and is used by 
 * the bootloader to select apropriate slots for booting
 */
typedef struct fsb_config_s {
	// Magic number, should be FSB_CONFIG_MAGIC
	uint32_t magic;
	// Bootconfig metadata version, should be FSB_CONFIG_VERSION
	uint8_t version;
	// Index of the slot that has been chosen for the last boot
	uint8_t chosen;
	// Slot metadata
	// 0 - Nand slot 0
	// 1 - Nand slot 1
	// 2 - Recovery ramdisk
	fsb_slotinfo slots[FSB_CONFIG_NUM_SLOTS];
	// CRC checksum of all bytes preceding this
	uint32_t crc32;
} __attribute__((packed)) fsb_config;

_Static_assert(sizeof(fsb_slotinfo) == 2, "fsb_slotinfo has wrong size");
_Static_assert(sizeof(fsb_config) == 16, "fsb_config has wrong size");

static inline const char *fsb_slot_str(int idx)
{
	switch (idx) {
	case 0:
		return "rutos-a";
	case 1:
		return "rutos-b";
	case 2:
		return "recovery";
	default:
		return "<invalid>";
	}
}

/*
 * Generates new default bootconfig
 */
static inline void fsb_config_default(fsb_config *bc)
{
	*bc = (fsb_config) {
		.version = 0x01,
		.chosen = 0,
		.slots = {
			{ // rutos-a
				.priority = 2,
				.tries_remaining = 5,
				.successful_boot = 0,
				.force = 0
			},
			{ // rutos-b
				.priority = 2,
				.tries_remaining = 5,
				.successful_boot = 0,
				.force = 0
			},
			{ // recovery
				.priority = 0,
				.tries_remaining = 15,
				.successful_boot = 0,
				.force = 0
			},
		}
	};
}

static inline void fsb_config_dbg(fsb_config *bc)
{
	fsb_dbg("==================================\n");
	fsb_dbg("magic: 0x%08x\n", bc->magic);
	fsb_dbg("version: 0x%02x\n", bc->version);
	fsb_dbg("chosen: %d (%s)\n", bc->chosen, fsb_slot_str(bc->chosen));
	fsb_dbg("slots:\n");

	for (int i = 0; i < FSB_CONFIG_NUM_SLOTS; i++) {
		fsb_dbg("\t%s:\n", fsb_slot_str(i));
		fsb_dbg("\t\tpriority: %d\n", bc->slots[i].priority);
		fsb_dbg("\t\ttries_remaining: %d\n", bc->slots[i].tries_remaining);
		fsb_dbg("\t\tsuccessful_boot: %d\n", bc->slots[i].successful_boot);
		fsb_dbg("\t\tforce: %d\n", bc->slots[i].force);
	}

	fsb_dbg("crc32: 0x%08x\n", bc->crc32);
	fsb_dbg("==================================\n");
}

/*
 * Returns crc32 checksum of all bootconfig fiels preceding the crc field
 */
static inline uint32_t fsb_config_crc_calc(fsb_config *bc)
{
	return crc32(FSB_CONFIG_MAGIC, bc, offsetof(fsb_config, crc32));
}

/*
 * Recalculates and updates bootconfig's crc field
 */
static inline void fsb_config_crc_update(fsb_config *bc)
{
	bc->crc32 = fsb_config_crc_calc(bc);
}

/* FailSafeBoot context
 * 
 * Stores any data useful between flash reads/writes
 */
typedef struct fsb_context_s {
	// bootconfig to be written to flash
	fsb_config config_new;
	// bootconfig currently active in flash
	fsb_config config_active;
} fsb_context;

/*
 * Reads and scans bootconfig partitions for newest valid bootconfig
 * May backup and restore bootconfigs if they are corrupted, and return defaulted bootconfig
 */
void fsb_context_load(fsb_context *ctx);

/*
 * Writes new bootconfig value into flash
 * May backup and erase bootconfigs if necessary
 */
int fsb_context_save(fsb_context *ctx);

/*
 * Copies active bootconfig into the new one, thereby reverting any unwritten changes
 */
static inline void fsb_context_revert(fsb_context *ctx)
{
	ctx->config_new = ctx->config_active;
}

/*
 * Compare two slots.
 * Returns negative number if the slot "a" is better, positive of the slot "b" is
 * better or 0 if they are equally good.
 */
int fsb_slotinfo_compare(fsb_slotinfo *a, fsb_slotinfo *b);

/*
 * Returns the index of the most suitable slot for booting
 * Returns -1 if no slot suitable for booting is found
 */
int fsb_config_pick_slot(fsb_config *bc);

/*
 * Updates slot metadata to indicate a boot attempt
 */
void fsb_config_mark_slot(fsb_config *bc, int slot_idx);

#endif