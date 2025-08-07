include $(TOPDIR)/rules.mk

PKG_NAME:=modem_control
PKG_VERSION:=2025-07-02
PKG_SOURCE_VERSION:=7.16
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Modem control through serial interface
	DEPENDS:=+kmod-usb-serial +libubox +libuci +libtlt_uci +libubus +libpthread \
		  +libgsm +libmctl +libtlt_termios +libboardjson +libmnfinfo
	USERID:=modem_control=504:modem_control=504
endef

define Package/$(PKG_NAME)/description
	Modem control through serial interface
endef


define Package/$(PKG_NAME)/conffiles
/etc/config/rs_modem
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_control $(1)/usr/sbin/modem_control
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rs_modem.init $(1)/etc/init.d/rs_modem
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rs_modem.conf $(1)/etc/config/rs_modem
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rs_modem.permtab $(1)/etc/permtab.d/rs_modem
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
