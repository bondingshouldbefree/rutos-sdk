#
# Copyright (C) 2016-2017 Dan Luedtke <mail@danrl.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=jool
PKG_VERSION:=4.1.12
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=4.1.12
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/NICMx/Jool/releases/download/v$(PKG_VERSION)

PKG_HASH:=f0c257371ea0b8f6a39143757bc8e3291000bbdba9794c043fd36467246b5431

PKG_MAINTAINER:=
PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:jool:jool

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS:=!USE_GLIBC:argp-standalone

include $(INCLUDE_DIR)/package.mk

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		KERNEL_DIR="$(LINUX_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		M="$(PKG_BUILD_DIR)/src/mod/common" \
		V="$(V)" \
		modules
	$(MAKE) -C "$(LINUX_DIR)" \
		KERNEL_DIR="$(LINUX_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		M="$(PKG_BUILD_DIR)/src/mod/nat64" \
		V="$(V)" \
		modules
	$(call Build/Compile/Default)
endef

define Package/jool/Default
  SECTION:=net
  CATEGORY:=Network
  URL:=https://www.jool.mx
endef

define Package/jool/Default/description
  Jool is an Open Source SIIT and NAT64 for Linux.
endef

define Package/jool
  $(call Package/jool/Default)
  TITLE:=Jool userspace control programs
  DEPENDS:=+libnl +libxtables +kmod-jool
endef

define Package/jool/description
  $(call Package/jool/Default/description)
endef

define KernelPackage/jool
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Support
  TITLE:=Jool kernel module
  DEPENDS:= \
    @IPV6 \
    +kmod-crypto-md5 \
    +kmod-nf-conntrack \
    +kmod-nf-conntrack6 \
    +kmod-nf-ipt
  FILES:= \
    $(PKG_BUILD_DIR)/src/mod/common/jool_common.$(LINUX_KMOD_SUFFIX) \
    $(PKG_BUILD_DIR)/src/mod/nat64/jool.$(LINUX_KMOD_SUFFIX)
  AUTOLOAD:=$(call AutoProbe,jool)
endef

define KernelPackage/jool/description
  $(call Package/jool/Default/description)

  This package provides the kernel module for Jool.
endef

define Package/jool/conffiles
/etc/config/jool
endef

define Package/jool/postinst
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	/etc/init.d/firewall reload >/dev/null 2>&1
	exit 0 
endef

CONFIGURE_ARGS += \
	--disable-shared \
	--without-bash-completion-dir

CONFIGURE_VARS += \
	ac_cv_func_memset=yes \
	ac_cv_func_strcasecmp=yes

define Package/jool/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/jool		$(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/joold		$(1)/usr/bin/

	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_jool)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/usr/lib/iptables
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/local/usr/lib/iptables/libxt_JOOL.so \
		$(DEST_DIR)/usr/lib/iptables

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/jool.config $(1)/etc/config/jool

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/jool.init $(1)/etc/init.d/jool
endef

$(eval $(call BuildPackage,jool))
$(eval $(call KernelPackage,jool))
