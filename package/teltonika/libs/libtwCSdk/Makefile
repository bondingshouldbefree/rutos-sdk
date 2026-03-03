#
# Copyright (C) 2006-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libtwCSdk
PKG_VERSION:=2026-02-11
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.9
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-3p-closed

include $(INCLUDE_DIR)/package.mk


CMAKE_OPTIONS += -DTHINGWORX_CSDK_OPENSSL_INCLUDE_DIR=$(STAGING_DIR)/usr/include/openssl

define Package/libtwCSdk
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=ThingWorx C SDK Library.
	DEPENDS:=+libopenssl +libpthread +zlib
endef

define Package/libtwCSdk/description
	A simple library to enable ThingWorx on the device.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include/thingworx
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/* $(1)/usr/lib/
endef


define Package/libtwCSdk/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libtwCSdk.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libtwCSdk))
