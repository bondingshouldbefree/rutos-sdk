include $(TOPDIR)/rules.mk

APP_APP_NAME:=telnet
APP_TITLE:=VuCI API Support for Telnet
APP_TLT_NAME:=Telnet
APP_ROUTER:=$(TLT_PLATFORM_NAME)
APP_DEPENDS:=+telnet

define Package/vuci-app-telnet-api/prerm
	#!/bin/sh
	. /lib/functions.sh

	clean_telnet_rules() {
		local name
		config_get "name" "$$1" "name"
		[ "$$name" = "Enable_TELNET_WAN" ] || [ "$$name" = "Reject-Telnet-lan" ] && {
			uci_remove firewall "$$1"
		}
	}

	config_load firewall
	config_foreach clean_telnet_rules rule 2> /dev/null
	uci_commit firewall 2> /dev/null
endef

include ../api.mk

define Package/vuci-app-telnet-api/description
	Telnet is a protocol that allows you to connect to remote computers (called hosts) over a TCP/IP network 
endef

# call BuildPackage - OpenWrt buildroot signature
