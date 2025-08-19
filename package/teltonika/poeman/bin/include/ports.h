#ifndef __PORTS_H
#define __PORTS_H

#include <stdbool.h>

enum poe_dump_map {
	POE_DUMP_STATE = 1 << 0,
	POE_DUMP_CLASS = 1 << 1,
	POE_DUMP_CUR   = 1 << 2,
	POE_DUMP_VOL   = 1 << 3,
	POE_DUMP_TEMP  = 1 << 4,
	POE_DUMP_POW   = 1 << 5,
};

typedef struct {
	const char *state;
	const char *class;
	int current;
	int voltage;
	int temp;
	int power;
	enum poe_dump_map vals;
} t_poe_dump;

enum port_state {
	PORT_STATE_UNKNOWN,
	PORT_STATE_UP,
	PORT_STATE_DOWN,
	PORT_STATE_BUDGET,
};

typedef struct {
	char *port_name;
	bool enabled;
	int class_limit;
	int power_limit;
	int index;
	void *poe;
	enum port_state state;
	int fail;
} t_port;

int ports_init(int ports_number);
t_port *get_ports(void);
int get_ports_num(void);
t_port *get_port_by_id(const int id);
t_port *get_port_by_number(int numb);
t_port *get_port_by_name(const char *name);
t_port *get_next_port(t_port *port);
t_port *get_port_by_chip(int addr, int id);
void chip_dump_port(t_port *port, t_poe_dump *info);
void ports_deinit(void);

#endif
