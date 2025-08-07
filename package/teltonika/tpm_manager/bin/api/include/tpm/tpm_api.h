#ifndef TPM_TPM_API
#define TPM_TPM_API

/** @file tpm_api.h */

// Define how many tpm tpm_manager will support
#define MAX_TPM_OBJS 1

/**
 * Enumeration of tpm method action values
 */
typedef enum {
        ACT_OK, /*!< Valid result received */
        ACT_ERROR, /*!< Unknown error occurred */
	ACT_IMPORT_ERROR, /*!< Import error occurred */
	ACT_DATA_PROCESS_ERROR, /*!< Data processing error occurred */
	ACT_SESSION_ERROR, /*!< Session error occurred */
	ACT_EVICT_ERROR, /*!< Evict error occurred */
        ACT_ARG_INVALID, /*!< Invalid or missing arguments */
        ACT_MALLOC_FAIL, /*!< Failed memory allocation */
        ACT_EXCEPTION, /*<! Fatal exception occurred */
        ACT_RESPONSE_INVALID, /*!< Response is not valid */
	ACT_WRITE_ERROR, /*!< Write error occurred */
	ACT_NV_DEFINE_ERROR, /*!< NV define error occurred */
        ACT_NOT_SUPPORTED, /*!< Functionality not supported */
        ACT_TIMEOUT, /*!< Request timeout expired */

        __ACT_MAX,
} func_t;

/**
 * Enumeration of TPM functionality
 */
enum tpm_func_t {
        TPM_FULL_MODE, /* <! Standard tpm functionality */

        __TPM_MODE_MAX,
};

/**
 * Enumeration of tpm states
 */
enum tpm_state_id {
        TPM_STATE_UNKNOWN, /*< Unknown tpm state */
        TPM_STATE_IDLE, /*< Idle state */
        TPM_STATE_CMD_EXEC, /*< Regular command execution state */

        __TPM_STATE_MAX,
};

/**
 * Enumeration of tpm capabilities types
 */
enum tpm_cap_property_id {
	TPM_ACTIVE_SESSION_FIRST, /*!< Active session handles */
	TPM_LOADED_SESSION_FIRST, /*!< Loaded session handles */
	TPM_NV_INDEX_FIRST, /*!< NV index handles */
	TPM_PCR_FIRST, /*!< PCR handles */
	TPM_PERMANENT_FIRST, /*!< Permanent handles */
	TPM_PERSISTENT_FIRST, /*!< Persistent handles */
	TPM_TRANSIENT_FIRST, /*!< Transient handles */
	TPM_ECC_NIST_P192, /*!< ECC curves */
	TPM_PT_VAR, /*!< Variable properties */
	TPM_PT_FIXED, /*!< Fixed properties */
	TPM_PCRS, /*!< PCR properties */
	TPM_CC_FIRST, /*!< Command codes */
	TPM_ALG_FIRST, /*!< Algorithms */
	__TPM_CAP_MAX,
};

/**
 * Enumeration of Flash zone types
 */
enum nv_type_id {
	NV_TYPE_UNKNOWN, /*!< Unknown NV type */
	NV_TYPE_CERTIFICATE, /*!< Certificate NV type */
	NV_TYPE_KEY, /*!< Key NV type */
	__NV_TYPE_MAX,
};

/**
 * Enumeration of hash algorithm types
 */
enum alg_type_id {
	ALG_TYPE_UNKNOWN, /*!< Unknown algorithm type */
	ALG_TYPE_SHA1, /*!< SHA1 algorithm type */
	ALG_TYPE_SHA256, /*!< SHA256 algorithm type */
	ALG_TYPE_SHA384, /*!< SHA384 algorithm type */
	ALG_TYPE_SHA512, /*!< SHA512 algorithm type */
	ALG_TYPE_SM3_256, /*!< SM3-256 algorithm type */
	ALG_TYPE_SHA3_256, /*!< SHA3-256 algorithm type */
	ALG_TYPE_SHA3_384, /*!< SHA3-384 algorithm type */
	ALG_TYPE_SHA3_512, /*!< SHA3-512 algorithm type */
	__ALG_TYPE_MAX,
};

/**
 * Enumeration of key algorithm types
 */
enum key_alg_id {
	KEY_ALG_UNKNOWN, /*!< Unknown key algorithm */
	KEY_ALG_RSA, /*!< RSA key algorithm */
	KEY_ALG_ECC, /*!< ECC key algorithm */
	__KEY_ALG_MAX,
};

/**
 * Convert tpm capability enum to string.
 * @param[in]    id     TPM capabilities property enumeration value.
 * @return const char *. String of tpm capability string value.
 */
const char *tpm_cap_property_arg_str(enum tpm_cap_property_id id);

/**
 * Convert tpm state enum to string.
 * @param[in]    state     TPM state enumeration value.
 * @return const char *. String of tpm state value.
 */
const char *tpm_state_str(enum tpm_state_id state);

/**
 * Convert action status enum to string.
 * @param[in]    status     Action status enumeration value.
 * @return const char *. String of action status value.
 */
const char *act_status_str(func_t status);

/**
 * Convert NV type argument string to enumeration value.
 * @param[in]    type     NV type string.
 * @return enum nv_type_id. Enumeration value of NV type.
 */
enum nv_type_id nv_type_arg_to_enum(const char *arg);

/**
 * Convert algorithm type argument string to enumeration value.
 * @param[in]    arg     Algorithm type string.
 * @return enum alg_type_id. Enumeration value of algorithm type.
 */
enum alg_type_id alg_type_arg_to_enum(const char *arg);

/**
 * Convert key type argument string to enumeration value.
 * @param[in]    arg     Key algorithm type string.
 * @return enum key_type_id. Enumeration value of key aglorithm type.
 */
enum key_alg_id key_type_arg_to_enum(const char *arg);

#endif // TPM_TPM_API
