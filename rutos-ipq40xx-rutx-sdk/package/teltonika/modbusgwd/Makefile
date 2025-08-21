include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=modbusgwd
PKG_VERSION:=2025-07-31

PKG_SOURCE_VERSION:=7.17
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/modbusgwd
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Modbus RTU to TCP gateway by Teltonika
	DEPENDS:=+kmod-usb-serial +libuci +libtlt_uci +libtlt_termios +libubus +libubox +libtlt-logger
	FATTRS:=/usr/sbin/modbusgwd::::cap_net_bind_service=ep
endef

define Package/modbusgwd/description
	MODBUS RTU to TCP gateway designed to receive MODBUS TCP message, convert to MODBUS RTU and send it to MODBUS RTU device.
endef

define Package/modbusgwd/conffiles
/etc/config/rs_modbus
endef



define Package/modbusgwd/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config $(1)/usr/share/acl.d $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modbusgwd $(1)/usr/sbin/modbusgwd
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rs_modbus.conf $(1)/etc/config/rs_modbus
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rs_modbus.init $(1)/etc/init.d/rs_modbus
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rs_modbus.json $(1)/usr/share/acl.d/rs_modbus.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rs_modbus.permtab $(1)/etc/permtab.d/rs_modbus
endef

$(eval $(call BuildPackage,modbusgwd))
