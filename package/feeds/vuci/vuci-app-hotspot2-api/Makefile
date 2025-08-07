include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for Hotspot 2.0

define Package/vuci-app-hotspot2-api/prerm
	#!/bin/sh
	. /lib/functions.sh

	remove_section() {
		uci_remove wireless "$$1"
	}

	remove_item() {
		uci_remove_list wireless "$$2" "$$3" "$$1"
	}

	cleanup_wless_iface() {
		uci_remove wireless "$$1" "interworking"
		uci_remove wireless "$$1" "hs20"
		uci_remove wireless "$$1" "internet"
		uci_remove wireless "$$1" "access_network_type"
		uci_remove wireless "$$1" "hessid"
		uci_remove wireless "$$1" "network_auth_type"
		uci_remove wireless "$$1" "ipaddr_type_"
		uci_remove wireless "$$1" "venue_group"
		uci_remove wireless "$$1" "venue_type"
		uci_remove wireless "$$1" "osu_ssid"
		uci_remove wireless "$$1" "osu_server_uri"
		uci_remove wireless "$$1" "osu_friendly_name"
		uci_remove wireless "$$1" "osu_nai"
		uci_remove wireless "$$1" "osu_service_desc"
		uci_remove wireless "$$1" "hs20_wan_status"
		uci_remove wireless "$$1" "hs20_wan_dw_speed"
		uci_remove wireless "$$1" "hs20_wan_up_speed"

		config_list_foreach "$$1" "domain_name" remove_item "$$1" "domain_name"
		config_list_foreach "$$1" "osu_method_list" remove_item "$$1" "osu_method_list"
		config_list_foreach "$$1" "venue_url" remove_item "$$1" "venue_url"
		config_list_foreach "$$1" "venue_name" remove_item "$$1" "venue_name"
		config_list_foreach "$$1" "anqp_3gpp_cell_net" remove_item "$$1" "anqp_3gpp_cell_net"
		config_list_foreach "$$1" "nai_realm" remove_item "$$1" "nai_realm"
		config_list_foreach "$$1" "hs20_oper_friendly_name" remove_item "$$1" "hs20_oper_friendly_name"
		config_list_foreach "$$1" "hs20_conn_capab" remove_item "$$1" "hs20_conn_capab"
	}

	config_load wireless
	config_foreach remove_section "venue"
	config_foreach remove_section "nai-realm"
	config_foreach remove_section "hs20_conn_capab"
	config_foreach remove_section "anqp_3gpp_cell_net"
	config_foreach remove_section "hs20_oper_friendly_name"

	config_foreach cleanup_wless_iface "wifi-iface" 2> /dev/null

	uci_commit wireless 2> /dev/null
	/etc/init.d/wpad reload 2> /dev/null || true
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
