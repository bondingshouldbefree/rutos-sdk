
#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=event-juggler

PKG_SOURCE_VERSION:=1.4
PKG_LICENSE:=Teltonika-closed

PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/event-juggler
	SECTION:=base
	CATEGORY:=Base system
	MENU:=1
	TITLE:=Event juggler package
	USERID:=juggler=516:juggler=516
	USER_GROUPS:=juggler:gsm profiler rms network wireless
	DEPENDS:=+libubox +libubus +libuci +libtlt-logger +libblobmsg-json +libparam \
			+libcfg +libcurl +liblua +libmosquitto +libtlt_smtp +libtlt_uci +libapi \
			+PACKAGE_EVENT_JUGGLER_EVENT_GSM:liburc \
			+PACKAGE_EVENT_JUGGLER_ACTION_MODEM:libmctl \
			+PACKAGE_EVENT_JUGGLER_EVENT_IO:iomand \
			+PACKAGE_EVENT_JUGGLER_ACTION_OUT:iomand \
			+PACKAGE_EVENT_JUGGLER_EVENT_GPS:libgps \
			+PACKAGE_EVENT_JUGGLER_CONDITION_GPS:libgps \
			+PACKAGE_EVENT_JUGGLER_CONDITION_IO:iomand \
			+PACKAGE_EVENT_JUGGLER_ACTION_SHUTDOWN:libgpiod \
			+CONFIG_MOBILE_SUPPORT:libgsm
endef

define Package/event-juggler/config
	source "$(SOURCE)/Config.in"
endef

define Package/event-juggler/conffiles
/etc/config/event_juggler
endef

CONFIGURE_ARGS += \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_DEBUG),--enable-debug) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_IO),--enable-event_io) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_QUOTA),--enable-event_quota) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_GPS),--enable-event_gps) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_GSM),--enable-event_gsm) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_ASTRO_TIME),--enable-event_astro_time) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_BOOT),--enable-event_boot) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_TIME),--enable-event_time) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_HOTSPOT),--enable-event_hotspot) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_EVENT_DUMMY),--enable-event_dummy) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_OUT),--enable-action_out) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_WIFI),--enable-action_wifi) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_RMS),--enable-action_rms) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_SHUTDOWN),--enable-action_shutdown) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_EXEC),--enable-action_exec) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_MODEM),--enable-action_modem) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_LUA),--enable-action_lua) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_SIM_SWITCH),--enable-action_sim_switch) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_HTTP),--enable-action_http) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_SMS),--enable-action_sms) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_CALL),--enable-action_call) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_SMTP),--enable-action_smtp) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_MQTT),--enable-action_mqtt) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_CONNECTION),--enable-action_connection) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_CONDITION_IO),--enable-cond_io) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_CONDITION_GPS),--enable-cond_gps) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_CONDITION_LUA),--enable-cond_lua) \
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_CONDITION_FILTER),--enable-cond_filter) \
	--with-jglibdir=/usr/local/usr/lib/event_juggler


define InstallLuaActionExamples
	$(INSTALL_DIR) $(1)/etc/event_juggler
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lua_examples/action.lua $(1)/etc/event_juggler/
endef

define InstallLuaConditionExamples
	$(INSTALL_DIR) $(1)/etc/event_juggler
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lua_examples/condition.lua $(1)/etc/event_juggler/
endef

define Package/event-juggler/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ $(1)/usr/sbin/ \
		$(1)/etc/uci-defaults/7.13 $(1)/lib/troubleshoot $(1)/usr/share/acl.d/

	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/event_juggler $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/event_juggler.init $(1)/etc/init.d/event_juggler
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/event_juggler_migration.sh \
			$(1)/etc/uci-defaults/7.13/99-event_juggler
	$(if $(CONFIG_POWER_CONTROL_SUPPORT),\
			$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/event_juggler_atrm50.conf $(1)/etc/config/event_juggler;,\
			$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/event_juggler.conf $(1)/etc/config/event_juggler;)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/event_juggler_troubleshoot.sh \
			$(1)/lib/troubleshoot/event_juggler.sh
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/event_juggler.json $(1)/usr/share/acl.d/

	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_ACTION_LUA),$(call InstallLuaActionExamples,$(1)))
	$(if $(CONFIG_PACKAGE_EVENT_JUGGLER_CONDITION_LUA),$(call InstallLuaConditionExamples,$(1)))
endef

$(eval $(call BuildPackage,event-juggler))
