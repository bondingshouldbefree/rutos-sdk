#ifndef H_POE_UTILS
#define H_POE_UTILS

#include <stdbool.h>
#include <stdio.h>

extern bool g_debug;

#define LOG(...)                                                                                             \
	do {                                                                                                 \
		fprintf(stdout, ##__VA_ARGS__);                                                              \
		fflush(stdout);                                                                              \
	} while (0);

#define ERR(fmt, ...)                                                                                        \
	do {                                                                                                 \
		fprintf(stdout, "[%s:%d] error: " fmt, __func__, __LINE__, ##__VA_ARGS__);                   \
		fflush(stdout);                                                                              \
	} while (0);

#define DBG(...)                                                                                             \
	do {                                                                                                 \
		if (g_debug) {                                                                               \
			fprintf(stdout, ##__VA_ARGS__);                                                      \
			fflush(stdout);                                                                      \
		}                                                                                            \
	} while (0);

#define PANIC(fmt, ...)                                                                                      \
	do {                                                                                                 \
		fprintf(stdout, "[%s:%d] error: " fmt, __func__, __LINE__, ##__VA_ARGS__);                   \
		fflush(stdout);                                                                              \
		exit(1);                                                                                     \
	} while (0);

#define POE_OK	     0
#define POE_ERR_SYS  -1
#define POE_ERR_NACK -2

#endif
