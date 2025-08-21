include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=sodog-tlt
PKG_VERSION:=2025-07-31
PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=SOdog establishes multiple bidirectional byte streams and transfers data between them by Teltonika.
	DEPENDS:=+kmod-usb-serial +libubox +libuci +libtlt_uci +libubus +libpthread \
		 +libopenssl +@OPENSSL_WITH_DTLS +libtlt_termios +libboardjson +libgpiod
	FATTRS:=/usr/sbin/sodog::::cap_net_bind_service=ep
	USERID:=sodog=522:sodog=522
endef

define Package/$(PKG_NAME)/description
	SOdog establishes multiple bidirectional byte streams and transfers data between them by Teltonika.
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/rs_overip
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/etc/permtab.d $(1)/usr/share/acl.d $(1)/etc/uci-defaults/etc $(1)/etc/uci-defaults/7.14
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sodog $(1)/usr/sbin/sodog
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rs_overip.init $(1)/etc/init.d/rs_overip
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rs_overip.conf $(1)/etc/config/rs_overip
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rs_overip.json $(1)/usr/share/acl.d/rs_overip.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rs_overip.permtab $(1)/etc/permtab.d/rs_overip
	$(CP) $(PKG_BUILD_DIR)/files/defaults/23_migrate_overip $(1)/etc/uci-defaults/etc
	$(CP) $(PKG_BUILD_DIR)/files/defaults/7.14/99_overip_vuci_uploads $(1)/etc/uci-defaults/7.14
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
