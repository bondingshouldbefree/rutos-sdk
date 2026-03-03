#include "tlt_logger.h"

#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>

static int initialized = 0;
static volatile int socket_connected = 0;
static int pid=0;
static int facility=LOG_DAEMON;
static volatile log_level_type min_level;
static unsigned int enabled_levels_mask = 0xFFFFFFFF;
static int use_syslog;
static int syslog_levels;
static int use_stdout;
static pthread_mutex_t syslog_mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t stdout_mtx = PTHREAD_MUTEX_INITIALIZER;
static const char *PROGNAME;

static const char *level_strings[] = {
	[L_DEBUG] = "Debug", [L_INFO] = "Info", [L_NOTICE] = "Notice", [L_WARNING] = "Warning",
	[L_ERROR] = "Error", [L_CRIT] = "Crit", [L_ALERT] = "Alert",   [L_EMERG] = "Emergency"
};

static const int level_to_slevel[] = {
	[L_DEBUG] = LOG_DEBUG, [L_INFO] = LOG_INFO, [L_NOTICE] = LOG_NOTICE, [L_WARNING] = LOG_WARNING,
	[L_ERROR] = LOG_ERR,   [L_CRIT] = LOG_CRIT, [L_ALERT] = LOG_ALERT,   [L_EMERG] = LOG_EMERG
};

static inline unsigned int log_level_to_bit(log_level_type lvl)
{
	switch (lvl) {
	case L_EMERG:
		return B_EMERG;
	case L_ALERT:
		return B_ALERT;
	case L_CRIT:
		return B_CRIT;
	case L_ERROR:
		return B_ERROR;
	case L_WARNING:
		return B_WARNING;
	case L_NOTICE:
		return B_NOTICE;
	case L_INFO:
		return B_INFO;
	case L_DEBUG:
		return B_DEBUG;
	default:
		return 0;
	}
}

static int request_level(int fd)
{
	if (fd < 0) {
		return -1;
	}
	struct sockaddr_un addr = { 0 };
	addr.sun_family		= AF_UNIX;
	strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

	char query[128];
	snprintf(query, sizeof(query), "%s.log_level?\n", PROGNAME);
	write(fd, query, strlen(query));
	char buf[128];
	int n = read(fd, buf, sizeof(buf) - 1);
	if (n > 0) {
		buf[n] = '\0';
		unsigned int level;
		if (sscanf(buf, "%d", &level) == 1) {
			enabled_levels_mask = level;
		}
	}

	return 0;
}

static void *socket_thread(void *arg)
{
	while (1) {
		int fd = socket(AF_UNIX, SOCK_STREAM, 0);
		if (fd < 0) {
			sleep(1);
			continue;
		}

		struct sockaddr_un addr = { 0 };
		addr.sun_family		= AF_UNIX;
		strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

		if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
			close(fd);
			socket_connected = 0;
			use_stdout	 = 1;
			sleep(1);
			continue;
		}

		socket_connected = 1;
		use_stdout	 = 0;
		request_level(fd);

		char buf[BUF_SIZE];
		ssize_t offset = 0;

		while (1) {
			ssize_t n = read(fd, buf + offset, BUF_SIZE - 1 - offset);
			if (n <= 0)
				break;

			offset += n;
			buf[offset] = '\0';

			char *line = buf;
			char *newline;
			while ((newline = strchr(line, '\n'))) {
				*newline = '\0';
				char prog[64];
				unsigned int level;
				if (sscanf(line, "%63[^.].log_level=%d", prog, &level) == 2) {
					char progname_base[64];
					strncpy(progname_base, PROGNAME, sizeof(progname_base) - 1);
					progname_base[sizeof(progname_base) - 1] = '\0';
					char *at = strchr(progname_base, '@');
					if (at) *at = '\0';

					at = strchr(prog, '@');
					if (at) *at = '\0';
					if (strcmp(prog, progname_base) == 0 || strcmp(prog, "global") == 0) {
						enabled_levels_mask = level;
					}
				}
				line = newline + 1;
			}

			offset = buf + offset - line;
			if (offset > 0)
				memmove(buf, line, offset);
		}

		close(fd);
		socket_connected = 0;
		use_stdout	 = 1;
		sleep(5);
	}
	return NULL;
}

int logger_init_ext(int _min_level, int logger_type, const char *prog_name, int _pid, int _facility)
{
	pid	 = _pid;
	facility = _facility;
	return logger_init((log_level_type)_min_level, logger_type, prog_name);
}

int logger_init(log_level_type _min_level, int logger_type, const char *prog_name)
{
	if (initialized) {
		return 0;
	}
	PROGNAME = prog_name;
	if (_min_level == L_SYSTEM) {
		pthread_t tid;
		if (pthread_create(&tid, NULL, (void *(*)(void *))socket_thread, NULL) != 0) {
			return 1;
		}

		if (min_level == 0) {
			min_level = L_INFO;
		}
	}

	min_level = _min_level;
	
	initialized = 1;

	if (logger_type & L_TYPE_SYSLOG || logger_type == 0) {
		use_syslog = 1;
		openlog(prog_name, pid, facility);
	}

	if (logger_type & L_TYPE_STDOUT) {
		use_stdout = 1;
	}

	if (logger_type & L_SYSLOG_LEVELS) {
		syslog_levels=1;
	}

	return 0;
}

int log_get_level(void)
{
	return min_level;
}

static void log_syslog(int level, const char *fmt, va_list arg_list)
{
	pthread_mutex_lock(&syslog_mtx);
	vsyslog(level, fmt, arg_list);
	pthread_mutex_unlock(&syslog_mtx);
}

static void stdout_print_header(void)
{
	printf("[%-9s] %s\n", "Severity", "Message");
}

static void log_stdout(log_level_type level, const char *fmt, va_list arg_list)
{
	static int header_printed;

	pthread_mutex_lock(&stdout_mtx);
	if (!header_printed) {
		stdout_print_header();
		header_printed = 1;
	}

	printf("[%-9s] ", level_strings[level]);
	vprintf(fmt, arg_list);

	pthread_mutex_unlock(&stdout_mtx);
}

void _log(log_level_type level, const char *fmt, ...)
{
	static int last_state_connected = -1;
	if (socket_connected != last_state_connected) {
		last_state_connected = socket_connected;
	}
	va_list arg_list;
	if (min_level != L_SYSTEM && level < min_level) {
		return;
	} else {
		unsigned int lvl_bit = log_level_to_bit(level);
		if (!(enabled_levels_mask & lvl_bit)) {
			return;
		}
	}

	if (use_syslog) {
		va_start(arg_list, fmt);
		if (syslog_levels) {
			log_syslog(level, fmt, arg_list);
		} else {
			log_syslog(level_to_slevel[level], fmt, arg_list);
		}
			
		va_end(arg_list);
	}

	if (use_stdout) {
		va_start(arg_list, fmt);
		log_stdout(level, fmt, arg_list);
		va_end(arg_list);
	}
}

void _log_with_count(log_counter *counter, log_id id, log_level_type level, char *fmt, ...)
{
	va_list arg_list;

	// Counter should be reset if either new error is encountered
	// or service did not have any failures (id = LOG_ID_OK)
	if (id != counter->id || !id) {
		counter->count = 0;
		counter->id    = id;
		if (!id) {
			return;
		}
	}

	if (!initialized || level < min_level || !fmt) {
		return;
	}

	char last_fmt[strlen(fmt) + strlen(SPAM_WARNING) + 1];
	last_fmt[0] = 0;

	if (counter->count < MAX_LOG_MSG) {
		counter->count++;

		// If last log message is printed append info
		// about it's printing discontinuation
		if (counter->count == MAX_LOG_MSG) {
			snprintf(last_fmt, sizeof(last_fmt), "%s%s", fmt, SPAM_WARNING);
			fmt = last_fmt;
			counter->count++;
		}

		if (use_syslog) {
			va_start(arg_list, fmt);
			if (syslog_levels) {
				log_syslog(level, fmt, arg_list);
			} else {
				log_syslog(level_to_slevel[level], fmt, arg_list);
			}
			va_end(arg_list);
		}

		if (use_stdout) {
			va_start(arg_list, fmt);
			log_stdout(level, fmt, arg_list);
			va_end(arg_list);
		}
	}
}

void log_db(const char *as_sender, log_facility_type fac,
	log_level_type level, const char *fmt, ...)
{
	va_list arg_list;
	char message[1024];
	const char *user = as_sender ? as_sender : PROGNAME;

	va_start(arg_list, fmt);
	vsnprintf(message, sizeof(message), fmt, arg_list);
	va_end(arg_list);

	pthread_mutex_lock(&syslog_mtx);
	openlog(user, 0, fac);
	syslog(level_to_slevel[level], "%s", message);
	closelog();
	pthread_mutex_unlock(&syslog_mtx);
	if (PROGNAME) {
		openlog(PROGNAME, pid, facility);
	}
}