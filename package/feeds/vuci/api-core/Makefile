#
# Copyright (C) 2022 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=api-core
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-nda-source
PKG_BUILD_DEPENDS:=VUCI_MINIFY_LUA:luasrcdiet/host

include $(INCLUDE_DIR)/package.mk
include ../utils.mk

define Package/api-core
  SECTION:=webui
  CATEGORY:=WebUI
  TITLE:= API core
  DEPENDS:=+rpcd +WIFI_SUPPORT:rpcd-mod-iwinfo +rpcd-mod-file +rpcd-mod-rpcsys +uhttpd \
		+uhttpd-mod-ubus +lua +libubox-lua +libubus-lua \
		+libuci-lua +liblua +luci-lib-jsonc +luci-lib-nixio \
		+luci-lib-ip +rpcd-mod-rrdns +uhttpd-mod-lua +lua_crypto +lua_extra_validators \
		+libubus +luasocket +lsqlite3 +lrexlib +rpcd-mod-mnfinfo +luasec +rpcd-mod-uci \
		+rpcd-mod-rc
endef

define Package/api-core/config
	source "$(SOURCE)/Config.in"
endef

define Package/api-core/description
	Provides core API functionality
endef

define Package/api-core/conffiles
/etc/config/vuci
endef



ifndef CONFIG_GPL_INCLUDE_WEB_SOURCES
ifeq ("$(wildcard $(PKG_BUILD_DIR)/files)","")
GPL_FILES_DIR := ./files
else
GPL_FILES_DIR := $(PKG_BUILD_DIR)/files
endif
else
GPL_FILES_DIR := ./files
endif

define install_closed_gpl
	$(INSTALL_DIR) -D $(PKG_GPL_BUILD_DIR)/files/sbin \
		$(PKG_GPL_BUILD_DIR)/files/bin \
		$(PKG_GPL_BUILD_DIR)/files/lib/config.d \
		$(PKG_GPL_BUILD_DIR)/files/usr/sbin \
		$(PKG_GPL_BUILD_DIR)/files/etc/init.d \
		$(PKG_GPL_BUILD_DIR)/files/etc/config \
		$(PKG_GPL_BUILD_DIR)/files/etc/uci-defaults \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/vuci/network \
		$(PKG_GPL_BUILD_DIR)/files/www/cgi-bin \
		$(PKG_GPL_BUILD_DIR)/files/etc/vuci-uploads \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/ubus/services \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/ubus/network \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/ubus/status \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/ubus/system \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/core \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/services \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/status \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/system \
		$(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/network

	$(CP) $(GPL_FILES_DIR)/etc/config/vuci $(PKG_GPL_BUILD_DIR)/files/etc/config
	$(CP) $(GPL_FILES_DIR)/bin/trigger_vuci_routes_reload $(PKG_GPL_BUILD_DIR)/files/bin
	$(CP) $(GPL_FILES_DIR)/etc/init.d/event_server.init $(PKG_GPL_BUILD_DIR)/files/etc/init.d
	$(CP) $(GPL_FILES_DIR)/sbin/event_server.lua $(PKG_GPL_BUILD_DIR)/files/sbin
	$(CP) $(GPL_FILES_DIR)/sbin/api.lua $(PKG_GPL_BUILD_DIR)/files/sbin
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/api/core/* $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/core
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/api/services/*.lua $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/services
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/api/network/*.lua $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api/network
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/api/*.lua $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/api
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/vuci/*.lua $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/vuci
	$(CP) $(GPL_FILES_DIR)/usr/lib/lua/vuci/network/* $(PKG_GPL_BUILD_DIR)/files/usr/lib/lua/vuci/network
	$(CP) $(GPL_FILES_DIR)/www/cgi-bin/subscribe.lua $(PKG_GPL_BUILD_DIR)/files/www/cgi-bin
	$(CP) $(GPL_FILES_DIR)/www/cgi-bin/sentry.lua $(PKG_GPL_BUILD_DIR)/files/www/cgi-bin
	$(CP) $(GPL_FILES_DIR)/www/cgi-bin/luci.lua $(PKG_GPL_BUILD_DIR)/files/www/cgi-bin
	$(CP) $(GPL_FILES_DIR)/www/cgi-bin/index.lua $(PKG_GPL_BUILD_DIR)/files/www/cgi-bin
	$(CP) $(GPL_FILES_DIR)/www/cgi-bin/api_dispatcher.lua $(PKG_GPL_BUILD_DIR)/files/www/cgi-bin

	$(CP) $(PKG_BUILD_DIR)/vuci.so $(1)
endef



# GPL has no PKG_BUILD_DIR in api-core so we need to use ./files dir
define Package/api-core/install
	files_dir="./files"; \
	if [[ -d "$(PKG_BUILD_DIR)/files" ]]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_DIR) -D $(1)/www/cgi-bin \
				$(1)/bin \
				$(1)/sbin \
				$(1)/lib/config.d \
				$(1)/usr/sbin \
				$(1)/usr/lib/lua/ubus \
				$(1)/usr/lib/lua/vuci/network \
				$(1)/usr/lib/lua/api/core \
				$(1)/usr/lib/lua/api/system \
				$(1)/usr/lib/lua/api/status \
				$(1)/usr/lib/lua/api/network \
				$(1)/usr/lib/lua/api/services \
				$(1)/usr/lib/lua/ubus/system \
				$(1)/usr/lib/lua/ubus/status \
				$(1)/usr/lib/lua/ubus/network \
				$(1)/usr/lib/lua/ubus/services \
				$(1)/etc/vuci-uploads ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/etc/config/vuci $(1)/etc/config/vuci ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/bin/trigger_vuci_routes_reload $(1)/bin/trigger_vuci_routes_reload ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/etc/init.d/event_server.init $(1)/etc/init.d/event_server ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/sbin/event_server.lua $(1)/sbin/event_server ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/sbin/api.lua $(1)/sbin/api ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/vuci/*.lua $(1)/usr/lib/lua/vuci ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/vuci/network/* $(1)/usr/lib/lua/vuci/network ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/www/cgi-bin/subscribe.lua $(1)/www/cgi-bin/subscribe.lua ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/www/cgi-bin/sentry.lua $(1)/www/cgi-bin/sentry ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/www/cgi-bin/luci.lua $(1)/www/cgi-bin/luci ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/www/cgi-bin/index.lua $(1)/www/cgi-bin/index ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/www/cgi-bin/api_dispatcher.lua $(1)/www/cgi-bin/api_dispatcher.lua ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/api/*.lua $(1)/usr/lib/lua/api ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/api/core/* $(1)/usr/lib/lua/api/core ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/api/services/* $(1)/usr/lib/lua/api/services ; \
	$(INSTALL_BIN) -D "$$$$files_dir"/usr/lib/lua/api/network/* $(1)/usr/lib/lua/api/network

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/vuci.so $(1)/usr/lib/lua

	# remove some core api files if none of these features are supported
	$(if $(or $(CONFIG_IO_SUPPORT),\
	     $(CONFIG_GPS_SUPPORT),\
	     $(CONFIG_MOBILE_UTILS_SUPPORT),\
	     $(CONFIG_SERIAL_SUPPORT),\
	     $(CONFIG_SNMP_SUPPORT)),,\
		$(RM) $(1)/usr/lib/lua/vuci/io.lua; \
	)
	$(if $(CONFIG_IO_MODBUS_SUPPORT),,\
		$(RM) $(1)/usr/lib/lua/vuci/modbus_utils.lua; \
	)
	$(if $(or $(CONFIG_SERIAL_SUPPORT),\
	     $(CONFIG_IO_MODBUS_SUPPORT),\
	     $(CONFIG_NTRIP_SUPPORT),\
	     $(CONFIG_MBUS),\
	     $(CONFIG_DNP3_SUPPORT),\
	     $(CONFIG_BACNET_SUPPORT)),,\
		$(RM) $(1)/usr/lib/lua/api/services/serial_status.lua; \
		$(RM) $(1)/usr/lib/lua/vuci/serial.lua; \
	)
endef

$(eval $(call BuildPackage,api-core))
