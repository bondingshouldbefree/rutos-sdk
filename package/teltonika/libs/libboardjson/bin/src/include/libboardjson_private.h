#ifndef LIBBOARDJSON_PRIVATE_H
#define LIBBOARDJSON_PRIVATE_H

#include "libboardjson.h"

#include <stdbool.h>
#include <libubox/blob.h>
#include <libubox/blobmsg.h>

// filepaths
#define BJSON_FILEPATH "/etc/board.json"
#define BJSON_FILEPATH_TEMP "/tmp/board.json"

// macros that retreive and null-check parsed blobmsg values
#define blob_get_str_nullchk(value) (value) ? strdup(blobmsg_get_string(value)) : ""
#define blob_get_bool_nullchk(value) (value) ? blobmsg_get_bool(value) : 0
#define blob_get_num_nullchk(value) (value) ? atoi(blobmsg_get_string(value)) : 0 // for string->int conversion
#define blob_get_u32_nullchk(value) (value) ? blobmsg_get_u32(value) : 0
#define blob_memdup_nullchk(value) (value) ? blob_memdup(value) : NULL

bool is_string_defined(const char *str);
void free_string(char **text);

int lbjson_parse_serial(struct lbjson_serial_device *devices, int max_count, struct blob_attr *data, struct lbjson_hwinfo *hw);

#endif /* LIBBOARDJSON_PRIVATE_H */
