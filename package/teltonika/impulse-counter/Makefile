include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=impulse-counter
PKG_VERSION:=2025-07-31
PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed


include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Impulse counter
	DEPENDS:=+libubox +libuci +libtlt_uci +libubus +libblobmsg-json +lsqlite3 +libtlt-logger +iomand
	USERID:=icounter=592:icounter=592
endef

define Package/$(PKG_NAME)/description
	Impulse counter application is used to count impulse signals and store them in a database.
endef


define Package/$(PKG_NAME)/conffiles
/etc/config/impulse_counter
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/impulse_counter $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/impulse_counter.init $(1)/etc/init.d/impulse_counter
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/impulse_counter.conf $(1)/etc/config/impulse_counter
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/impulse_counter.json $(1)/usr/share/acl.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/impulse_counter.permtab $(1)/etc/permtab.d/impulse_counter
endef

define Package/$(PKG_NAME)/postinst
	#!/bin/sh

	/etc/init.d/rpcd reload

	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	[ -e /lib/data_sender/libdata_sender.sh ] || exit 0

	. /lib/data_sender/libdata_sender.sh

	ds_find_plugin impulse_counter && /etc/init.d/data_sender restart

	exit 0
endef

define Package/$(PKG_NAME)/prerm
	#!/bin/sh

	rm -f /tmp/impulse_counter.db
endef

define Package/$(PKG_NAME)/postrm
	#!/bin/sh
	/etc/init.d/rpcd reload
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
