include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=mqtt-modbus-gateway
PKG_VERSION:=2025-07-02
PKG_SOURCE_VERSION:=7.16
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/mqtt-modbus-gateway
	SECTION:=net
	CATEGORY:=Network
	TITLE:=MQTT Modbus Gateway
	DEPENDS:=+libmosquitto +libmodbus +libmnfinfo +libtlt_uci +libtlt_termios +libuci +libubox +libubus +libblobmsg-json +libjson-c
	USERID:=mqtt_modbus_gateway=515:mqtt_modbus_gateway=515
endef

define Package/mqtt-modbus-gateway/description
	MQTT-Modbus Gateway is a service meant to read/write MODBUS TCP/RTU servers via MQTT messages.
endef

define Package/mqtt-modbus-gateway/conffiles
/etc/config/modbusgateway
endef


define Build/Test
	test_modbusgateway.c
	test_parse_mqtt_request.c
	test_validate_request_parameters.c
	test_config_utils.c
endef

define Package/mqtt-modbus-gateway/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/permtab.d $(1)/usr/sbin $(1)/usr/share/acl.d $(1)/etc/uci-defaults/7.14/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modbusgateway $(1)/usr/sbin/modbusgateway
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/modbusgateway.init $(1)/etc/init.d/modbusgateway
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/modbusgateway.conf $(1)/etc/config/modbusgateway
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbusgateway.json $(1)/usr/share/acl.d/modbusgateway.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/modbusgateway.permtab $(1)/etc/permtab.d/modbusgateway
	$(CP) $(PKG_BUILD_DIR)/files/migrations/7.14/99_modbusgateway_vuci_uploads $(1)/etc/uci-defaults/7.14
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	. /lib/functions.sh
	config_load modbusgateway
	config_get device_files gateway device_files "1"
	for opt in cafile certfile keyfile ; do
		config_get value gateway "$$opt" ""
		[ "$$device_files" = 0 ] && [ -n "$$value" ] && rm -f "$$value"
	done
	exit 0
endef

$(eval $(call BuildPackage,mqtt-modbus-gateway))
