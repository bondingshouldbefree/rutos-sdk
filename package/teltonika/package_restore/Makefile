#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=package_restore
PKG_VERSION:=2025-07-31
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=3.13
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/package_restore
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Auto package restore
	DEPENDS:=+vuci-app-package-manager-api
	USERID:=opkg=624:opkg=624
endef

define Package/package_restore/conffiles
/etc/config/package_restore
endef



define Package/package_restore/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/package_restore.lua $(1)/sbin/package_restore.lua

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/package_restore.init $(1)/etc/init.d/package_restore

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/package_restore.config $(1)/etc/config/package_restore
	
	$(INSTALL_DIR) $(1)/etc/permtab.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/package_restore.permtab $(1)/etc/permtab.d/package_restore

endef

$(eval $(call BuildPackage,package_restore))
