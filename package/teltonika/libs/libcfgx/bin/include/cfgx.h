#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <libubox/blob.h>
#include <uci.h>

#include <stddef.h>
#include <stdbool.h>

/// Abstraction over underlying storage layer when reading configurations.
/// Useful for using the same code when parsing sections from UCI and UBus
typedef struct cfgx_context cfgx_context_t;

/// A configuration section which has loaded from a configuration context
struct cfgx_section {
	/// Parent section pointer, useful for when you want to iterate over
	/// all child sections of a certain section.
	/// \note Can be NULL
	struct cfgx_section *parent;

	/// Unique identifier of this section. Useful for finding a section when
	/// another one references it by ID.
	/// \note Can be NULL
	char *id;

	/// Type of section. Useful for iterating all section of the same type.
	/// \note Can be NULL
	char *type;
};

/// A list of strings
struct cfgx_string_list {
	/// Base array pointer
	char **strings;

	/// Length of array
	size_t len;
};

/// A list of configurations
struct cfgx_section_list {
	/// Base array pointer
	struct cfgx_section **sections;

	/// Length of array
	size_t len;
};

/// @brief Allocate new empty configuration context. Use `cfgx_context_append_section_blobmsg` to append sections.
/// @return Configuration context
 cfgx_context_t *cfgx_context_init_blobmsg(void);

/// @brief Allocate new configuration context from uci context.
/// @param config Configuration name
/// @return Configuration context
cfgx_context_t *cfgx_context_init_uci(const char *config);

/// @brief Allocate new configuration context with given uci context.
/// @note The user is responsible for keeping the `uci` and `pkg` valid as long as this context is in use.
///       UCI context will not be freed when freeing configuration context.
///       You MUST not call `uci_free_context` before `cfgx_context_free`.
/// @param uci UCI context
/// @param pkg UCI package
/// @return Configuration context
cfgx_context_t *cfgx_context_init_uci_ctx(struct uci_context *uci, struct uci_package *pkg);

/// @brief Free configuration context
/// @param ctx Configuration context
/// @return NULL
cfgx_context_t *cfgx_context_free(cfgx_context_t *ctx);

/// @brief Append a configuration section to the configuration context
/// @param ctx Configuration context
/// @param blobmsg Section that will be added
/// @return Newly added section as a `cfgx_section` struct
/// @retval not NULL, if section was added
/// @retval     NULL, if section was not added (OOM)
struct cfgx_section *cfgx_context_append_section_blobmsg(cfgx_context_t *ctx, struct blob_attr *blobmsg);

/// @brief Find a section by an id in the context
/// @param ctx Configuration context
/// @param id Section id
/// @retval not NULL, if section was found
/// @retval     NULL, if section was not found
struct cfgx_section *cfgx_context_find_by_id(cfgx_context_t *ctx, const char *id);

/// @brief Count number of sections in context by type.
/// @note Intended for allocating a buffer in advance.
/// @param ctx Configuration context
/// @param type Section type
/// @return Number of section with given type in context
size_t cfgx_context_count_by_type(cfgx_context_t *ctx, const char *type);

/// @brief Count number of sections in context by parent.
/// @note Intended for allocating a buffer in advance.
/// @param ctx Configuration context
/// @param parent Parent section pointer
/// @return Number of section with given parent in context
size_t cfgx_context_count_by_parent(cfgx_context_t *ctx, struct cfgx_section *parent);

/// @brief List all available sections in context
/// @param ctx Configuration context
/// @return List of sections
struct cfgx_section_list cfgx_context_list_sections(cfgx_context_t *ctx);

/// @brief Free configuration list
/// @param list List of sections
/// @return Zeroed struct
struct cfgx_section_list cfgx_section_list_free(struct cfgx_section_list list);

/// @brief Get value of option by name from section.
/// @warning Type of option must be an array of strings
/// @param ctx Configuration context
/// @param section Section
/// @param name Option name
/// @param[out] result_list On success, result will be stored here
/// @retval  0, success
/// @retval -1, failure
int cfgx_section_get_string_list(cfgx_context_t *ctx, struct cfgx_section *section, const char *name, struct cfgx_string_list *result_list);

/// @brief Free allocated memory by list of strings
/// @param list List of strings
/// @return Zeroed struct
struct cfgx_string_list cfgx_string_list_free(struct cfgx_string_list list);

/// @brief Get value of option by name from section.
/// @warning Type of option must be a string
/// @warning Return value MUST be freed.
/// @param ctx Configuration context
/// @param section Section
/// @param name Option name
/// @retval not NULL, string which was malloc'ed
/// @retval     NULL, option of string type was not found
char *cfgx_section_get_string(cfgx_context_t *ctx, struct cfgx_section *section, const char *name);

/// @brief Get value of option by name from section and check if it is within a certain range.
/// @param ctx Configuration context
/// @param section Section
/// @param name Option name
/// @param def Default value
/// @param min Minimum value (inclusive)
/// @param max Maximum value (inclusive)
/// @return Parsed valued or default if an error occured
int64_t cfgx_section_get_i64(cfgx_context_t *ctx, struct cfgx_section *section, const char *name, int64_t min, int64_t max, int64_t def);

#ifdef __cplusplus
}
#endif

