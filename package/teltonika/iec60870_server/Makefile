#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=iec60870_server
PKG_VERSION:=2025-12-09
PKG_SOURCE_VERSION:=7.21
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=IEC 60870-5 Server by Teltonika
	DEPENDS:=+libuci +libtlt_uci +libtlt-logger +lib60870 +libtlt_termios +libubus +libboardjson +libmnfinfo \
		+MOBILE_SUPPORT:libmdcollect +MOBILE_SUPPORT:libgsm +GPS_SUPPORT:libgps +IO_SUPPORT:iomand
	USERID:=iec60870_server=652:iec60870_server=652
	FATTRS:=/usr/bin/iec60870_server::::cap_net_bind_service=ep
endef

define Package/$(PKG_NAME)/description
	Server application implementation intended for router data provision and control using IEC 60870 protocol.
	Supports both 104 and 101 parts of specification.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/iec60870_server
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iec60870_server $(1)/usr/bin/iec60870_server

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/iec60870_server.init $(1)/etc/init.d/iec60870_server

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/iec60870_server.conf $(1)/etc/config/iec60870_server

	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iec60870_server.json $(1)/usr/share/acl.d/iec60870_server.json

	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iec60870_server.permtab $(1)/etc/permtab.d/iec60870_server
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

