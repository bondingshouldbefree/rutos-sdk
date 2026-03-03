# libtlt-logger

## Overview

The library provides a unified API for logging messages through multiple backends:

syslog — integrates with the system logging facility

stdout — outputs logs to the console, useful for debugging or development

logd socket — connects to a Unix domain socket managed by logd for centralized logging and runtime log-level management

When connected to the logd socket, the logger dynamically receives configuration updates that determine which log levels are enabled.
This allows the application to perform local filtering of log messages, preventing unnecessary logs from being generated or transmitted.

## Features 

- Thread-safe logging with internal mutex protection
- Configurable backends (syslog, stdout, or both)
- Dynamic runtime log-level management via Unix socket
- Client-side log filtering based on bitmask updates
- Graceful fallback to local logging if socket connection fails
- Background reconnect thread to maintain persistent connection
- Optional spam suppression with _log_with_count()

## Architecture

### Initialization and Socket Thread
1. When initialized with L_SYSTEM as the minimum log level, the logger starts a background thread that handles communication with logd.
2. The thread attempts to connect to the configured Unix domain socket (`SOCKET_PATH`).
3. Once connected, it sends a query to logd:
```
<progname>.log_level?
```
4. logd responds with a bitmask representing the enabled log levels. The library updates its internal enabled_levels_mask accordingly.
5. The thread listens for further configuration updates such as:
```
global.log_level=<bitmask>
myservice.log_level=<bitmask>
```
6. Whenever such an update is received, the library immediately adjusts which messages are emitted based on the new mask.

If the socket connection is lost, the logger switches to local logging (stdout) and periodically retries the connection.

## Log Levels

| Level Name | Enum Symbol | Syslog Equivalent | Description               |
| ---------- | ----------- | ----------------- | ------------------------- |
| Emergency  | `L_EMERG`   | `LOG_EMERG`       | System unusable           |
| Alert      | `L_ALERT`   | `LOG_ALERT`       | Immediate action required |
| Critical   | `L_CRIT`    | `LOG_CRIT`        | Critical conditions       |
| Error      | `L_ERROR`   | `LOG_ERR`         | Error conditions          |
| Warning    | `L_WARNING` | `LOG_WARNING`     | Warning conditions        |
| Notice     | `L_NOTICE`  | `LOG_NOTICE`      | Normal but significant    |
| Info       | `L_INFO`    | `LOG_INFO`        | Informational messages    |
| Debug      | `L_DEBUG`   | `LOG_DEBUG`       | Debug-level messages      |

Each log level corresponds to a single bit in a runtime bitmask.
This allows enabling or disabling any combination of levels dynamically.

Legacy numeric levels (0–7) are automatically reversed if L_SYSTEM is not used:

0 → L_DEBUG
7 → L_EMERG

## Initialization
## Function Signatures

```
int logger_init(log_level_type min_level, int logger_type, const char *prog_name);
int logger_init_ext(int min_level, int logger_type, const char *prog_name, int pid, int facility);
```

### Parameters

min_level
Minimum log level to output.
If set to L_SYSTEM, the library will use logd for runtime configuration.

### logger_type
Output destination flags:

- L_TYPE_SYSLOG — use syslog
- L_TYPE_STDOUT — use standard output
- Both can be combined
- prog_name
Program name used to identify the service to logd.
- pid
PID flag used for syslog (only for logger_init_ext()).
- facility
Syslog facility such as LOG_DAEMON, LOG_USER, etc.

### Logging API
Functions
```
void _log(log_level_type level, const char *fmt, ...);
void _log_with_count(log_counter *counter, log_id id, log_level_type level, char *fmt, ...);
```

### Description

- _log()
Logs a formatted message at the given level.
The message is emitted only if the corresponding level bit is enabled in the mask.

- _log_with_count()
Similar to _log(), but suppresses repetitive messages after a threshold.
Useful for preventing log flooding in repetitive error conditions.

### Example
```
_log(L_INFO, "Service started successfully (pid=%d)\n", getpid());
_log(L_ERROR, "Failed to connect to database: %s\n", strerror(errno));
```

### Runtime Log-Level Management

When connected to the logd socket:

- The logger requests and receives a bitmask defining which log levels are enabled.
- This configuration can be updated dynamically by logd or another management service.
- The application applies updates immediately without restarting.
- Log filtering is done locally based on this bitmask, preventing excess log generation and reducing CPU and I/O overhead.
- If disconnected from the socket:
- The logger falls back to using syslog or stdout depending on configuration.
- The background thread continuously attempts to reconnect.

### Thread Safety

All logging operations are thread-safe.
The library uses separate mutexes for syslog and stdout operations to prevent concurrent message interleaving or corruption in multi-threaded environments.

### Example Workflow

#### Initialization
```
logger_init(L_SYSTEM, L_TYPE_SYSLOG, "myservice");
```

#### Connection

The logger connects to the logd socket and retrieves the active log-level bitmask.

#### Runtime Updates

Administrator changes configuration:
```
myservice.log_level=240
```

The library applies this immediately, enabling only specific log levels.

#### Fallback

If the socket disconnects, logs continue via stdout until reconnected.

### Logging to database
The log_db() function provides a simple, thread-safe way to write messages directly to syslog, optionally under a different sender name and syslog facility.
Unlike _log(), it ignores runtime log-level filters and always emits the message as system event.

Function signature:
```
void log_db(const char *as_sender,
            log_facility_type fac,
            log_level_type level,
            const char *fmt, ...);
```

Parameters:
- as_sender — Optional sender name. If NULL, the library uses the program name (PROGNAME) as the sender.
- fac — Syslog facility (LOG_DAEMON, LOG_USER, LOG_AUTH, etc.) or log_facility_type enum:
```
typedef enum {
    LOG_SYSTEM      = LOG_LOCAL0,
    LOG_NETWORK     = LOG_LOCAL1,
    LOG_CONNECTIONS = LOG_LOCAL2,
    LOG_EVENTS      = LOG_LOCAL3,
} log_facility_type;
```

Behavior

1.Formats the message using the provided fmt and arguments.
2.Locks an internal mutex (syslog_mtx) for thread safety.
3.Opens a temporary syslog session with the specified sender and facility.
4.Sends the message to syslog using syslog().
5.Closes the temporary syslog session and restores the main logger session (if any).

## Summary

The TLT Logger library provides a flexible, efficient, and runtime-configurable logging mechanism for system applications.
By integrating with a logging daemon through a Unix socket, it enables dynamic log-level control, reducing unnecessary message generation and preventing system log overload.
It is suitable for embedded, multi-threaded, or service-based environments where controlled and lightweight logging is essential.