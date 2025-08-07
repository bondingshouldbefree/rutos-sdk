
#ifndef _LCFG_UBUS_H_
#define _LCFG_UBUS_H_

#include <libubus.h>

#include "libcfg.h"

/**
 * @brief parse the UCI section to the structure using UBUS API. Extended version
 * 
 * @param ubus UBUS context
 * @param ctx lcfg context
 * @param package UCI package name
 * @param section UCI section name
 * @param options options policy
 * @param dst destination for the parsed data
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR otherwise
 */
lcfg_stat lcfg_parse_section_ubus_ext(struct ubus_context *ubus, struct lcfg_context *ctx,
				      const char *package, const char *section,
				      const struct lcfg_opt *options, void *dst);

/**
 * @brief save the structure to the UCI config using UBUS API
 * 
 * @param ubus UBUS context
 * @param package UCI package name
 * @param section UCI section name
 * @param type UCI type name. The new section will be created if type is not NULL
 * 		and section is not created
 * @param options options list
 * @param data data to save
 * @param mask mask of the options to save
 * @return uint64_t mask of the options that failed to save or LCFG_SAVE_FAIL on error
 */
uint64_t lcfg_save_ubus(struct ubus_context *ubus, const char *package, const char *section, const char *type,
			const struct lcfg_opt *options, void *data, uint64_t mask);

/**
 * @brief add a new section to the UCI config using UBUS API
 * 
 * @param ubus UBUS context
 * @param package UCI package name
 * @param section UCI section name
 * @param type UCI section type
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR otherwise
 */
lcfg_stat lcfg_add_section_ubus(struct ubus_context *ubus, const char *package, const char *section,
				const char *type);

/**
 * @brief commit the UCI config using UBUS API
 * 
 * @param ubus UBUS context
 * @param package UCI package name
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR otherwise
 */
lcfg_stat lcfg_commit_ubus(struct ubus_context *ubus, const char *package);

/**
 * @brief calculate the hash of the options using UBUS API
 * 
 * @param ubus UBUS context
 * @param package UCI package name
 * @param section UCI section name
 * @param options UCI options list
 * @param dst destination for the hash
 * @param mask options mask
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR otherwise
 */
lcfg_stat lcfg_hash_options_ubus(struct ubus_context *ubus, const char *package, const char *section,
				 const struct lcfg_opt *options, uint32_t *dst, uint64_t mask);

/**
 * @brief parse the UCI section to the structure using UBUS API
 * 
 * @param ubus UBUS context
 * @param package UCI package name
 * @param section UCI section name
 * @param options options policy
 * @param dst destination for the parsed data
 * @return lcfg_stat LCFG_SUCCESS on success, LCFG_ERROR otherwise
 */
static inline lcfg_stat lcfg_parse_section_ubus(struct ubus_context *ubus, const char *package,
						const char *section, const struct lcfg_opt *options,
						void *dst)
{
	struct lcfg_context ctx = { 0 };

	return lcfg_parse_section_ubus_ext(ubus, &ctx, package, section, options, dst);
}

#endif //_LCFG_UBUS_H_
