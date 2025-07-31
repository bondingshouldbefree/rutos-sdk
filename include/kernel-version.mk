
# Use the default kernel version if the Makefile doesn't override it
LINUX_RELEASE?=1

ifdef CONFIG_TESTING_KERNEL
  KERNEL_PATCHVER:=$(KERNEL_TESTING_PATCHVER)
endif

LINUX_VERSION-4.14 = .336
LINUX_VERSION-5.4 = .293
LINUX_VERSION-msm5.4 = .244
LINUX_VERSION-5.15 = .184
LINUX_VERSION-6.6 = .92

LINUX_KERNEL_HASH-5.4.293 = 34589340c7d76c0de91965e5242f61e9f9f3bacd03e8e34239e5d4660d45372d
LINUX_KERNEL_HASH-5.15.184 = 9c3e98c6dcc7dca7c2e9dd51423eaf0581f5e100d0f04c23bc29f21913dac1d9
LINUX_KERNEL_HASH-6.6.92 = 1d82a82642d281c31d86f7301bc55e12a8a9f9c04532e249ef8ae6fe7dc237ec

remove_uri_prefix=$(subst git://,,$(subst http://,,$(subst https://,,$(1))))
sanitize_uri=$(call qstrip,$(subst @,_,$(subst :,_,$(subst .,_,$(subst -,_,$(subst /,_,$(1)))))))

ifneq ($(call qstrip,$(CONFIG_KERNEL_GIT_CLONE_URI)),)
#  LINUX_VERSION:=$(call sanitize_uri,$(call remove_uri_prefix,$(CONFIG_KERNEL_GIT_CLONE_URI)))
  ifeq ($(call qstrip,$(CONFIG_KERNEL_GIT_REF)),)
    CONFIG_KERNEL_GIT_REF:=HEAD
  endif
#  LINUX_VERSION:=$(LINUX_VERSION)-$(call sanitize_uri,$(CONFIG_KERNEL_GIT_REF))
#else
endif
ifdef KERNEL_PATCHVER
  LINUX_VERSION:=$(KERNEL_PATCHVER)$(strip $(LINUX_VERSION-$(KERNEL_PATCHVER)))
endif
ifdef KERNEL_TESTING_PATCHVER
  LINUX_TESTING_VERSION:=$(KERNEL_TESTING_PATCHVER)$(strip $(LINUX_VERSION-$(KERNEL_TESTING_PATCHVER)))
endif
#endif

split_version=$(subst ., ,$(1))
merge_version=$(subst $(space),.,$(1))
KERNEL_BASE=$(firstword $(subst -, ,$(LINUX_VERSION)))
KERNEL=$(call merge_version,$(wordlist 1,2,$(call split_version,$(KERNEL_BASE))))
KERNEL_PATCHVER ?= $(KERNEL)

# disable the md5sum check for unknown kernel versions
LINUX_KERNEL_HASH:=$(LINUX_KERNEL_HASH-$(strip $(LINUX_VERSION)))
LINUX_KERNEL_HASH?=x
