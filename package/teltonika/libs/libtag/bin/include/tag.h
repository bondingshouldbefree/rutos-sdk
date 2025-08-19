#ifndef TAG_H
#define TAG_H

#include <stdint.h>
#include <stdbool.h>
#include <libubus.h>

#ifdef __cplusplus
extern "C" {
#endif

#define MIN(a, b) ((a) < (b) ? (a) : (b))

/**
 * @brief Tag manager structure
 */
typedef struct tag_manager tag_manager_t;

/**
 * @brief Tag structure
 */
typedef struct tag tag_t;

/**
 * @brief Multi-value tag array structure
 */
typedef struct tag_multi_value tag_multi_value_t;

enum {
	RPC_TAG_GET_VAL_ID,
	RPC_TAG_GET_VAL_INDEX,
	RPC_TAG_GET_VAL_COUNT,
	RPC_TAG_GET_VAL_MAX,
};

enum {
	RPC_TAG_SET_VAL_ID,
	RPC_TAG_SET_VAL_VALUES,
	RPC_TAG_SET_VAL_INDEX,
	RPC_TAG_SET_VAL_MAX,
};

static const struct blobmsg_policy tag_get_policy[] = {
	[RPC_TAG_GET_VAL_ID]    = { .name = "id", .type = BLOBMSG_TYPE_STRING, },
	[RPC_TAG_GET_VAL_INDEX] = { .name = "index", .type = BLOBMSG_TYPE_INT32, },
	[RPC_TAG_GET_VAL_COUNT] = { .name = "count", .type = BLOBMSG_TYPE_INT32, },
};

static const struct blobmsg_policy tag_set_policy[] = {
	[RPC_TAG_SET_VAL_ID]     = { .name = "id", .type = BLOBMSG_TYPE_STRING, },
	[RPC_TAG_SET_VAL_VALUES] = { .name = "values", .type = BLOBMSG_TYPE_ARRAY, },
	[RPC_TAG_SET_VAL_INDEX]  = { .name = "index", .type = BLOBMSG_TYPE_INT32, },
};

/**
 * @brief Tag permissions
 */
#define TAG_PERM_NONE	   0x00 /**< No permissions */
#define TAG_PERM_READ	   0x01 /**< Read permission */
#define TAG_PERM_WRITE	   0x02 /**< Write permission */
#define TAG_PERM_READWRITE 0x03 /**< Read and write permissions */

/**
 * @brief Error codes returned by library functions
 */
typedef enum {
	TAG_SUCCESS		      = 0, /**< Operation completed successfully */
	TAG_ERROR_INVALID_PARAMETER   = -1, /**< Invalid parameter provided */
	TAG_ERROR_MEMORY_ALLOCATION   = -2, /**< Memory allocation failed */
	TAG_ERROR_NOT_FOUND	      = -3, /**< Requested tag not found */
	TAG_ERROR_DUPLICATE	      = -4, /**< Tag with the same ID already exists */
	TAG_ERROR_TYPE_MISMATCH	      = -5, /**< Tag type mismatch */
	TAG_ERROR_COMMUNICATION	      = -6, /**< Communication error (e.g., ubus) */
	TAG_ERROR_INTERNAL	      = -7, /**< Internal error */
	TAG_ERROR_NOT_IMPLEMENTED     = -8, /**< Functionality not implemented */
	TAG_ERROR_OPERATION_FAILED    = -9, /**< Operation failed */
	TAG_ERROR_INDEX_OUT_OF_BOUNDS = -10, /**< Index out of bounds for multi-value tag */
	TAG_ERROR_PERMISSION_DENIED   = -11, /**< Permission denied */
	TAG_ERROR_UNKNOWN	      = -12, /**< Unknown error */
} tag_error_t;

/**
 * @brief Tag endianness
 */
typedef enum {
	TAG_ENDIAN_LITTLE = 0,
	TAG_ENDIAN_BIG,
	TAG_ENDIAN_MAX,
} tag_endianness_t;

/**
 * @brief Tag data types enumeration
 */
typedef enum {
	TAG_TYPE_UNKNOWN = 0,
	TAG_TYPE_BOOL,
	TAG_TYPE_INT8,
	TAG_TYPE_UINT8,
	TAG_TYPE_INT16,
	TAG_TYPE_UINT16,
	TAG_TYPE_INT32,
	TAG_TYPE_UINT32,
	TAG_TYPE_INT64,
	TAG_TYPE_UINT64,
	TAG_TYPE_FLOAT32,
	TAG_TYPE_FLOAT64,
	TAG_TYPE_STRING,
	TAG_TYPE_BINARY,
	TAG_TYPE_MAX,
} tag_type_t;

/**
 * @brief Union to hold tag values of different types
 */
typedef union {
	bool bool_val;
	int8_t int8_val;
	uint8_t uint8_val;
	int16_t int16_val;
	uint16_t uint16_val;
	int32_t int32_val;
	uint32_t uint32_val;
	int64_t int64_val;
	uint64_t uint64_val;
	float float32_val;
	double float64_val;
	char *string_val;
	struct {
		uint8_t *data;
		size_t size;
	} binary_val;
	char *unknown_val;
} tag_value_t;

/**
 * @brief Tag structure definition
 */
struct tag {
	char *name; /**< Unique tag name. Server uses this to store different tags with the same ID. */
	char *id;   /**< Unique tag ID. Clients use this to identify the tag. */
	char *config_name; /**< Configuration name */
	char *pretty_name; /**< Human-readable name */
	char *source;	   /**< Source service (e.g., "modbus_client") */
	char *description; /**< Optional description */
	tag_type_t type;   /**< Data type */
	tag_value_t value; /**< Single value. This will be removed in future. Every tag will have multi-value array. */
	tag_value_t *values;
	size_t value_count;
	size_t value_size;  /**< Size of the value in bytes (for fixed-size types). */

	/**
	 * @brief Permissions for the tag
	 * 0x01 = Readable
	 * 0x02 = Writable
	 * 0x03 = Read/Write
	 */
	uint8_t permissions;

	/**
	 * @brief Read callback function.
	 * Called by tag_read() if non-NULL.
	 * Should fetch the latest value(s) from the source and update the tag
	 * using tag_set_value_at().
	 * @param tag The tag instance to update.
	 * @param user_data User-provided context.
	 * @return TAG_SUCCESS on success, error code otherwise.
	 */
	tag_error_t (*read_cb)(tag_t *tag, void *user_data);

	/**
	 * @brief Multi-value write callback function.
	 * Called by tag_write_multi() if non-NULL.
	 * Should write the provided array of values to the source.
	 * @param tag The tag being written to.
	 * @param values Array of values to write (caller owns memory for strings/binaries within).
	 * @param value_count Number of values in the array.
	 * @param start_index Starting index to write at the source.
	 * @param user_data User-provided context.
	 * @return TAG_SUCCESS on success, error code otherwise.
	 */
	tag_error_t (*write_cb)(tag_t *tag, tag_value_t *values, size_t value_count, size_t start_index, void *user_data);

	void *priv;		  /**< Private data pointer */
	size_t priv_size;	  /**< Size of the private data */
	void (*priv_free)(void *); /**< Private data free function */
};

typedef struct tag_get_request {
	char *tag_id; /**< Tag ID */
	size_t index; /**< Starting index of the value to get */
	size_t count; /**< Number of values to get */
} tag_get_request_t;

typedef struct tag_set_request {
	char *tag_id; /**< Tag ID */
	tag_value_t *values; /**< Array of values to set. It should be parsed after tag is found. */
	size_t count; /**< Number of values to set */
	size_t start_index; /**< Starting index to set */
	struct blob_attr *values_blob; /**< Parsed values blob */
} tag_set_request_t;

/**
 * @brief Initialize tag manager
 *
 * @return tag_manager_t* Pointer to the initialized tag manager, or NULL on failure
 */
tag_manager_t *tag_manager_init(void);

/**
 * @brief Clean up tag manager and free all resources
 *
 * @param tm Pointer to the tag manager
 */
void tag_manager_cleanup(tag_manager_t *tm);

/**
 * @brief Register a tag with the tag manager
 *
 * @param tm Pointer to the tag manager
 * @param tag Pointer to the tag to register
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag manager or tag
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 *         - TAG_ERROR_DUPLICATE: Tag with the same name already exists
 */
tag_error_t tag_register(tag_manager_t *tm, tag_t *tag);

/**
 * @brief Get a tag by name.
 *
 * Tag name is unique within the tag manager.
 *
 * @param tm Pointer to the tag manager
 * @param tag_name Name of the tag to get
 * @return tag_t* Pointer to the tag, or NULL if not found
 */
tag_t *tag_get_by_name(tag_manager_t *tm, const char *tag_name);

/**
 * @brief Get a tag by ID
 *
 * Important: if multiple tags share the same ID (e.g., registered with different names),
 * this function returns only the first one encountered during iteration.
 *
 * Generally, ID should be unique within the tag manager for clients.
 * Servers can register and use tag with same ID multiple times with different names for different registers.
 *
 * @param tm Pointer to the tag manager
 * @param tag_id ID of the tag to get
 * @return tag_t* Pointer to the tag, or NULL if not found
 */
tag_t *tag_get_by_id(tag_manager_t *tm, const char *tag_id);

/**
 * @brief Get tags by source
 *
 * @param tm Pointer to the tag manager
 * @param source Source to filter by
 * @param tags Pointer to store the array of tag pointers
 * @param count Pointer to store the number of tags found
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag manager, source, tags or count
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 */
tag_error_t tag_get_by_source(tag_manager_t *tm, const char *source, tag_t ***tags, size_t *count);

/**
 * @brief Get all tags
 *
 * @param tm Pointer to the tag manager
 * @param tags Pointer to store the array of tag pointers
 * @param count Pointer to store the number of tags found
 */
tag_error_t tag_get_all(tag_manager_t *tm, tag_t ***tags, size_t *count);

/**
 * @brief Read a tag value (triggers read callback if registered)
 *
 * If the tag has a read callback (`read_cb`), it will be called first to potentially
 * update the tag's value(s) from the source.
 *
 * @param tag Pointer to the tag
 * @param user_data User data to pass to the read callback
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag
 */
tag_error_t tag_read(tag_t *tag, void *user_data);

/**
 * @brief Write a tag value (triggers write callback if registered)
 *
 * Writes to the first value (index 0) of the tag.
 * If the tag has a write callback (`write_cb`), it will be called to perform the write to the source.
 * If no `write_cb` is registered, the tag's value at index 0 will be updated directly
 * in the tag manager's cache using tag_set_value_at(tag, 0, value).
 *
 * @param tag Pointer to the tag
 * @param value Value to write. The caller retains ownership of memory pointed to by
 *              value.string_val or value.binary_val.data; the library/callback
 *              will copy the data if needed.
 * @param user_data User data to pass to the write callback
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag
 *         - TAG_ERROR_WRITE_PERMISSION_DENIED: Write permission denied
 */
tag_error_t tag_write(tag_t *tag, tag_value_t *values, size_t count, size_t start_index, void *user_data);

/**
 * @brief Update a tag's value at index 0 (internal update, doesn't trigger callbacks)
 *
 * Directly updates the tag's value at index 0 in the tag manager's cache.
 * Use tag_set_value_at() to update other indices.
 *
 * @param tag Pointer to the tag
 * @param values New values. The tag takes ownership of memory allocated for
 *              values.string_val or values.binary_val.data if the type matches.
 * @param count Number of values to update.
 * @param start_index Index to start updating at.
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag
 */
tag_error_t tag_update(tag_t *tag, tag_value_t *values, size_t count, size_t start_index);


/**
 * @brief Read a tag value from ubus
 *
 * @param tag Pointer to the tag
 * @param ctx Ubus context
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag or ubus context
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 *         - TAG_ERROR_COMMUNICATION: Communication error (e.g., ubus)
 *         - TAG_ERROR_INTERNAL: Internal error
 */
tag_error_t tag_read_from_ubus(tag_t *tag, struct ubus_context *ctx);

/**
 * @brief Read a range of tag values from ubus
 *
 * @param tag Pointer to the tag
 * @param index Starting index
 * @param count Number of values to read
 * @param ctx Ubus context
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag or ubus context
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 *         - TAG_ERROR_COMMUNICATION: Communication error (e.g., ubus)
 *         - TAG_ERROR_INTERNAL: Internal error
 */
tag_error_t tag_read_range_from_ubus(tag_t *tag, size_t index, size_t count, struct ubus_context *ctx);

/**
 * @brief Write a tag value to ubus
 *
 * Writes to the first value (index 0) of the tag <value_count> number of values.
 *
 * @param tag Pointer to the tag
 * @param values Values to write
 * @param value_count Number of values to write
 * @param ctx Ubus context
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag or ubus context
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 *         - TAG_ERROR_COMMUNICATION: Communication error (e.g., ubus)
 *         - TAG_ERROR_INTERNAL: Internal error
 */
tag_error_t tag_write_to_ubus(tag_t *tag, tag_value_t *values, size_t value_count, struct ubus_context *ctx);

/**
 * @brief Write a range of tag values to ubus
 *
 * Writes to the <start_index> of the tag <value_count> number of values.
 *
 * @param tag Pointer to the tag
 * @param values Values to write
 * @param value_count Number of values to write
 * @param start_index Starting index
 * @param ctx Ubus context
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag or ubus context
 *         - TAG_ERROR_MEMORY_ALLOCATION: Memory allocation failed
 *         - TAG_ERROR_COMMUNICATION: Communication error (e.g., ubus)
 *         - TAG_ERROR_INTERNAL: Internal error
 */

tag_error_t tag_write_range_to_ubus(tag_t *tag, tag_value_t *values, size_t value_count, size_t start_index,
			       struct ubus_context *ctx);
/**
 * @brief Read a tag value from ubus (from other services)
 *
 * @deprecated THIS WILL BE REMOVED IN THE FUTURE.
 * Use tag_read_from_ubus() instead.
 *
 * If the received value is not of the same type as the tag, the tag value will not be updated.
 * If the received value has unknown type, the provided tag type will be used to parse the value.
 *
 * @param tag Pointer to the tag
 * @param ctx Pointer to the ubus context
 * @return tag_t* Pointer to the tag with updated value, or NULL if not found or error
 */
tag_t *tag_read_value_from_ubus(tag_t *tag, struct ubus_context *ctx);

/**
 * @brief Read a tag value by name
 *
 * @param tm Pointer to the tag manager
 * @param tag_name Name of the tag to read
 * @param user_data User data to pass to the read callback
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_read_by_name(tag_manager_t *tm, const char *tag_name, void *user_data);

/**
 * @brief Write a tag value by name
 *
 * @param tm Pointer to the tag manager
 * @param tag_name Name of the tag to write
 * @param values Values to write
 * @param count Number of values to write
 * @param start_index Index to start writing at
 * @param user_data User data to pass to the write callback
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_write_by_name(tag_manager_t *tm, const char *tag_name, tag_value_t *values, size_t count, size_t start_index, void *user_data);

/**
 * @brief Update a tag value by name
 *
 * @param tm Pointer to the tag manager
 * @param tag_name Name of the tag to update
 * @param values Values to update
 * @param count Number of values to update
 * @param start_index Index to start updating at
 * @param user_data User data to pass to the update callback
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_update_by_name(tag_manager_t *tm, const char *tag_name, tag_value_t *values, size_t count, size_t start_index, void *user_data);

/**
 * @brief Read a tag value (triggers read callback if registered)
 *
 * Finds the tag by ID and reads the value.
 *
 * If the tag has a read callback, it will be called to get the value. Callback should update the tag value.
 * If the tag does not have a read callback, tag will be returned from the tag manager.
 *
 * @param tm Pointer to the tag manager
 * @param tag_id ID of the tag to read
 * @param user_data User data to pass to the read callback
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_read_by_id(tag_manager_t *tm, const char *tag_id, void *user_data);

/**
 * @brief Write a tag value (triggers write callback if registered)
 *
 * Finds the tag by ID and writes the value.
 *
 * If the tag has a write callback, it will be called to write the value. Callback should update the tag value.
 * If the tag does not have a write callback, tag will be updated in the tag manager.
 *
 * For multi-value tags, this will write to the first value in the array.
 *
 * @param tm Pointer to the tag manager
 * @param tag_id ID of the tag to write
 * @param values Values to write
 * @param count Number of values to write
 * @param start_index Index to start writing at
 * @param user_data User data to pass to the write callback
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_write_by_id(tag_manager_t *tm, const char *tag_id, tag_value_t *values, size_t count, size_t start_index, void *user_data);

/**
 * @brief Update a tag value (internal update, doesn't trigger callbacks)
 *
 * Finds the tag by ID and updates the value.
 *
 * For multi-value tags, this will update the first value in the array.
 *
 * @param tm Pointer to the tag manager
 * @param tag_id ID of the tag to update
 * @param values Values to update
 * @param count Number of values to update
 * @param start_index Index to start updating at
 * @return tag_t* Pointer to the tag, or NULL if not found or error
 */
tag_t *tag_update_by_id(tag_manager_t *tm, const char *tag_id, tag_value_t *values, size_t count,
			size_t start_index);

/**
 * @brief Initialize or resize the value array for a tag.
 *
 * Allocates or reallocates the internal `values` array.
 * If reallocating, existing values up to the minimum of the old and new
 * counts might be preserved (depending on reallocation behavior), but any
 * dynamically allocated data (strings, binaries) within values beyond the
 * new count will be freed. Initializes new elements to zero.
 * Sets `tag->value_count`.
 *
 * @param tag Pointer to the tag
 * @param count Number of values to allocate for. Must be > 0.
 * @return tag_error_t TAG_SUCCESS on success, TAG_ERROR_MEMORY_ALLOCATION or TAG_ERROR_INVALID_PARAMETER on failure.
 */
tag_error_t tag_resize_values(tag_t *tag, size_t count);

/**
 * @brief Get a pointer to a specific value from a tag's value array.
 *
 * Provides read-only access to the value.
 * For string and binary types, the returned pointers (`value->string_val`,
 * `value->binary_val.data`) point directly to the tag's internal memory.
 * Do not free or modify this memory. The pointers are valid only as long
 * as the tag itself and its value array are not modified or freed.
 *
 * @param tag Pointer to the tag.
 * @param index Index of the value to get.
 * @param value Pointer to a tag_value_t structure where the value's data/pointers will be copied.
 * @return tag_error_t TAG_SUCCESS on success, TAG_ERROR_INDEX_OUT_OF_BOUNDS or TAG_ERROR_INVALID_PARAMETER on failure.
 */
tag_error_t tag_get_value_at(const tag_t *tag, size_t index, tag_value_t *value);

/**
 * @brief Set a specific value in a tag's value array.
 *
 * Updates the tag's value in the tag manager's cache. Does not trigger callbacks.
 * The tag takes ownership of dynamically allocated memory (string_val, binary_val.data)
 * in the provided `value` if the type matches. Any previously held memory at this
 * index for string/binary types will be freed.
 *
 * @param tag Pointer to the tag.
 * @param index Index of the value to set.
 * @param value The value to set.
 * @return tag_error_t TAG_SUCCESS on success, or an error code (e.g., TAG_ERROR_INDEX_OUT_OF_BOUNDS,
 *         TAG_ERROR_MEMORY_ALLOCATION, TAG_ERROR_TYPE_MISMATCH, TAG_ERROR_INVALID_PARAMETER).
 */
tag_error_t tag_set_value_at(tag_t *tag, size_t index, tag_value_t value);

/**
 * @brief Convert tag manager to blob for ubus
 *
 * @param tm Pointer to the tag manager
 * @param b Pointer to the blob buffer
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag manager or blob buffer
 */
tag_error_t tag_manager_to_blob(tag_manager_t *tm, struct blob_buf *b);

/**
 * @brief Convert tag value to blob for ubus
 *
 * @param value Pointer to the tag value
 * @param type Tag type
 * @param b Pointer to the blob buffer
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid value or blob buffer
 */
tag_error_t tag_value_to_blob(tag_value_t *value, tag_type_t type, struct blob_buf *b);

/**
 * @brief Convert tag values to blob for ubus
 *
 * Serializes a range of values from a tag's value array.
 *
 * @param tag Pointer to the tag.
 * @param index Starting index of values to include.
 * @param count Number of values to include (if 0, attempts to include all from index).
 * @param b Pointer to the blob buffer.
 * @return tag_error_t TAG_SUCCESS on success, error code on failure.
 */
tag_error_t tag_values_to_blob(tag_t *tag, size_t index, size_t count, struct blob_buf *b);

/**
 * @brief Find tag by ID and convert to blob for ubus
 *
 * @param tm Pointer to the tag manager
 * @param id ID of the tag
 * @param b Pointer to the blob buffer
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag manager, ID or blob buffer
 *         - TAG_ERROR_NOT_FOUND: Tag with the specified ID not found
 */
tag_error_t tag_by_id_to_blob(tag_manager_t *tm, const char *id, struct blob_buf *b);

/**
 * @brief Convert tag metadata and optionally value(s) to blob for ubus
 *
 * Includes metadata like id, names, source, type, permissions, value_count.
 * How values are included depends on the implementation (e.g., might include
 * the first value, or require a separate call to tag_values_to_blob).
 *
 * @param tag Pointer to the tag
 * @param b Pointer to the blob buffer
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 */
tag_error_t tag_to_blob(tag_t *tag, struct blob_buf *b);

/**
 * @brief Create a boolean tag value
 *
 * @param val Boolean value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_bool(bool val);

/**
 * @brief Create an int8 tag value
 *
 * @param val Int8 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_int8(int8_t val);

/**
 * @brief Create a uint8 tag value
 *
 * @param val Uint8 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_uint8(uint8_t val);

/**
 * @brief Create an int16 tag value
 *
 * @param val Int16 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_int16(int16_t val);

/**
 * @brief Create a uint16 tag value
 *
 * @param val Uint16 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_uint16(uint16_t val);

/**
 * @brief Create an int32 tag value
 *
 * @param val Int32 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_int32(int32_t val);

/**
 * @brief Create a uint32 tag value
 *
 * @param val Uint32 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_uint32(uint32_t val);

/**
 * @brief Create an int64 tag value
 *
 * @param val Int64 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_int64(int64_t val);

/**
 * @brief Create a uint64 tag value
 *
 * @param val Uint64 value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_uint64(uint64_t val);

/**
 * @brief Create a float32 tag value
 *
 * @param val Float value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_float32(float val);

/**
 * @brief Create a float64 tag value
 *
 * @param val Double value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_float64(double val);

/**
 * @brief Create a string tag value
 *
 * @param val String value (will be copied)
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_string(const char *val);

/**
 * @brief Create a binary tag value
 *
 * @param data Binary data (will be copied)
 * @param size Size of the binary data
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_binary(const uint8_t *data, size_t size);

/**
 * @brief Create an unknown tag value
 *
 * This is used for tags that have unknown type. This has to be converted to the correct type when read.
 * Currently it is always a string.
 *
 * @param val Unknown value
 * @return tag_value_t Tag value
 */
tag_value_t tag_value_create_unknown(const char *val);

/**
 * @brief Convert tag type to string representation
 *
 * @param type Tag type
 * @return const char* String representation
 */
const char *tag_type_to_string(tag_type_t type);

/**
 * @brief Convert string to tag type
 *
 * @param type_str String representation of tag type
 * @return tag_type_t Tag type
 */
tag_type_t tag_type_from_string(const char *type_str);

/**
 * @brief Generate a unique tag ID
 *
 * @param name Tag name
 * @param index Tag index
 * @return char* Generated ID (must be freed by caller)
 */
char *tag_generate_id(const char *name, uint32_t index);

/**
 * @brief Free tag resources
 *
 * @param tag Pointer to the tag to free
 */
void tag_free(tag_t *tag);

/**
 * @brief Free tag value
 *
 * @param value Pointer to the tag value to free
 * @param type Tag type
 */
void tag_free_value(tag_value_t *value, tag_type_t type);

/**
 * @brief Free tag multi-value array and its contents.
 *
 * @param values Pointer to the tag multi-value array to free
 * @param count Number of values to free
 * @param type Tag type
 */
void tag_free_multi_value(tag_value_t *values, size_t count, tag_type_t type);

/**
 * @brief Iterate through all tags
 *
 * @param tm Pointer to the tag manager
 * @param callback Callback function to call for each tag
 * @param user_data User data to pass to the callback
 * @return tag_error_t TAG_SUCCESS on success, or the first error code returned by the callback.
 */
tag_error_t tag_foreach(tag_manager_t *tm, int (*callback)(tag_t *tag, void *user_data), void *user_data);

/**
 * @brief Search tags using a custom filter callback without allocating memory
 *
 * @param tm Pointer to the tag manager
 * @param filter Filter function (return non-zero to include tag)
 * @param filter_data User data for the filter function
 * @param results Array to store pointers to matching tags
 * @param max_results Maximum number of results to store
 * @param count Pointer to store the number of results found
 * @return tag_error_t TAG_SUCCESS on success. 1 if more results were available than max_results. Error code on failure.
 */
tag_error_t tag_search(tag_manager_t *tm, int (*filter)(tag_t *tag, void *filter_data), void *filter_data,
		       tag_t **results, size_t max_results, size_t *count);

/**
 * @brief Convert tag error to string
 *
 * @param error Tag error
 * @return const char* String representation
 */
const char *tag_error_to_string(tag_error_t error);

/**
 * @brief Convert string to tag error
 *
 * @param str String representation of tag error
 * @return tag_error_t Tag error
 */
tag_error_t tag_string_to_error(const char *str);

/**
 * @brief Convert tag error to UBUS status code
 *
 * @param error Tag error
 * @return int UBUS status code
 */
int tag_error_to_ubus_status(tag_error_t error);

/**
 * @brief Get the size of a tag type in bytes
 *
 * @param type Tag type
 * @return uint8_t Size in bytes
 */
uint8_t tag_type_size(tag_type_t type);

/**
 * @brief Get the size of a tag type in bits
 *
 * @param type Tag type
 * @return uint8_t Size in bits
 */
uint8_t tag_type_bit_size(tag_type_t type);

/**
 * @brief Check if a tag is readable
 *
 * @param tag Pointer to the tag
 * @return bool True if the tag is readable, false otherwise
 */
bool tag_is_readable(const tag_t *tag);

/**
 * @brief Check if a tag is writable
 *
 * @param tag Pointer to the tag
 * @return bool True if the tag is writable, false otherwise
 */
bool tag_is_writable(const tag_t *tag);

/**
 * @brief Format a tag value to a string
 *
 * @param tag Pointer to the tag
 * @param buf Buffer to store the formatted value
 * @param size Size of the buffer
 */
void tag_format_value(tag_t *tag, char *buf, size_t size);

/**
 * @brief Format a specific value from a multi-value tag to a string
 *
 * @param tag Pointer to the tag
 * @param index Index of the value to format
 * @param buf Buffer to store the formatted value
 * @param size Size of the buffer
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 */
tag_error_t tag_format_value_at(tag_t *tag, size_t index, char *buf, size_t size);

/**
 * @brief Convert bytes to a tag value
 *
 * @param new_value Pointer to the tag value
 * @param type Tag type
 * @param endianness Endianness of the bytes
 * @param bytes Bytes to convert
 * @param byte_count Number of bytes to convert
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag, bytes, new_value or endianness
 *         - TAG_ERROR_TYPE_MISMATCH: Tag type does not match the bytes type
 */
int tag_bytes_to_value(tag_value_t *new_value, tag_type_t type, tag_endianness_t endianness,
		       const uint8_t *bytes, size_t byte_count);

/**
 * @brief Convert a tag value to bytes
 *
 * @param value Pointer to the tag value
 * @param type Tag type
 * @param endianness Endianness of the bytes
 * @param bytes Bytes to store the converted value
 * @param byte_count Number of bytes to store
 * @return tag_error_t TAG_SUCCESS on success, error code on failure
 *         - TAG_ERROR_INVALID_PARAMETER: Invalid tag, value or endianness
 *         - TAG_ERROR_TYPE_MISMATCH: Tag type does not match the value type
 */
int tag_value_to_bytes(const tag_value_t *value, tag_type_t type, tag_endianness_t endianness, uint8_t *bytes,
		       size_t byte_count);

/**
 * @brief Helper function to add an error message to a blob buffer.
 * @param b Blob buffer.
 * @param error Error code.
 */
void tag_reply_with_error(struct blob_buf *b, tag_error_t error);

/**
 * @brief Parses a ubus message containing a tag get request.
 *
 * Extracts the 'tag_id' and optional 'index' and 'count' from the blob message.
 *
 * @param request The target tag (used to determine expected value type).
 * @param msg The ubus blob message attribute containing the request data.
 * @return tag_error_t TAG_SUCCESS on success, error code otherwise.
 */
tag_error_t tag_parse_get_request(tag_get_request_t *req, struct blob_attr *msg);

/**
 * @brief Parses a ubus message containing values to set for a tag.
 *
 * Extracts the 'values' array or single 'value' and optional 'index' from the blob message.
 * The caller is responsible for freeing the individual values within it using tag_set_request_free().
 *
 * @param request The target tag (used to determine expected value type).
 * @param msg The ubus blob message attribute containing the request data.
 * @return tag_error_t TAG_SUCCESS on success, error code otherwise.
 */
tag_error_t tag_parse_set_request(tag_set_request_t *req, struct blob_attr *msg);

/**
 * @brief Parses a ubus message containing values to set for a tag.
 *
 * Extracts the 'values' array or single 'value' and optional 'index' from the blob message.
 * Converts the blob values to tag_value_t based on the tag's type.
 * The caller is responsible for freeing the returned 'parsed_values' within it using tag_set_request_free().
 *
 * @param request The target tag (used to determine expected value type).
 * @param msg The ubus blob message attribute containing the request data.
 * @param type Tag type
 * @return tag_error_t TAG_SUCCESS on success, error code otherwise.
 */
tag_error_t tag_parse_set_request_values(tag_set_request_t *req, struct blob_attr *msg, tag_type_t type);

/**
 * @brief Free a tag set request
 *
 * @param request The tag set request to free
 * @param type Tag type
 */
void tag_set_request_free(tag_set_request_t *req, tag_type_t type);

/**
 * @brief Free a tag get request
 *
 * @param request The tag get request to free
 */
void tag_get_request_free(tag_get_request_t *req);

#ifdef __cplusplus
}
#endif

#endif /* TAG_H */