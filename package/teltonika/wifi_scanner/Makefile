#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=wifi_scanner
PKG_VERSION:=2025-05-14
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.14
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=$(PKG_NAME)
	DEPENDS:=+libubox +libtlt-logger +libubus +lsqlite3
	USERID:=wifi_scanner:wifi_scanner
endef

define Package/$(PKG_NAME)/description
	Wireless devices beacon and probe packet analyzer
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/wifi_scanner
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config $(1)/etc/init.d $(1)/usr/share/acl.d/ $(1)/etc/permtab.d

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/wifi_scanner.json $(1)/usr/share/acl.d/wifi_scanner.json
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/files/wifi_scanner.conf $(1)/etc/config/wifi_scanner
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wifi_scanner.init $(1)/etc/init.d/wifi_scanner
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/wifi_scanner $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/wifi_scanner.permtab $(1)/etc/permtab.d/wifi_scanner
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh

	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0

	. /lib/data_sender/libdata_sender.sh

	ds_find_plugin wifiscan && /etc/init.d/data_sender restart
	
	exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
