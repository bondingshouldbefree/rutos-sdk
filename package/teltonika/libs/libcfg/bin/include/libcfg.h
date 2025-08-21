
#ifndef _LCFG_H
#define _LCFG_H

#include <stdint.h>
#include <stdio.h>

#define LCFG_SAVE_FAIL 0XFFFFFFFFFFFFFFFF
#define LCFG_LIST_HEADER_SIZE sizeof(size_t)

typedef enum {
	LCFG_SUCCESS,
	LCFG_ERROR,
	LCFG_PARSE_ERROR,
	LCFG_REQUIRED,
	LCGF_VALIDATION_FAIL,
	LCFG_DEPEND_FAIL,
	LCFG_EXCLUDE_FAIL,
} lcfg_stat;

enum opt_type {
	LCFG_OTYPE_NONE,
	LCFG_OTYPE_STRING,
	LCFG_OTYPE_UINT8,
	LCFG_OTYPE_UINT16,
	LCFG_OTYPE_UINT32,
	LCFG_OTYPE_UINT64,
	LCFG_OTYPE_DOUBLE,
	LCFG_OTYPE_BOOL,
	LCFG_OTYPE_SECTION,
};

enum opt_flags {
	OFLAG_NONE	  = 0,
	OFLAG_REQUIRED	  = 1 << 0, // option is required
	OFLAG_SCPY	  = 1 << 1, // copy data
	OFLAG_LIST	  = 1 << 2, // option is a list
	OFLAG_LIST_CUSTOM = 1 << 3, // do not allocate memory for the list and use the custom parse function
};

struct lcfg_opt;

struct lcfg_opt {
	/* option name */
	const char *name;
	/* option description */
	const char *desc;
	/* option id */
	uint16_t id;
	/* option flags */
	uint16_t flag;
	/* option type */
	enum opt_type type;
	/* pointer to the option list. Only if option flag OFLAG_SECTION is set */
	const struct lcfg_opt *options;
	/* bit mask of the dependecies */
	uint16_t depends;
	//TODO: implement dependencies
	// .dependency = { .id = IO_CFG_ACL, .u.str = "current" },
	/* bit mask of the exclusions */
	uint16_t excl;
	/* offset of the option in the structure */
	unsigned int ptroff;
	/* size of the option in the structure */
	size_t size;
	/* validation range */
	long long range[2];
	/* default value */
	union {
		const char *s;
		double d;
		uint8_t u8;
		uint16_t u16;
		uint32_t u32;
		uint64_t u64;
	} d;
	/* indicates if default value is set */
	uint8_t dset;
	/* custom function to validate the dependencies */
	lcfg_stat (*depends_cb)(const struct lcfg_opt *option, void *ptr, uint64_t res);
	/* custom function to parse option */
	lcfg_stat (*parse)(const struct lcfg_opt *option, void *ptr, const char *str);
	/* custom function to validate the option */
	lcfg_stat (*validate)(const struct lcfg_opt *option, const char *val);
};

struct lcfg_context {
	/* Return code */
	lcfg_stat err;
	/* The pointer to the option that encountered an error */
	const struct lcfg_opt *option;
};

void lcfg_list_free(void *ptr, const struct lcfg_opt *option);

/**
 * @brief Free the config structure
 * 
 * @param options Option list
 * @param dst Config structure
 */
void lcfg_free(const struct lcfg_opt *options, void *dst);

/**
 * @brief print default value for the option
 * 
 * @param option pointer to the option
 * @return char* default value 
 */
char *lcfg_get_default(const struct lcfg_opt *option);

/**
 * @brief Print the help for the option
 * 
 * @param option pointer to the option
 * @return char* help string
 */
char *lcfg_get_option_help(const struct lcfg_opt *option);

/**
 * @brief Print the help for the option list
 * 
 * @param option pointer to the option list
 */
void lcfg_print_help(const struct lcfg_opt *option);

/**
 * @brief Get the error string
 * 
 * @param num error number
 * @return const char* error string
 */
const char *lcfg_error(lcfg_stat num);

/**
 * @brief Get the error string
 * 
 * @param ctx lib config context
 * @param dst destination buffer
 * @param prefix prefix string
 */
void lcfg_error_str(struct lcfg_context *ctx, char **dst, const char *prefix);

void *lcfg_list_init(size_t size, size_t nmemb);

void *lcfg_append_list(void **list, size_t size);

void *lcfg_list_add(void *list, size_t size, const void *data);

void *lcfg_list_dup(void *list, const struct lcfg_opt *option);

void *lcfg_list_find(void *list, const struct lcfg_opt *option, void *value);

size_t lcfg_size(const struct lcfg_opt *options);

static inline void *lcfg_list_head(void *ptr)
{
	return (char *)ptr - LCFG_LIST_HEADER_SIZE;
}

/**
 * @brief convert option type to string
 * 
 * @param type option type
 * @return const char* string representation of the option type
 */
static inline const char *lcfg_type_to_str(enum opt_type type)
{
	static const char *types[] = {
		[LCFG_OTYPE_NONE] = "none",	  [LCFG_OTYPE_STRING] = "string",
		[LCFG_OTYPE_BOOL] = "bool",	  [LCFG_OTYPE_UINT8] = "uint8",
		[LCFG_OTYPE_UINT16] = "uint16",	  [LCFG_OTYPE_UINT32] = "uint32",
		[LCFG_OTYPE_UINT64] = "uint64",	  [LCFG_OTYPE_DOUBLE] = "double",
		[LCFG_OTYPE_SECTION] = "section",
	};

	if (type >= LCFG_OTYPE_NONE && type <= LCFG_OTYPE_SECTION) {
		return types[type];
	}

	return "unknown";
}

/* Iterate over the options */
#define LCFG_OPT_FOR_EACH(opt, options) for (opt = options; opt->name != NULL; opt++)

/* Get the offset of the structure element */
#define LCFG_OPT_POINTER(stype, member)                                                                      \
	.ptroff = offsetof(stype, member), .size = sizeof(((stype *)NULL)->member)

/* Get the pointer to the structure element by offset */
#define LCFG_OPT_MKPTR(dst, opt) ((void *)((char *)dst + (opt)->ptroff))

/* Last element of the table */
#define LCFG_TABLE_END                                                                                       \
	{                                                                                                    \
		.name = NULL                                                                                 \
	}

/* Get list lenght */
#define LCFG_OPT_LIST_LEN(p) *(size_t *)((char *)p - sizeof(size_t))

#define LCFG_LIST_FOR_EACH_EXT(pos, list, rem, n)                                                            \
	for (rem = LCFG_OPT_LIST_LEN(list), pos = list; rem > 0; rem--, pos += n)

#define LCFG_LIST_FOR_EACH(pos, list, rem) LCFG_LIST_FOR_EACH_EXT(pos, list, rem, 1)

/* Set default value */
#define LCFG_OPT_SET_DEFAULT(var, val) var = val, .dset = 1
/* Set default string value */
#define LCFG_OPT_DEFAULT_STR(val) LCFG_OPT_SET_DEFAULT(.d.s, val)
/* Set default uint8 value */
#define LCFG_OPT_DEFAULT_UINT8(val) LCFG_OPT_SET_DEFAULT(.d.u8, val)
/* Set default bool value */
#define LCFG_OPT_DEFAULT_BOOL(val) LCFG_OPT_DEFAULT_UINT8(val)
/* Set default uint16 value */
#define LCFG_OPT_DEFAULT_UINT16(val) LCFG_OPT_SET_DEFAULT(.d.u16, val)
/* Set default uint32 value */
#define LCFG_OPT_DEFAULT_UINT32(val) LCFG_OPT_SET_DEFAULT(.d.u32, val)
/* Set default uint64 value */
#define LCFG_OPT_DEFAULT_UINT64(val) LCFG_OPT_SET_DEFAULT(.d.u64, val)
/* Set default double value */
#define LCFG_OPT_DEFAULT_DOUBLE(val) LCFG_OPT_SET_DEFAULT(.d.d, val)

/**
 * @brief find string element in the list
 * 
 * @param list string list
 * @param value string to find
 * @return char* pointer to the string element or NULL
 */
static inline char *lcfg_list_find_str(char **list, const char *value)
{
	char **cur = NULL;
	int rem = 0;

	LCFG_LIST_FOR_EACH(cur, list, rem) {
		if (strcmp(*cur, value) == 0) {
			return *cur;
		}
	}

	return NULL;
}

#endif //_LCFG_H
