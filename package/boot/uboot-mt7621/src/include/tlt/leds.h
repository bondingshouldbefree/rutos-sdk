
#ifndef __TLT_LEDS_H
#define __TLT_LEDS_H

#ifdef CONFIG_VENDOR_TLT
void tlt_leds_on(void);
void tlt_leds_off(void);
void tlt_leds_invert(void);
void tlt_leds_check_anim(void);
void tlt_leds_check_blink(void);
void tlt_btn_press_blink_set(int val);
int tlt_leds_check_btn_blink(void);
void tlt_leds_set_flashing_state(int state);
void tlt_leds_set_failsafe_state(int state);
int tlt_leds_get_flashing_state(void);
int tlt_leds_get_failsafe_state(void);
int tlt_get_rst_btn_status(void);
#ifdef CONFIG_DIN_SERIAL
int tlt_get_din_pin_status(void);
#endif // CONFIG_DIN_SERIAL
#else
static inline void tlt_leds_on(void) {};
static inline void tlt_leds_off(void) {};
static inline void tlt_leds_invert(void) {};
static inline void tlt_leds_check_anim(void) {};
static inline void tlt_leds_check_blink(void) {};
static inline void tlt_btn_press_blink_set(int val) {};
static inline int tlt_leds_check_btn_blink(void) { return 0; };
static inline void tlt_leds_set_flashing_state(int state) {};
static inline void tlt_leds_set_failsafe_state(int state) {};
static inline int tlt_leds_get_flashing_state(void) { return 0; };
static inline int tlt_leds_get_failsafe_state(void) { return 0; };
static inline int tlt_get_rst_btn_status(void) { return 1; };
#ifdef CONFIG_DIN_SERIAL
static inline int tlt_get_din_pin_status(void) { return 0; };
#endif // CONFIG_DIN_SERIAL
#endif

#endif /* __TLT_LEDS_H */
