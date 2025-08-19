#ifndef _POE_H
#define _POE_H

#include "chip.h"
#include "config.h"

typedef struct {
	int channel;
	char *name;
} t_chan;

typedef enum {
	CHIP_STATE_UNKNOWN,
	CHIP_STATE_OK,
	CHIP_STATE_NOT_FOUND,
	CHIP_STATE_LOST,
} t_chip_state;

typedef struct {
	int address;
	int chan_count;
	t_chan *channels;
	t_chip_state state;
} t_chip;

typedef struct {
	t_config config;
	int consumed;
	bool is_high_load;
	int poe_ports;
	t_chip *chipset;
	int chip_count;
	int load_hi_tr;
	int load_lo_tr;
} t_poe;

int poe_check();
int poe_init();
void poe_deinit();
t_poe *get_poe_info();

#endif
