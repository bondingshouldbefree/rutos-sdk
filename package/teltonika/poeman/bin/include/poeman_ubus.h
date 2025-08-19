#ifndef _POEMAN_UBUS_H
#define _POEMAN_UBUS_H

void ubus_broadcast_event();
int ubus_broadcast_power_event(int usage, bool high_load);
int ubus_init();
void ubus_run();

#endif
