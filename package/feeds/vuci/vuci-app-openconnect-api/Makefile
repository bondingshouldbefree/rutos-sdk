include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for OpenConnect
APP_DEPENDS:=+openconnect

define Package/vuci-app-openconnect-api/prerm
	#!/bin/sh

	. /lib/functions.sh
	. /usr/share/libubox/jshn.sh

	get_openconnect() {
		local section="$$1" proto
		config_get proto "$$section" proto
		if [ "$$proto" = "openconnect" ]; then
			json_add_string "" "$$section"
		fi
	}

	config_load network

	json_init
	json_add_array data
	config_foreach get_openconnect interface
	json_close_array

	api delete /openconnect/client/config "$$(json_dump)" > /dev/null 2>&1
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
