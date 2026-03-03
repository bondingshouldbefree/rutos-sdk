
#ifndef _LCFG_INTERNAL_H_
#define _LCFG_INTERNAL_H_

#define __private __attribute__((visibility("hidden")))

__private lcfg_stat lcfg_str_list_to_cfg(struct lcfg_context *ctx, void *ptr, const char *str,
					 const struct lcfg_opt *option);

__private lcfg_stat lcfg_str_list_to_cfg_cust(void *ptr, const char *str, const struct lcfg_opt *option);

__private lcfg_stat llcfg_options_check(struct lcfg_context *ctx, const struct lcfg_opt *options,
					uint64_t res, void *dst);

__private void lcfg_set_default(const struct lcfg_opt *option, void *dst);

__private lcfg_stat lcfg_parse_option(struct lcfg_context *ctx, const struct lcfg_opt *option,
				      const char *str, void *ptr);

static inline void lcfg_ctx_set_err(struct lcfg_context *ctx, lcfg_stat err, const struct lcfg_opt *option)
{
	ctx->err    = err;
	ctx->option = option;
}

#endif //_LCFG_INTERNAL_H_
