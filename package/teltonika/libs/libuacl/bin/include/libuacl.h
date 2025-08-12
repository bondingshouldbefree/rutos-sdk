
#ifndef __UACL_H
#define __UACL_H

#include <libubox/blobmsg.h>

typedef enum {
    UACL_SUCCESS,
    UACL_ERROR,
} uacl_stat;

struct uacl_context {
    struct blob_buf b;
    struct blob_attr *acl;
    const char *username;
    const char *group;
    uid_t uid;
    gid_t gid;
    uacl_stat status;
};

/**
 * @brief initialize uacl context
 * 
 * @param acl_path path to the ACL file
 * @return struct uacl_context* pointer to the initialized context or NULL on failure
 */
struct uacl_context *uacl_init(const char *acl_path);

/**
 * @brief destroy uacl context
 * 
 * @param ctx pointer to the uacl context to destroy
 */
void uacl_destroy(struct uacl_context *ctx);

/**
 * @brief verify access to a node
 * 
 * @param ctx pointer to the uacl context
 * @param nodes entry to check
 * @param mask mask of the methods to check
 * @return uacl_stat UACL_SUCCESS if access is granted, UACL_ERROR if access is denied
 */
uacl_stat uacl_grant_access(struct uacl_context *ctx, const char **nodes, int mask);

#endif /* __UACL_H */
