#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=modbus_client
PKG_VERSION:=2025-07-31
PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed
TARGET_CFLAGS += "-DCACHE_HASH=\\\"$(PKG_SOURCE_VERSION)\\\""
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=MODBUS TCP/Serial client daemon by Teltonika
	DEPENDS:=+libuci +libtlt_uci +libtlt_termios +libsqlite3 +libmodbus +IO_SUPPORT:iomand \
		 +MOBILE_SUPPORT:libgsm +libparam +libmosquitto +libtlt_smtp +libcurl +libtag
	USERID:=modbus_client=577:modbus_client=577
endef

define Package/$(PKG_NAME)/description
	MODBUS TCP/Serial client designed for reading/writing data from MODBUS servers and storing read data in local database.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/permtab.d $(1)/etc/init.d $(1)/usr/sbin $(1)/usr/lib 
	$(INSTALL_DIR) $(1)/usr/lib/rpcd
	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.17

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modbus_client $(1)/usr/sbin/modbus_client
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/modbus_client.init $(1)/etc/init.d/modbus_client
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/modbus_client.conf $(1)/etc/config/modbus_client
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbus_client.permtab $(1)/etc/permtab.d/modbus_client
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbus_client.json $(1)/usr/share/acl.d/modbus_client.json
	$(CP) $(PKG_BUILD_DIR)/libalarms.so $(1)/usr/lib/libalarms.so
	$(CP) $(PKG_BUILD_DIR)/modbus_client.so $(1)/usr/lib/rpcd/modbus_client.so
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/migrations/7.17/01_modbus_client_move_flash_db $(1)/etc/uci-defaults/7.17/01_modbus_client_move_flash_db
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh

	/etc/init.d/rpcd reload

	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0
	. /lib/data_sender/libdata_sender.sh
	ds_find_plugin modbus && /etc/init.d/data_sender restart

	exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh

	foreach_server() {
		config_foreach foreach_alarm "alarm_$$1"
	}

	foreach_alarm() {
		config_get device_files "$$1" device_files "1"
		for opt in ca_file cert_file key_file ; do
			config_get value "$$1" "$$opt" ""
			[ "$$device_files" = 0 ] && [ -n "$$value" ] && rm -f "$$value"
		done
	}

	config_load modbus_client
	config_foreach foreach_server tcp_server
	config_foreach foreach_server rtu_server

	config_get db_path "main" "db_path" "/var/run/modbus_client/modbus.db"
	if [ -f "$$db_path" ]; then
		rm -f "$$db_path"
	fi

	exit 0
endef

define Package/$(PKG_NAME)/postrm
	#!/bin/sh
	/etc/init.d/rpcd reload
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
