include $(TOPDIR)/rules.mk

PKG_NAME:=serial
PKG_VERSION:=2024-11-21
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=General serial device package.
endef

define Package/$(PKG_NAME)/description
	General serial device package. Contains files which don't belong to any specific serial service.
endef


Build/Compile = $(Build/Compile/Default)


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/hotplug.d/tty $(1)/lib/functions $(1)/usr/bin

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rs_console.init $(1)/etc/init.d/rs_console
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rs_console.config $(1)/etc/config/rs_console
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rs_console $(1)/usr/bin/rs_console

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/01-serial-symlink.sh $(1)/etc/hotplug.d/tty/01-serial-symlink.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/serial.sh $(1)/lib/functions/serial.sh
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
