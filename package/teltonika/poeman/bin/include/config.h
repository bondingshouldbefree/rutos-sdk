#ifndef _CONFIG_H
#define _CONFIG_H

#define MAX_BUDGETS 4
#define MAX_GPIOS   6

#include <gpiod.h>

typedef struct {
	int gpio;
	int val;
} t_budget_gpio;

typedef struct {
	t_budget_gpio gpios[MAX_GPIOS];
	int gpios_cnt;
	int (*vin_cmp)(double, double);
	int vin;
	int budget;
	int max_port_power;
	int deficit;
} t_budget;

typedef struct config_s t_config;
struct config_s {
	char bus[256];
	t_budget budgets[MAX_BUDGETS];
	t_budget *sel_budget;
	int budgets_cnt;
	struct gpiod_line *pse_en;
	double (*read_adc)(t_config *config);
	union {
		char path[256];
		int modem_port;
	} adc;
	double vin;
	double adc_divider;
	struct gpiod_line *gpios[MAX_GPIOS];
};

int config_init(t_config *config);
void config_deinit(t_config *config);

const char *get_poe_config(char *param1, char *param2);

#endif
