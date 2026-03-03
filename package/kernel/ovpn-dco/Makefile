#
# Copyright (C) 2021 Jianhui Zhao <zhaojh329@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=ovpn-dco
PKG_VERSION:=0.2.20241216
PKG_RELEASE:=4

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/OpenVPN/ovpn-dco/tar.gz/v$(PKG_VERSION)?
PKG_HASH:=0b30b8973b362b80a05f278ae217f01a2a2417e16e9c68c486960275a55306cc

PKG_MAINTAINER:=Jianhui Zhao <zhaojh329@gmail.com>
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=README


include $(INCLUDE_DIR)/package.mk

define KernelPackage/ovpn-dco-v2
  SUBMENU:=Network Support
  TITLE:=OpenVPN data channel offload
  DEPENDS:=+kmod-crypto-aead +kmod-udptunnel4 +IPV6:kmod-udptunnel6
  FILES:=$(PKG_BUILD_DIR)/drivers/net/ovpn-dco/ovpn-dco-v2.ko
  AUTOLOAD:=$(call AutoLoad,30,ovpn-dco-v2)
  ifeq (m, $(CONFIG_PACKAGE_kmod-ovpn-dco-v2))
    PKG_TLT_NAME:=OpenVPN DCO support
    PKG_ROUTER:=$(TLT_PLATFORM_NAME)
  endif
endef

define KernelPackage/ovpn-dco-v2/description
  This module enhances the performance of the OpenVPN userspace software
  by offloading the data channel processing to kernelspace.
endef

define Package/kmod-ovpn-dco-v2/postinst
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	/etc/init.d/openvpn restart >/dev/null 2>&1
	exit 0
endef

define Package/kmod-ovpn-dco-v2/postrm
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	rmmod ovpn_dco_v2 >/dev/null 2>&1
	/etc/init.d/openvpn restart >/dev/null 2>&1
	exit 0
endef

NOSTDINC_FLAGS += \
	$(KERNEL_NOSTDINC_FLAGS) \
	-I$(PKG_BUILD_DIR)/include \
	-include $(PKG_BUILD_DIR)/linux-compat.h

EXTRA_KCONFIG:= \
	CONFIG_OVPN_DCO_V2=m

PKG_EXTMOD_SUBDIRS = drivers/net/ovpn-dco

MAKE_OPTS:= \
	$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)/drivers/net/ovpn-dco" \
	NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,ovpn-dco-v2))
