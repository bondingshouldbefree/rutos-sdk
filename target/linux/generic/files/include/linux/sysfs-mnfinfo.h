
#ifndef _SYSFS_MNFINFO_H
#define _SYSFS_MNFINFO_H

const char *mnf_info_get_device_name(void);
const char *mnf_info_get_batch(void);
const char *mnf_info_get_branch(void);
int mnf_info_get_full_hw_version(void);

#endif
