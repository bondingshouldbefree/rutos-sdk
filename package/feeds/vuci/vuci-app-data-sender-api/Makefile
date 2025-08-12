include $(TOPDIR)/rules.mk

APP_TITLE := VuCI API Support for Data Sender
CUSTOM_INSTALL= 1

include ../api.mk

define ModuleInstallLuaFile
	$(INSTALL_BIN) $(4)/usr/lib/lua/api/services/$(1)$(if $(2),/$(2)).lua $(3)/usr/lib/lua/api/services/$(1)$(if $(2),/$(2)).lua;
endef

define ModulePostinst
#!/bin/sh

[ -z "$(1)" ] || exit 0

lua -e 'ds_update = require "vuci.ds_update_list"; ds_update:update_list();'

exit 0
endef

# --- Main Package Install ---
define Package/$(PKG_NAME)/install
	files_dir="./files"; if [[ -d "$(PKG_BUILD_DIR)/files" ]]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_DIR) $(1)/usr/lib/lua/api/services; \
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d; \
	$(INSTALL_DIR) $(1)/usr/lib/lua/vuci; \
	$(INSTALL_BIN) $$$$files_dir/usr/lib/lua/vuci/ds_update_list.lua $(1)/usr/lib/lua/vuci/ds_update_list.lua; \
	$(CP) $$$$files_dir/usr/share/rpcd/acl.d/datasender.json $(1)/usr/share/rpcd/acl.d/datasender.json; \
	$(foreach file,data_sender_collections data_sender_inputs data_sender_outputs data_sender_format data_sender_encoder data_sender_utils, \
	  $(call ModuleInstallLuaFile,$(file),,$(1),$$$$files_dir) \
	)
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

# --- Generate Data To Server Module ---
define GenerateDataToServerModule

define Package/vuci-app-data-sender-api-mod-$(2)
	SECTION:=vuci
	CATEGORY:=VuCI
	SUBMENU:=Applications/API
	TITLE:=Vuci Data Sender API $(1) module
	ifneq ($(2), azure)
		DEPENDS:=+data-sender-mod-$(2)
	endif
endef

define Package/vuci-app-data-sender-api-mod-$(2)/install
	files_dir="./files"; if [ -d "$(PKG_BUILD_DIR)/files" ]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_DIR) $$(1)/usr/lib/lua/api/services/$(3); \
	$(call ModuleInstallLuaFile,$(3),$(4),$$(1),$$$$$$$$files_dir)
endef

define Package/vuci-app-data-sender-api-mod-$(2)/postinst
$(call ModulePostinst,$$$${IPKG_INSTROOT})
endef

$$(eval $$(call BuildPackage,vuci-app-data-sender-api-mod-$(2)))
endef

# --- Module List ---
DATA_TO_SERVER_MODULES := \
	Format_Custom:format-custom:ds_formats:ds_format_custom \
	Lua_Format:lua_format:ds_formats:ds_format_lua \
	MQTT_Input:mqtt-in:ds_inputs:ds_input_mqtt \
	MQTT_Output:mqtt-out:ds_outputs:ds_output_mqtt \
	HTTP:http:ds_outputs:ds_output_http \
	UBUS:ubus:ds_outputs:ds_output_ubus \
	Bluetooth:bluetooth:ds_inputs:ds_input_bluetooth \
	Mbus:mbus:ds_inputs:ds_input_mbus \
	Lua_Script_Input:lua-in:ds_inputs:ds_input_lua \
	GSM:gsm:ds_inputs:ds_input_gsm \
	Mobile_Usage:mdcollect:ds_inputs:ds_input_mdcollect \
	Modbus_Alarm:modbus-alarm:ds_inputs:ds_input_modbus_alarm \
	Modbus:modbus:ds_inputs:ds_input_modbus \
	DNP3:dnp3:ds_inputs:ds_input_dnp3 \
	OPCUA:opcua:ds_inputs:ds_input_opcua \
	Impulse_Counter:impulse_counter:ds_inputs:ds_input_impulse_counter \
	Dlms:dlms:ds_inputs:ds_input_dlms \
	WifiScan:wifiscan:ds_inputs:ds_input_wifiscan \
	Azure:azure:ds_outputs:ds_output_azure

# --- Helper to replace _ with SPACE ---
space := $(empty) $(empty)
pretty_name = $(subst _,$(space),$(1))

# --- Loop Through and Generate Modules ---
$(foreach mod,$(DATA_TO_SERVER_MODULES), \
	$(eval parts := $(subst :, ,$(mod))) \
	$(eval modname := $(word 1,$(parts))) \
	$(eval $(call GenerateDataToServerModule,$(call pretty_name,$(modname)),$(word 2,$(parts)),$(word 3,$(parts)),$(word 4,$(parts)))) \
)

# --- Advanced Module ---
define Package/vuci-app-data-sender-api-mod-advanced
	SECTION:=vuci
    CATEGORY:=VuCI
    SUBMENU:=Applications/API
    TITLE:=Vuci Advanced Data to Server API modules
    DEPENDS:=+data-sender-mod-ftp +data-sender-mod-lua-out +data-sender-mod-smtp +data-sender-mod-socket +MOBILE_SUPPORT:data-sender-mod-sms-in +MOBILE_SUPPORT:data-sender-mod-sms-out +GPS_SUPPORT:data-sender-mod-gps +IO_SUPPORT:data-sender-mod-io
	ifeq (m, $(CONFIG_PACKAGE_vuci-app-data-sender-api-mod-advanced))
		PKG_TLT_NAME:=Advanced Data to Server Modules
		PKG_ROUTER:=$(TLT_PLATFORM_NAME)
		PKG_APP_NAME:=data-sender-mod-advanced
	endif
endef

define Package/vuci-app-data-sender-api-mod-advanced/description
	Includes advanced modules for data exchange between the router and external systems.
	Supports data input via SMS, and I/O. Data output via FTP, SMTP, sockets, Lua scripts and SMS.
	Optional modules enabled based on platform capabilities (e.g., SMS, GPS, I/O).
endef

define Package/vuci-app-data-sender-api-mod-advanced/install
	files_dir="./files"; if [ -d "$(PKG_BUILD_DIR)/files" ]; then files_dir="$(PKG_BUILD_DIR)/files"; fi; \
	$(INSTALL_DIR) $(1)/usr/lib/lua/api/services/ds_inputs; \
	$(INSTALL_DIR) $(1)/usr/lib/lua/api/services/ds_outputs; \
	$(if $(CONFIG_MOBILE_SUPPORT), \
		$(call ModuleInstallLuaFile,ds_inputs,ds_input_sms,$(1),$$$$files_dir) \
		$(call ModuleInstallLuaFile,ds_outputs,ds_output_sms,$(1),$$$$files_dir) \
	) \
	$(if $(CONFIG_IO_SUPPORT), \
		$(call ModuleInstallLuaFile,ds_inputs,ds_input_io,$(1),$$$$files_dir) \
	) \
	$(foreach file,ftp lua smtp socket, \
		$(call ModuleInstallLuaFile,ds_outputs,ds_output_$(file),$(1),$$$$files_dir) \
	)
endef

define Package/vuci-app-data-sender-api-mod-advanced/postinst
$(call ModulePostinst,$${IPKG_INSTROOT})
endef

$(eval $(call BuildPackage,vuci-app-data-sender-api-mod-advanced))
