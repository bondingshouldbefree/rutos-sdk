
# Use the default kernel version if the Makefile doesn't override it
LINUX_RELEASE?=1

ifdef CONFIG_TESTING_KERNEL
  KERNEL_PATCHVER:=$(KERNEL_TESTING_PATCHVER)
endif

LINUX_VERSION-4.14 = .336
LINUX_VERSION-5.4 = .302
LINUX_VERSION-msm5.4 = .244
LINUX_VERSION-5.15 = .197
LINUX_VERSION-msm5.15 = .144
LINUX_VERSION-6.6 = .119
LINUX_VERSION-4.9 = .333


LINUX_KERNEL_HASH-5.4.302 = ae6a3207f12aa4d6cfb0fa793ec9da4a6fcdfdcb57d869d63d6b77e3a8c1423d
LINUX_KERNEL_HASH-5.15.197 = fd218df8e2107a4443b6c29fef7f95aad167031e0fbdbc7a858ae8471360668a
LINUX_KERNEL_HASH-6.6.119 = 3da09b980bb404cc28793479bb2d6c636522679215ffa65a04c893575253e5e8

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
