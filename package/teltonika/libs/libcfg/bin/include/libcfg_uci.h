
#ifndef _LCFG_UCI_H_
#define _LCFG_UCI_H_

#include <uci.h>

#include "libcfg.h"

/**
 * @brief Parse the config section extended version
 * 
 * @param s lib config context
 * @param s UCI section
 * @param options option list
 * @param dst destination structure
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR or other on error
 */
lcfg_stat lcfg_parse_section_uci_ext(struct lcfg_context *ctx, struct uci_section *s,
				     const struct lcfg_opt *options, void *dst);

/**
 * @brief save structure to the UCI section
 * 
 * @param uci UCI context
 * @param s pointer to the UCI section
 * @param options config policy
 * @param data data to save
 * @param mask mask of the options to save
 * @return uint64_t 0 on success, mask of the options that failed to save
 */
uint64_t lcfg_save_uci(struct uci_context *uci, const struct uci_section *s,
		const struct lcfg_opt *options, void *data, uint64_t mask);

/**
 * @brief build a hash over an options
 * 
 * @param s pointer to the UCI section
 * @param options config policy
 * @param mask mask of the options to hash
 * @return uint32_t calculated hash or 0 on error
 */
uint32_t lcfg_hash_options_uci(struct uci_section *s, const struct lcfg_opt *options, uint64_t mask);

static inline lcfg_stat lcfg_parse_section_uci(struct uci_section *s, const struct lcfg_opt *options,
					       void *dst)
{
	struct lcfg_context ctx = { 0 };

	return lcfg_parse_section_uci_ext(&ctx, s, options, dst);
}

#endif //_LCFG_UCI_H_
