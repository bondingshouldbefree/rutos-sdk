include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=opcua_server
PKG_VERSION:=2025-07-02
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed
PKG_SOURCE_VERSION:=7.16

include $(INCLUDE_DIR)/package.mk

define Package/opcua_server
	SECTION:=net
	CATEGORY:=Network
	TITLE:=OPC UA server
	DEPENDS:=+open62541 +libmnfinfo +libuci +libtlt_uci +libubus +libboardjson +GPS_SUPPORT:libgps +MOBILE_SUPPORT:libgsm +IO_SUPPORT:iomand
	FATTRS:=/usr/bin/opcua_server::::cap_net_bind_service=ep
	USERID:=opcua_server=506:opcua_server=506
endef

define Package/opcua_server/description
	OPC UA server designed for OPC UA clients to read device data.
endef

define Package/opcua_server/conffiles
/etc/config/opcua_server
endef


define Package/opcua_server/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/permtab.d $(1)/usr/bin $(1)/usr/share/acl.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/opcua_server $(1)/usr/bin/opcua_server
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/opcua_server.init $(1)/etc/init.d/opcua_server
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/opcua_server.conf $(1)/etc/config/opcua_server
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/opcua_server.json $(1)/usr/share/acl.d/opcua_server.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/opcua_server.permtab $(1)/etc/permtab.d/opcua_server
endef

define Build/Test
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh
	. "$${IPKG_INSTROOT}/lib/functions.sh"
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	if [ -n "$$(find /etc/vuci-uploads -maxdepth 1 -name 'cbid.opcua_server.*')" ]; then
		chown opcua_server:opcua_server /etc/vuci-uploads/cbid.opcua_server.*
		chmod 0660 /etc/vuci-uploads/cbid.opcua_server.*
	fi
	exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	. /lib/functions.sh
	config_load opcua_server
	config_get key opcua_server key ""
	[ -n "$$key" ] && rm -f "$$key"
	config_get certificate opcua_server certificate ""
	[ -n "$$certificate" ] && rm -f "$$certificate"
	config_list_foreach opcua_server tcl rm
	exit 0
endef

$(eval $(call BuildPackage,opcua_server))
