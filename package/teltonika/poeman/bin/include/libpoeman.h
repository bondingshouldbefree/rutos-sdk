#ifndef LIBPOEMAN_H
#define LIBPOEMAN_H

#include <libubus.h>

/*DEFINES*/
#define LPOEMAN_OK	      0
#define LPOEMAN_ERROR	      1
#define LPOEMAN_UNKNOWN_VALUE 2

/*FUNCTIONS*/

/**
  * Retrieves port voltage
  * @param[in] lan LAN port name
  * @param[out] voltage port voltage value in Volts
  * @returns on success returns 0 else error code
  */
int get_port_voltage(struct ubus_context *ctx, char *lan, double *voltage);

/**
  * Retrieves connected device current usage
  * @param[in] lan LAN port name
  * @param[out] current port current in mA
  * @returns on success returns 0 else error code
  */
int get_port_current(struct ubus_context *ctx, char *lan, int *current);

/**
  * Retrieves connected device class
  * @param[in] lan LAN port name
  * @param[out] class class as string
  * @returns on success returns 0 else error code
  */
int get_port_class(struct ubus_context *ctx, char *lan, const char **class);

/**
  * Retrieves pots power state
  * @param[in] lan LAN port name
  * @param[out] state power state (1-PORT POWER ON; 0- PORT POWER OFF)
  * @returns on success returns 0 else error code
  */
int get_port_power_state(struct ubus_context *ctx, char *lan, int *state);

/**
  * Retrieves pots power state
  * @param[in] lan LAN port name
  * @param[in] enable enable or disables port power
  * @returns on success returns 0 else error code
  */
int set_port_power_state(struct ubus_context *ctx, char *lan, bool enable);

#endif
