#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ethtool
PKG_VERSION:=6.15
PKG_RELEASE:=3

PKG_SOURCE_VERSION:=6.15
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.xz
PKG_SOURCE_URL:=@KERNEL/software/network/ethtool

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
PKG_HASH:=9477c365114d910120aaec5336a1d16196c833d8486f7c6da67bedef57880ade

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:kernel:ethtool

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1

PKG_CONFIG_DEPENDS:=CONFIG_ETHTOOL_NETLINK CONFIG_ETHTOOL_PRETTY_DUMP

include $(INCLUDE_DIR)/package.mk

define Package/ethtool
  SECTION:=net
  CATEGORY:=Network
  VARIANT:=full
  DEPENDS:=+libmnl
  CONFLICTS:=ethtool-tiny
  TITLE:=Display or change ethernet card settings
  URL:=http://www.kernel.org/pub/software/network/ethtool/
endef

define Package/ethtool-tiny
  SECTION:=net
  CATEGORY:=Network
  VARIANT:=tiny
  TITLE:=Display or change ethernet card settings
  URL:=http://www.kernel.org/pub/software/network/ethtool/
endef

define Package/ethtool/description
 ethtool is a small utility for examining and tuning your ethernet-based
 network interface
endef

define Package/ethtool-tiny/description
 ethtool is even smaller utility for examining and tuning your ethernet-based
 network interface
endef

define Package/ethtool/config
	config ETHTOOL_NETLINK
		depends on PACKAGE_ethtool
		bool "Enable netlink interface"
		default y

	config ETHTOOL_PRETTY_DUMP
		depends on PACKAGE_ethtool
		bool "Enable pretty printing"
		default n
endef

define Package/ethtool-tiny/config
	config ETHTOOL_NETLINK
		depends on PACKAGE_ethtool-tiny
		bool "Enable netlink interface"
		default n

	config ETHTOOL_PRETTY_DUMP
		depends on PACKAGE_ethtool-tiny
		bool "Enable pretty printing"
		default n
endef

ifeq ($(CONFIG_ETHTOOL_NETLINK),y)
CONFIGURE_ARGS += --enable-netlink
else
CONFIGURE_ARGS += --disable-netlink
endif

ifeq ($(CONFIG_ETHTOOL_PRETTY_DUMP),y)
CONFIGURE_ARGS += --enable-pretty-dump
else
CONFIGURE_ARGS += --disable-pretty-dump
endif


define Build/Patch
	$(if $(QUILT),rm -rf $(PKG_BUILD_DIR)/patches; mkdir -p $(PKG_BUILD_DIR)/patches)
	$(call PatchDir,$(PKG_BUILD_DIR),$(PATCH_DIR)/generic,generic/)
ifeq ($(BUILD_VARIANT),tiny)
	$(call PatchDir,$(PKG_BUILD_DIR),$(PATCH_DIR)/tiny,tiny/)
endif
	$(if $(QUILT),touch $(PKG_BUILD_DIR)/.quilt_used)
endef

define Quilt/Refresh/Package
	$(call Quilt/RefreshDir,$(PKG_BUILD_DIR),$(PATCH_DIR)/generic,generic/)
ifeq ($(BUILD_VARIANT),tiny)
	$(call Quilt/RefreshDir,$(PKG_BUILD_DIR),$(PATCH_DIR)/tiny,tiny/)
endif
endef

define Package/ethtool/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ethtool $(1)/usr/sbin
endef

define Package/ethtool-tiny/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ethtool $(1)/usr/sbin
endef

$(eval $(call BuildPackage,ethtool))
$(eval $(call BuildPackage,ethtool-tiny))
