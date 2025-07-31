#
# Copyright (C) 2023 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=mobifd

PKG_SOURCE_VERSION:=7.16.2

PKG_LICENSE:=Teltonika-closed

PKG_CONFIG_DEPENDS += \
	CONFIG_USE_PROCD \
	CONFIG_USE_OPENRC

include $(INCLUDE_DIR)/package.mk

define Package/mobifd
	MENU:=1
	SECTION:=net
	CATEGORY:=Network
	TITLE:=GSM Modem manager
	DEPENDS:= +libubus +libubox +libgsm +liburc +libuci +libtlt_uci +libtlt-logger \
			+libsqlite3 +libmnfinfo +libboardjson
	USERID:=gsm=509:gsm=509
endef

define Package/mobifd/description
	Daemon for managing operator connection establishment and data connection handling.
endef

define Package/mobifd/config
	source "$(SOURCE)/Config.in"
endef

define Package/mobifd/conffiles
/etc/config/operctl
endef

TARGET_CFLAGS += $(if $(CONFIG_MOBIFD_DEBUG),-DMOBIFD_DEBUG)


define Package/mobifd/install
	$(INSTALL_DIR) $(1)/usr/share/gsm/ $(1)/lib/config.d $(1)/usr/libexec/rpcd/ $(1)/usr/share/acl.d/ $(1)/etc/permtab.d
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/config/ $(1)/etc/init.d/ $(1)/etc/uci-defaults/etc $(1)/lib/functions
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mobifd $(1)/usr/sbin/mobifd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/rpcd/rpc-ping $(1)/usr/libexec/rpcd/rpc-ping
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/mobile.sh $(1)/lib/functions/mobile.sh
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/mobifd.init $(1)/etc/init.d/mobifd
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/mobifd.conf $(1)/etc/config/operctl
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/config.d/400-gzip-apn-db $(1)/lib/config.d/400-gzip-apn-db
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/mobifd.json $(1)/usr/share/acl.d/mobifd.json
	$(CP) $(PKG_BUILD_DIR)/files/defaults/02_simcard $(1)/etc/uci-defaults/etc/02_simcard
	$(CP) $(PKG_BUILD_DIR)/files/defaults/106_operctl $(1)/etc/uci-defaults/etc/106_operctl
	$(CP) $(PKG_BUILD_DIR)/files/defaults/107_network_service_mode $(1)/etc/uci-defaults/etc/107_network_service_mode
	$(CP) $(PKG_BUILD_DIR)/files/hotplug/remove_operlist.hotplug $(1)/usr/share/gsm/5-remove-operlist
	$(CP) $(PKG_BUILD_DIR)/files/permtab.d/mobifd $(1)/etc/permtab.d/mobifd

	$(if $(CONFIG_USE_OPENRC),\
		$(OPENRC_INSTALL) boot mobifd ./mobifd.openrc $(1))
endef

define Build/Test
endef

$(eval $(call BuildPackage,mobifd))

