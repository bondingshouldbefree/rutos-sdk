#
# Copyright (C) 2023 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=modbus_server
PKG_VERSION:=2025-07-02
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=7.16
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_LICENSE:=Teltonika-closed
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Modbus server daemon by Teltonika
	DEPENDS:=+libuci +libtlt_uci +libtlt_termios +libubus +libubox +libjson-c +libblobmsg-json +libmnfinfo +libmodbus +libboardjson \
		 +MOBILE_SUPPORT:libmdcollect +MOBILE_SUPPORT:libgsm +IO_SUPPORT:iomand +libtag
	FATTRS:=/usr/sbin/modbus_server::::cap_net_bind_service=ep
endef

define Package/$(PKG_NAME)/description
	MODBUS TCP/Serial server designed for MODBUS clients to read and write device data.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/modbus_server
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/permtab.d $(1)/usr/sbin $(1)/usr/share/acl.d $(1)/etc/uci-defaults/7.15/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modbus_server $(1)/usr/sbin/modbus_server
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/modbus_server.init $(1)/etc/init.d/modbus_server
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/modbus_server.conf $(1)/etc/config/modbus_server
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbus_server.json $(1)/usr/share/acl.d/modbus_server.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbus_server.permtab $(1)/etc/permtab.d/modbus_server
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/migrations/7.15/99_modbus_server_migrate_regfile $(1)/etc/uci-defaults/7.15/
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	. /lib/functions.sh
	config_load modbus_server
	config_get regfile modbus regfile ""
	[ -n "$$regfile" ] && rm -f "$$regfile"
	exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
