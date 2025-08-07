# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2008-2011 OpenWrt.org

include $(TOPDIR)/rules.mk

ARCH:=mipsel
BOARD:=ramips
BOARDNAME:=MediaTek Ralink MIPS
SUBTARGETS:=mt7621
FEATURES:=squashfs gpio reset_button

KERNEL_PATCHVER:=5.15
KERNEL_TESTING_PATCHVER:=5.15

ifeq ($(SUBTARGET),mt7621)
KERNEL_PATCHVER:=6.6
KERNEL_TESTING_PATCHVER:=6.6
FEATURES += smp
endif

define Target/Description
	Build firmware images for Ralink RT288x/RT3xxx based boards.
endef

include $(INCLUDE_DIR)/target.mk


DEFAULT_PACKAGES += kmod-leds-gpio

$(eval $(call BuildTarget))
