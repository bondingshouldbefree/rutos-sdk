#ifndef LOGGER_H
#define LOGGER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdarg.h>
#include <syslog.h>

// Configuration constants
#define MAX_LOG_MSG 5
#define SPAM_WARNING                                                                                         \
	"(Will stop printing error messages due to log spam. "                                               \
	"That does not mean that the problem is no longer present!)"
#define SOCKET_PATH "/var/logd.sock"
#define BUF_SIZE    256

// Bitmask definitions for enabled log levels
#define B_EMERG	  (1u << 0)
#define B_ALERT	  (1u << 1)
#define B_CRIT	  (1u << 2)
#define B_ERROR	  (1u << 3)
#define B_WARNING (1u << 4)
#define B_NOTICE  (1u << 5)
#define B_INFO	  (1u << 6)
#define B_DEBUG	  (1u << 7)

// Log levels (priority ascending)
typedef enum {
	L_DEBUG,
	L_INFO,
	L_NOTICE,
	L_WARNING,
	L_ERROR,
	L_CRIT,
	L_ALERT,
	L_EMERG,
	L_SYSTEM /* special: dynamic level via socket */
} log_level_type;

// Log facilities (syslog local use for database logging)
typedef enum {
    LOG_EVENTS       = LOG_LOCAL0,
    LOG_SYSTEM       = LOG_LOCAL1,
    LOG_NETWORK      = LOG_LOCAL2,
    LOG_CONNECTIONS  = LOG_LOCAL3,
} log_facility_type;

// Log a message directly to the database
void log_db(const char *as_sender, log_facility_type facility,
	log_level_type level, const char *fmt, ...);

// Logger output targets (bitmask)
enum { L_TYPE_SYSLOG = (1 << 0), L_TYPE_STDOUT = (1 << 1), L_SYSLOG_LEVELS = (1 << 2) };

// Log message identifiers (used for log spam control)
typedef enum { LOG_ID_OK = 0, LOG_ID_ERR_1, LOG_ID_ERR_2, LOG_ID_ERR_3, LOG_ID_ERR_4, LOG_ID_ERR_5 } log_id;

// Counter for deduplicating repeated log messages
typedef struct log_count {
	/* Count how many times the message has been printed */
	int count;
	/* Unique message id that helps to determine if
	   a new error message has been encountered */
	log_id id;
} log_counter;

/**
 * Initialize the logger with minimum level and target outputs.
 * If logger_type = 0, defaults to SYSLOG.
 */
int logger_init(log_level_type min_level, int logger_type, const char *prog_name);

/**
 * Extended init — allows specifying process ID and syslog facility.
 */
int logger_init_ext(int min_level, int logger_type, const char *prog_name, int pid, int facility);

/**
 * Get the current minimum logging level.
 */
int log_get_level(void);

/**
 * Log a formatted message.
 */
void _log(log_level_type level, const char *fmt, ...) __attribute__((format(printf, 2, 3)));

/**
 * Logs defined log message using counter that counts
 * how many times it should be printed to reduce log spam
 * @param counter counter structure
 * @param id unique message id
 * @param level log message level
 * @param fmt string format
 */
void _log_with_count(log_counter *counter, log_id id, log_level_type level, char *fmt, ...)
	__attribute__((format(printf, 4, 5)));

/* --------------------------------------------------------------------
 * Convenience macros
 * -------------------------------------------------------------------- */
#define log(level, fmt, ...) _log(level, fmt "\n", ##__VA_ARGS__)

#define log_count(counter, id, level, fmt, ...) \
	_log_with_count(counter, id, level, fmt"\n", ##__VA_ARGS__)

#define DEBUG(fmt, ...) log(L_DEBUG, fmt, ##__VA_ARGS__)

#define INFO(fmt, ...) log(L_INFO, fmt, ##__VA_ARGS__)

#define NOTICE(fmt, ...) log(L_NOTICE, fmt, ##__VA_ARGS__)

#define WARN(fmt, ...) log(L_WARNING, fmt, ##__VA_ARGS__)

#define ERROR(fmt, ...) log(L_ERROR, fmt, ##__VA_ARGS__)

#define CRIT(fmt, ...) log(L_CRIT, fmt, ##__VA_ARGS__)

#define PANIC(fmt, ...)                                                                                      \
	do {                                                                                                 \
		log(L_CRIT, fmt, ##__VA_ARGS__);                                                             \
		exit(EXIT_FAILURE);                                                                          \
	} while (0)

#ifdef __cplusplus
}
#endif

#endif // LOGGER_H