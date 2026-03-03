#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=DMVPN
PKG_VERSION:=2021-02-11
PKG_RELEASE:=7
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/dmvpn
	SUBMENU:=VPN
  	SECTION:=net
  	CATEGORY:=Network
	TITLE:=Dynamic multipoint VPN using NHRP GRE and IPsec
	DEPENDS:=+kmod-gre +IPV6:kmod-gre6 +resolveip +libpthread +ip \
		+kmod-crypto-authenc +kmod-ipsec +kmod-ipsec4 +IPV6:kmod-ipsec6 \
		+kmod-ipt-ipsec +iptables-mod-ipsec \
		+frr-nhrp +frr
	USERID:=dmvpn:dmvpn
endef

define Package/dmvpn/description
	Dynamic Multipoint VPN (DMVPN) is a method of building scalable IPsec VPNs.
	DMVPN is configured as a hub-and-spoke network, where tunnels between spokes
	are built dynamically; therefore, no change in configuration is required on
	the hub in order to connect new spokes.
endef



define Package/dmvpn/conffiles
/etc/config/dmvpn
endef

define Package/dmvpn/install
	$(INSTALL_DIR) \
		$(1)/etc/config \
		$(1)/etc/uci-defaults/7.16 \
		$(1)/etc/uci-defaults/7.19 \
		$(1)/etc/permtab.d
	$(INSTALL_CONF_USR) files/etc/config/dmvpn \
		$(1)/etc/config/dmvpn
	$(INSTALL_BIN) ./files/defaults/99-main_table_to_254 $(1)/etc/uci-defaults/7.16/99-main_table_to_254
	$(INSTALL_BIN) ./files/defaults/99-migrate_redirect $(1)/etc/uci-defaults/7.19/99-migrate_redirect
	$(INSTALL_DATA) files/dmvpn.permtab $(1)/etc/permtab.d/dmvpn
endef

define Package/dmvpn/prerm
	#!/bin/sh
	. /lib/functions.sh
	delete_dmvpn() {
		section="$${1}"
		config="$${2}"
		config_get service "$${section}" service
		[ "$${service}" = "dmvpn" ] && uci_remove "$${config}" "$${section}"
	}
	clean_dmvpn() {
		config="$${1}"
		config_load "$${config}" || return
		config_foreach delete_dmvpn "" "$${config}"
		uci_commit "$${config}"
		/etc/init.d/"$${config/ipsec/swanctl}" reload
	}
	clean_dmvpn network
	clean_dmvpn ipsec
	clean_dmvpn frr
	exit 0
endef

$(eval $(call BuildPackage,dmvpn))
