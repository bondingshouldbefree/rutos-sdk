#
# Copytight (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=dsa-dot1x-server
PKG_SOURCE_VERSION:=1.0.1
PKG_RELEASE:=2025-04-28
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk



define Package/dsa-dot1x-server
	SECTION:=net
	CATEGORY:=Network
	TITLE:=802.1X server
	DEPENDS:=+radius_test +kmod-sched-flower +(WIFI_SUPPORT||PACKAGE_dot1x-client):wpad-openssl +tc-tiny \
		+!(HAS_SINGLE_ETH_PORT||DSA_SUPPORT||TARGET_x86_64):kmod-sched-act-vlan \
		+!(HAS_SINGLE_ETH_PORT||DSA_SUPPORT||TARGET_x86_64):kmod-sched-core \
		+!(HAS_SINGLE_ETH_PORT||DSA_SUPPORT||TARGET_x86_64):kmod-dummy \
		+TARGET_x86_64:kmod-veth +!(WIFI_SUPPORT||PACKAGE_dot1x-client):hostapd-micro-nac-openssl \
		+libcap +libuci +liblua
	FATTRS:=/usr/sbin/dot1x_port_blocker:dot1x_server::y:cap_net_admin=eip;/usr/sbin/eap_sender::::cap_net_raw=eip
endef

ifeq ($(CONFIG_PACKAGE_dsa-dot1x-server),m)
define Package/dsa-dot1x-server/postinst
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	config_generate
	exit 0
endef
endif

define Package/dsa-dot1x-server/prerm
	#!/bin/sh
	[ -z "$${IPKG_INSTROOT}" ] || exit 0
	. /lib/functions.sh
	/etc/init.d/dot1x_server stop # this will authorize all ports and clean up tc
	remove_isolation_vlans() {
		config_get isolation "$$1" isolation
		[ "$$isolation" = "1" ] && {
			uci_remove network "$$1"
		}
	}
	config_load network
	config_foreach remove_isolation_vlans "switch_vlan"
	uci commit network
	rm /etc/config/dot1x
endef

define Package/dsa-dot1x-server/description
	802.1X Network Access Control
endef

define Package/dsa-dot1x-server/install
	$(INSTALL_DIR) $(1)/usr/sbin/ $(1)/usr/lib/ $(1)/etc/init.d/ $(1)/lib/config.d/ $(1)/etc/config/ $(1)/usr/share/acl.d/ $(1)/etc/permtab.d/ $(1)/etc/uci-defaults/7.16/
	$(if $(CONFIG_TARGET_x86_64),\
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/dot1x_x86_64.config $(1)/etc/config/dot1x
		install -m0700 $(PKG_BUILD_DIR)/dot1xd/platform_scripts/dsa/dot1x_port_blocker $(1)/usr/sbin/dot1x_port_blocker,\
		$(if $(CONFIG_HAS_SINGLE_ETH_PORT),
			$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/dot1x_single_port.config $(1)/etc/config/dot1x
			install -m0700 $(PKG_BUILD_DIR)/dot1xd/platform_scripts/dsa/dot1x_port_blocker $(1)/usr/sbin/dot1x_port_blocker,\
			$(if $(CONFIG_TARGET_ramips_mt76x8),
				$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/config.d/generate-dot1x-server-mt76x8 $(1)/lib/config.d/797-generate-dot1x-server
				install -m0700 $(PKG_BUILD_DIR)/dot1xd/platform_scripts/mt76x8/runner $(1)/usr/sbin/dot1x_port_blocker,\
				$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/config.d/generate-dot1x-server $(1)/lib/config.d/799-generate-dot1x-server
				install -m0700 $(PKG_BUILD_DIR)/dot1xd/platform_scripts/dsa/dot1x_port_blocker $(1)/usr/sbin/dot1x_port_blocker
			)
		)
	)

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/dot1xd/dot1x_server.json $(1)/usr/share/acl.d/dot1x_server.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/defaults/99_add_radius_name $(1)/etc/uci-defaults/7.16/99_add_radius_name
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/dot1x_server.permtab $(1)/etc/permtab.d/dot1x_server
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dot1xd/dot1xd.lua $(1)/usr/sbin/dot1xd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/dot1xd/dot1x_server.init $(1)/etc/init.d/dot1x_server
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/eap_init/eap_sender $(1)/usr/sbin/eap_sender
endef

$(eval $(call BuildPackage,dsa-dot1x-server))
