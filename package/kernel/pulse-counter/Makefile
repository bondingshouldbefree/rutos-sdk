#
# Copyright (C) 2024 Teltonika-Networks
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=tlt-pulse-counter
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE/GPL-2.0

include $(INCLUDE_DIR)/package.mk

define KernelPackage/tlt-pulse-counter
	SUBMENU:=Other modules
	TITLE:=Teltonika pulse counter module
	FILES:=$(PKG_BUILD_DIR)/pulse_counter.ko
	AUTOLOAD:=$(call AutoLoad,99,pulse_counter)
	KCONFIG:=
endef

MAKE_OPTS:= $(KERNEL_MAKE_FLAGS) M="$(PKG_BUILD_DIR)"

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" $(MAKE_OPTS) modules
endef

$(eval $(call KernelPackage,tlt-pulse-counter))
