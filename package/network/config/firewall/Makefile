#
# Copyright (C) 2013-2016 OpenWrt.org
# Copyright (C) 2016 LEDE project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=firewall
PKG_RELEASE:=13

PKG_SOURCE_DATE:=2022-02-17
PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>
PKG_LICENSE:=ISC
PKG_LICENSE_FILES:=LICENSE

PKG_CONFIG_DEPENDS += \
	CONFIG_IPV6 \
	CONFIG_USE_PROCD \
	CONFIG_USE_OPENRC

PKG_BUILD_FLAGS:=gc-sections lto

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=$(PROJECT_GIT)/project/firewall3.git
PKG_SOURCE_VERSION:=4cd7d4f36bea731bf901cb067456f1d460294926

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/firewall
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=OpenWrt C Firewall
  DEPENDS:=+libubox +libubus +libuci +libip4tc +IPV6:libip6tc +libxtables +kmod-ipt-core +kmod-ipt-conntrack +IPV6:kmod-nf-conntrack6 +kmod-ipt-nat +libnetfilter-conntrack +libmnl +AP_DEVICE:iptables-mod-filter
endef

define Package/firewall/description
 This package provides a config-compatible C implementation of the UCI firewall.
endef

define Package/firewall/conffiles
/etc/config/firewall
/etc/firewall.user
endef

TARGET_LDFLAGS += -lmnl -lnetfilter_conntrack
CMAKE_OPTIONS += $(if $(CONFIG_IPV6),,-DDISABLE_IPV6=1)

FIREWALL_CONFIG="firewall.config"
ifeq ($(TLT_PLATFORM_TAP100), y)
	FIREWALL_CONFIG=firewall.config-tap100
endif

ifeq ($(TLT_PLATFORM_TAP200), y)
	FIREWALL_CONFIG=firewall.config-tap200
endif

ifeq ($(TLT_PLATFORM_TAP400), y)
	FIREWALL_CONFIG=firewall.config-tap400
endif

ifeq ($(TLT_PLATFORM_DAP14X), y)
	FIREWALL_CONFIG=firewall.config-dap14x
endif

OFFLOADING=""
WAN_NETWORK="option network 'wan wan6'"
ifeq ($(CONFIG_SW_OFFLOAD), y)
	OFFLOADING="option flow_offloading '1'"
endif
ifeq ($(CONFIG_HW_OFFLOAD), y)
	OFFLOADING="option flow_offloading '1'\n	option flow_offloading_hw '1'"
endif

ifeq ($(CONFIG_NO_WIRED_WAN), y)
	WAN_NETWORK=""
endif

define Package/firewall/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/firewall3 $(1)/sbin/fw3
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/firewall.init $(1)/etc/init.d/firewall
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_CONF) ./files/firewall.hotplug $(1)/etc/hotplug.d/iface/20-firewall
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF_USR) ./files/$(FIREWALL_CONFIG) $(1)/etc/config/firewall

	$(SED) "s#%%OFFLOADING%%#"$(OFFLOADING)"#g" $(1)/etc/config/firewall
	$(SED) "s#%%WAN_NETWORK%%#"$(WAN_NETWORK)"#g" $(1)/etc/config/firewall

	$(INSTALL_DIR) $(1)/etc/
	$(INSTALL_CONF) ./files/firewall.user $(1)/etc/firewall.user
	$(INSTALL_DIR) $(1)/usr/share/fw3
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/helpers.conf $(1)/usr/share/fw3

	$(if $(CONFIG_AP_DEVICE),,\
		$(INSTALL_DIR) $(1)/usr $(1)/usr/bin; \
		$(INSTALL_BIN) ./files/attack_prevention.sh $(1)/usr/bin/attack_prevention;)

	$(if $(CONFIG_POE_SUPPORT),\
		$(INSTALL_DIR) $(1)/etc/uci-defaults/; \
		$(INSTALL_BIN) ./files/migrate_poe_wan.defaults $(1)/etc/uci-defaults/;)

	$(if $(CONFIG_USE_OPENRC),\
		$(OPENRC_INSTALL) boot firewall ./files/firewall.openrc $(1))
endef

$(eval $(call BuildPackage,firewall))
