#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=iec60870_client
PKG_LICENSE:=Teltonika-closed
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=7.21

include $(INCLUDE_DIR)/package.mk

define Package/iec60870_client
	SECTION:=net
	CATEGORY:=Network
	TITLE:=IEC 60870-5 Client by Teltonika
	DEPENDS:=+libubus +libuci +libsqlite3 +lib60870 +libtlt_uci +libubox +libcfgx +libtlt-logger +libblobmsg-json +rpcd
	USERID:=iec60870_client=651:iec60870_client=651
endef

define Package/iec60870_client/description
	IEC 60870-5 client service for data acquisition
endef

define Package/iec60870_client/conffiles
/etc/config/iec60870_client
endef


define Package/iec60870_client/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iec60870_client $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/iec60870_client.init $(1)/etc/init.d/iec60870_client

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/iec60870_client.conf $(1)/etc/config/iec60870_client
	$(INSTALL_DIR) $(1)/usr/lib/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/iec60870_client_rpc.so $(1)/usr/lib/rpcd/
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iec60870_client.permtab $(1)/etc/permtab.d/iec60870_client
	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/iec60870_client.json $(1)/usr/share/acl.d/iec60870_client.json
endef

define Package/iec60870_client/postinst
	#!/bin/sh
	/etc/init.d/rpcd reload

	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0

	. /lib/data_sender/libdata_sender.sh

	ds_find_plugin iec60870 && /etc/init.d/data_sender restart

	exit 0
endef

define Package/iec60870_client/postrm
	#!/bin/sh
	/etc/init.d/rpcd reload
	rm -f /var/run/iec60870_client/iec60870_client.db
endef

$(eval $(call BuildPackage,iec60870_client))

