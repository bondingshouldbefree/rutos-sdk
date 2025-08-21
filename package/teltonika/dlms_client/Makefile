include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=dlms_client
PKG_VERSION:=2025-07-31

PKG_SOURCE_VERSION:=fa855d2e82db1a7d27c419d09ed7a11fe86b86f0
PKG_SOURCE=GuruxDLMS.c-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/Gurux/GuruxDLMS.c/tar.gz/$(PKG_SOURCE_VERSION)?
PKG_HASH:=c28b608cb7b3f03c4f1007c1be4ed514d3b0020b748df39106059373736f8895

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=DLMS Client for COSEM device monitoring
	DEPENDS:=+libsqlite3 +libubus +libubox +libuci +libtlt_uci +libtlt_termios +libtlt-logger +libpthread \
		+libdlms +libcfgx
endef

define Package/$(PKG_NAME)/description
	DLMS client designed for reading data from COSEM devices and storing read data in local database.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/sbin $(1)/usr/lib/rpcd $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/dlms_client.conf $(1)/etc/config/dlms_client
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/dlms_client.init $(1)/etc/init.d/dlms_client
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dlms_client $(1)/usr/sbin/dlms_client
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dlms_scan $(1)/usr/sbin/dlms_scan
	$(CP) $(PKG_BUILD_DIR)/dlms_client.so $(1)/usr/lib/rpcd/dlms_client.so
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/dlms_client.json $(1)/usr/share/acl.d/dlms_client.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/dlms_client.permtab $(1)/etc/permtab.d/dlms_client
endef

define Build/Test
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh

	/etc/init.d/rpcd reload

	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0

	. /lib/data_sender/libdata_sender.sh

	ds_find_plugin dlms && /etc/init.d/data_sender restart

	exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh
	rm -f /var/run/dlms_client/dlms.db
endef

define Package/$(PKG_NAME)/postrm
	#!/bin/sh
	/etc/init.d/rpcd reload
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
