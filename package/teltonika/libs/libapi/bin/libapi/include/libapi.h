
#ifndef __LIBAPI_H__
#define __LIBAPI_H__

#include <libubus.h>

typedef enum {
	LAPI_SUCCESS = 0,
	LAPI_ERROR,
	LAPI_ACCESS_DENIED,
	LAPI_INVALID_METHOD,
	LAPI_INVALID_ENDPOINT,
} lapi_stat;

enum lapi_method {
	LAPI_METHOD_GET = 0,
	LAPI_METHOD_POST,
	LAPI_METHOD_PUT,
	LAPI_METHOD_DELETE,
	LAPI_METHOD_UNKNOWN = 8,
};

enum lapi_access_mode {
	LAPI_MODE_UNKNOWN = 0,
	LAPI_MODE_WHITELIST,
	LAPI_MODE_BLACKLIST,
};

#define LAPI_R_ACCESS  (1 << LAPI_METHOD_GET)
#define LAPI_W_ACCESS  (1 << LAPI_METHOD_POST | 1 << LAPI_METHOD_PUT | 1 << LAPI_METHOD_DELETE)
#define LAPI_RW_ACCESS (LAPI_R_ACCESS | LAPI_W_ACCESS)

struct lapi_response {
	uint32_t http_status; // HTTP status code
	uint8_t api_status;   // API status code
	// struct blob_buf b; // Blob buffer for response data
	struct blob_attr *api_data; // Pointer to API data blob
	struct blob_attr *errors; // Pointer to errors blob
};

/**
 * @brief init access control list
 * 
 * @return lapi_stat 
 */
lapi_stat lapi_init(void);

/**
 * @brief destroy access control list
 * 
 */
void lapi_destroy(void);

/**
 * @brief grant access to endpoint
 * 
 * @param endpoint API endpoint
 * @param method method to access
 * @return lapi_stat LAPI_SUCCESS if access granted, LAPI_ERROR otherwise
 */
lapi_stat lapi_grant_access(const char *endpoint, enum lapi_method method);

/**
 * @brief API method to enum conversion
 * 
 * @param method pointer to method string
 * @return enum lapi_method numeric representation of method or LAPI_METHOD_UNKNOWN if method is unknown
 */
enum lapi_method lapi_method_atoi(const char *method);

/**
 * @brief numeric representation of method to string conversion
 * 
 * @param method numeric representation of method
 * @return const char* pointer to string representation of method or NULL if method is unknown
 */
const char *lapi_method_str(enum lapi_method method);

/**
 * @brief call API endpoint
 * 
 * @param ubus pointer to ubus context
 * @param endpoint API endpoint
 * @param method API method to call
 * @param data request data to send to endpoint
 * @param resp pointer to blob_buf to store response
 * @return lapi_stat LAPI_SUCCESS if call was successful, LAPI_ERROR otherwise
 */
lapi_stat lapi_call(struct ubus_context *ubus, const char *endpoint,
		    enum lapi_method method, struct blob_attr *data, struct blob_buf *resp);

/**
 * @brief returns string representation of lapi_stat
 * 
 * @param status status code to convert to string
 * @return const char* pointer to string representation of status code
 */
const char *lapi_error_str(lapi_stat status);

/**
 * @brief parse response from API call
 * 
 * @param resp pointer to lapi_response structure to store parsed response
 * @param data pointer to blob_attr containing raw response data
 * @return lapi_stat LAPI_SUCCESS if response was parsed successfully, LAPI_ERROR otherwise
 */
lapi_stat lapi_parse_response(struct lapi_response *resp, struct blob_attr *data);

/**
 * @brief grant access to endpoint. Simplified version
 * 
 * @param endpoint API endpoint
 * @param method method to access
 * @return lapi_stat LAPI_SUCCESS if access granted, LAPI_ERROR otherwise
 */
static inline lapi_stat lapi_grant_access_simple(const char *endpoint, const char *method)
{
	return lapi_grant_access(endpoint, lapi_method_atoi(method));
}

#endif // __LIBAPI_H__
