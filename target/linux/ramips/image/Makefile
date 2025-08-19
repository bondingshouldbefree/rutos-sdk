# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2008-2011 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define Device/Default
	DEVICE_VENDOR := TELTONIKA
	PROFILES = Default
	MTDPARTS :=
	DEVICE_DTS_DIR := ../dts
	COMPILE :=

	IMAGES := sysupgrade.bin
	IMAGES += $(if $(CONFIG_BUILD_FACTORY_IMAGE),master_fw.bin)
endef

include $(SUBTARGET).mk

$(eval $(call BuildImage))
