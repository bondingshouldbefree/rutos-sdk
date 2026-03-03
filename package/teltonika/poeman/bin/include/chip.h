#ifndef _CHIP_H
#define _CHIP_H

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <config.h>
#include <poe_utils.h>

int chip_probe(t_config *config);
int chip_init(void);
void chip_deinit(void);
int chip_port_enable(const char *lan, bool enable);
int chip_get_port_power(const char *lan, int *on);
int chip_get_port_current_ma(const char *lan, int *current);
int chip_get_port_voltage_mv(const char *lan, int *voltage);
int chip_get_port_t(const char *lan, int *temperature);
int chip_get_port_pd_class(const char *lan, const char **class);
void chip_dump_regs(void);

#endif
