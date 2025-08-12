include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=data-sender
PKG_RELEASE=1

PKG_SOURCE_VERSION:=1.20

PKG_FIXUP:=autoreconf

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/data-sender/Default
  SECTION:=net
  CATEGORY:=Network
endef

define Package/data-sender-pkg/Default
  PKG_ROUTER:=$(call device_shortname)
endef

define Package/data-sender
  $(call Package/data-sender/Default)
  DEPENDS:=+libuci +libtlt-logger +libubox +libblobmsg-json +libubus +libjson-c $(DS_DEPS)
  TITLE:=Data sender daemon by Teltonika
  MENU:=1
  USERID:=ds=530:ds=530
endef

define Package/data-sender/config
  source "$(SOURCE)/Config.in"
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/data_sender
endef


define RegisterPlugin
  define Package/data-sender-mod-$(1)
	$(call Package/data-sender/Default)
	DEPENDS:=data-sender $(2)
	TITLE:=$(3)

	ifeq ($(CONFIG_PACKAGE_data-sender-mod-$(1)),y)
		DS_DEPS+=$(2)
	endif
  endef

  CONFIGURE_ARGS += $(if $(CONFIG_PACKAGE_data-sender-mod-$(1)), --with-mod-$(1)=$(CONFIG_PACKAGE_data-sender-mod-$(1)))
endef

$(eval $(call RegisterPlugin,bluetooth,+libsqlite3,Input plugin for bluetooth data gathering))
$(eval $(call RegisterPlugin,modbus,+libsqlite3,Input plugin for modbus data gathering))
$(eval $(call RegisterPlugin,modbus-alarm,+libsqlite3,Input plugin for modbus alarm gathering))
$(eval $(call RegisterPlugin,dnp3,+libsqlite3,Input plugin for DNP3 data gathering))
$(eval $(call RegisterPlugin,opcua,+libsqlite3,Input plugin for OPC UA data gathering))
$(eval $(call RegisterPlugin,impulse_counter,+libsqlite3,Input plugin for impulse counter data gathering))
$(eval $(call RegisterPlugin,mbus,+libsqlite3,Input plugin for M-Bus data gathering))
$(eval $(call RegisterPlugin,wifiscan,+libsqlite3,Input plugin for wifi scaner data gathering))
$(eval $(call RegisterPlugin,mnfinfo,+libmnfinfo,Input plugin for manufacturer information))
$(eval $(call RegisterPlugin,gsm,+libgsm,Input plugin for gsm information))
$(eval $(call RegisterPlugin,sms-in,+libgsm +liburc,Input plugin for SMS input))
$(eval $(call RegisterPlugin,mdcollect,+libgsm +libmdcollect,Input plugin for data usage information))
$(eval $(call RegisterPlugin,gps,+libgps,Input plugin for GPS data gathering))
$(eval $(call RegisterPlugin,chilli,+libuci +libtltchilli,Input plugin for CoovaChilli Hotspot data gathering))
$(eval $(call RegisterPlugin,io,+iomand,Input plugin for Input/Output data gathering))
$(eval $(call RegisterPlugin,format-custom,+libblobmsg-json,Format plugin for data concatenation))
$(eval $(call RegisterPlugin,format-csv,+libblobmsg-json,Format plugin for CSV formating))
$(eval $(call RegisterPlugin,format-none,+libblobmsg-json,Format plugin for plain serialization))
$(eval $(call RegisterPlugin,http,+libcurl,Output plugin for sending data over http))
$(eval $(call RegisterPlugin,mqtt-out,+libmosquitto,Output plugin for sending data over MQTT))
$(eval $(call RegisterPlugin,socket,,Output plugin for sending data over a UNIX socket))
$(eval $(call RegisterPlugin,sms-out,+libgsm,Output plugin for sending data over SMS))
$(eval $(call RegisterPlugin,smtp,+libcurl +libuci +@LIBCURL_SMTP,Output plugin for sending data over SMTP))
$(eval $(call RegisterPlugin,nflog,+libnetfilter-log +libxtables,Input plugin for NFLOG))
$(eval $(call RegisterPlugin,eventlog,,Input plugin for events log))
$(eval $(call RegisterPlugin,lua-in,+liblua,Input plugin for custom scripts))
$(eval $(call RegisterPlugin,lua-out,+liblua,Output plugin for custom scripts))
$(eval $(call RegisterPlugin,ftp,+libcurl,Output plugin for sending data over FTP))
$(eval $(call RegisterPlugin,base,,Base input plugin))
$(eval $(call RegisterPlugin,lua_format,+liblua,Output plugin for custom formating))
$(eval $(call RegisterPlugin,telegram,+libcurl +libopenssl,Output plugin for sending data over Telegram))
$(eval $(call RegisterPlugin,ubus,,Output plugin for sending data over UBUS))
$(eval $(call RegisterPlugin,file,,Output plugin for writing data to a file))
$(eval $(call RegisterPlugin,dlms,+libsqlite3,Input plugin for M-Bus data gathering))
$(eval $(call RegisterPlugin,mqtt-in,+libmosquitto,Input plugin for subscribing MQTT data))
$(eval $(call RegisterPlugin,lua_filter,+liblua,Filter plugin for LUA scripts))
$(eval $(call RegisterPlugin,cmp,,Filter plugin for data comparison))
$(eval $(call RegisterPlugin,stdin,,Input plugin for reading data from stdin))
$(eval $(call RegisterPlugin,stdout,,Output plugin for writing data to stdout))
$(eval $(call RegisterPlugin,syslog,,Input plugin for syslog data gathering))

CONFIGURE_ARGS += \
		--with-max_instances=$(CONFIG_PACKAGE_DATA_SENDER_COLLECTIONS) \
		--with-max_inputs=$(CONFIG_PACKAGE_DATA_SENDER_INPUTS) \
		$(if $(CONFIG_PACKAGE_DATA_SENDER_BASE64),--enable-base64) \
		$(if $(CONFIG_PACKAGE_DATA_SENDER_SCHEDULER),--enable-scheduler) \
		$(if $(CONFIG_PACKAGE_DATA_SENDER_DEBUG),--enable-debug)


define Package/data-sender/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/sbin \
			$(1)/lib/troubleshoot $(1)/lib/data_sender $(1)/usr/share/acl.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/data_sender.init $(1)/etc/init.d/data_sender
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/data_sender.conf $(1)/etc/config/data_sender
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/datasender $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/data_sender_troubleshoot.sh \
			$(1)/lib/troubleshoot/data_sender.sh
	$(CP) $(PKG_BUILD_DIR)/files/libdata_sender.sh $(1)/lib/data_sender/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/data_sender.json $(1)/usr/share/acl.d/
endef

define BuildPlugin
  define Package/data-sender-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/data_sender $$(1)/usr/share/acl.d

	if [ "$(CONFIG_PACKAGE_data-sender-mod-$(1))" = "m" ]; then \
	for m in $(2); do \
		$(CP) $(PKG_INSTALL_DIR)/usr/lib/data_sender/ds_$$$$$$$${m}.so $$(1)/usr/lib/data_sender/ ; \
	done; \
	fi
	if [ -n "$(3)" ] && [ -d "$(PKG_BUILD_DIR)/files/modules/$(3)" ]; then \
		$(INSTALL_DIR) $$(1)/etc/data_sender/modules/$(3) ; \
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/modules/$(3)/* $$(1)/etc/data_sender/modules/$(3)/ ; \
	fi
	if [ -e "$(PKG_BUILD_DIR)/files/acl.d/$(1).json" ]; then \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/$(1).json $$(1)/usr/share/acl.d/ds_$(1).json; \
	fi
  endef

ifeq ($$(CONFIG_PACKAGE_data-sender-mod-$(1)),m)
  ifeq ($(wildcard $(PKG_BUILD_DIR)/files/acl.d/$(1).json),)
  define Package/data-sender-mod-$(1)/postinst
#!/bin/sh

[ -z "$$$${IPKG_INSTROOT}" ] || exit 0

#Relaod ubusd acl rules
pid=$$$$(pidof ubusd)
[ -z "$$$$pid" ] || kill -HUP $$$$pid
  endef
  endif
endif
  define Package/data-sender-mod-$(1)/postrm
	#!/bin/sh
	
	[ -z "$$$${IPKG_INSTROOT}" ] || exit 0

	. /lib/data_sender/libdata_sender.sh 
	ds_remove_plugin_cfg $(1)

	if [ -f "/tmp/data_sender/plugin_data.json" ]; then
		rm -f "/tmp/data_sender/plugin_data.json"
	fi

	exit 0
  endef
  $$(eval $$(call BuildPackage,data-sender-mod-$(1)))
endef

$(eval $(call BuildPlugin,bluetooth,input_bluetooth))
$(eval $(call BuildPlugin,modbus,input_modbus))
$(eval $(call BuildPlugin,modbus-alarm,input_modbus_alarm))
$(eval $(call BuildPlugin,dnp3,input_dnp3))
$(eval $(call BuildPlugin,opcua,input_opcua))
$(eval $(call BuildPlugin,impulse_counter,input_impulse_counter))
$(eval $(call BuildPlugin,mbus,input_mbus))
$(eval $(call BuildPlugin,wifiscan,input_wifiscan))
$(eval $(call BuildPlugin,mnfinfo,input_mnfinfo))
$(eval $(call BuildPlugin,gsm,input_gsm))
$(eval $(call BuildPlugin,sms-in,input_sms))
$(eval $(call BuildPlugin,mdcollect,input_mdcollect))
$(eval $(call BuildPlugin,gps,input_gps))
$(eval $(call BuildPlugin,chilli,input_chilli))
$(eval $(call BuildPlugin,io,input_io))
$(eval $(call BuildPlugin,format-custom,format_custom))
$(eval $(call BuildPlugin,format-csv,format_csv))
$(eval $(call BuildPlugin,format-none,format_none))
$(eval $(call BuildPlugin,http,output_http))
$(eval $(call BuildPlugin,mqtt-out,output_mqtt))
$(eval $(call BuildPlugin,socket,output_socket))
$(eval $(call BuildPlugin,sms-out,output_sms))
$(eval $(call BuildPlugin,smtp,output_smtp))
$(eval $(call BuildPlugin,nflog,input_nflog))
$(eval $(call BuildPlugin,eventlog,input_eventlog))
$(eval $(call BuildPlugin,base,input_base))
$(eval $(call BuildPlugin,lua-in,input_lua,input/lua))
$(eval $(call BuildPlugin,lua-out,output_lua,output/lua))
$(eval $(call BuildPlugin,lua_format,format_lua,format/lua))
$(eval $(call BuildPlugin,telegram,output_telegram))
$(eval $(call BuildPlugin,ftp,output_ftp))
$(eval $(call BuildPlugin,ubus,output_ubus))
$(eval $(call BuildPlugin,file,output_file))
$(eval $(call BuildPlugin,dlms,input_dlms))
$(eval $(call BuildPlugin,mqtt-in,input_mqtt))
$(eval $(call BuildPlugin,lua_filter,filter_lua))
$(eval $(call BuildPlugin,cmp,filter_cmp))
$(eval $(call BuildPlugin,stdin,input_stdin))
$(eval $(call BuildPlugin,stdout,output_stdout))
$(eval $(call BuildPlugin,syslog,input_syslog))
$(eval $(call BuildPackage,data-sender))
