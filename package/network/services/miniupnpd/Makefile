#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=miniupnpd
PKG_VERSION:=2.3.4
PKG_RELEASE:=4

PKG_SOURCE_VERSION:=2.3.4
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=http://miniupnp.free.fr/files \
		https://miniupnp.tuxfamily.org/files

PKG_HASH:=e7303348fc8ac427de7f04f0eeb757d49dcc8367311ee2582552c38f5d6da08a

PKG_MAINTAINER:=
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:miniupnp_project:miniupnpd

PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=lto

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/version.mk

define Package/miniupnpd
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+iptables +libip4tc +IPV6:libip6tc +IPV6:ip6tables +libuuid
  TITLE:=Lightweight UPnP IGD, NAT-PMP & PCP daemon
  SUBMENU:=Firewall
  URL:=https://miniupnp.tuxfamily.org/
  USERID:=upnpd=544:upnpd=544
  FATTRS:=/usr/sbin/miniupnpd::::cap_net_broadcast,cap_net_admin,cap_net_raw,cap_net_bind_service=ep
endef

define Package/miniupnpd/description
	UPnP (Universal Plug and Play) is a service that allows clients in
	the local network to automatically configure some devices and services.
endef

define Package/miniupnpd/conffiles
/etc/config/upnpd
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	echo "$(VERSION_NUMBER)" | tr '() ' '_' >$(PKG_BUILD_DIR)/os.openwrt
endef

CONFIGURE_ARGS = \
	$(if $(CONFIG_IPV6),--ipv6) \
	--igd2 \
	--leasefile \
	--portinuse \
	--firewall=iptables \
	--disable-fork

TARGET_CFLAGS += $(FPIC)
TARGET_LDFLAGS += -Wl,--gc-sections,--as-needed

define Package/miniupnpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.4
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.14
	$(INSTALL_DIR) $(1)/etc/permtab.d

	$(INSTALL_DATA) ./files/miniupnpd.permtab $(1)/etc/permtab.d/miniupnpd
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/miniupnpd $(1)/usr/sbin/miniupnpd
	$(INSTALL_BIN) ./files/miniupnpd.init $(1)/etc/init.d/miniupnpd
	$(INSTALL_CONF_USR) ./files/upnpd.config $(1)/etc/config/upnpd
	$(INSTALL_DATA) ./files/miniupnpd.hotplug $(1)/etc/hotplug.d/iface/50-miniupnpd
	$(INSTALL_DATA) ./files/migrations/99_upnpd_fix_port_range $(1)/etc/uci-defaults/7.4/
	$(INSTALL_DATA) ./files/migrations/99_upnpd_fix_lease_file $(1)/etc/uci-defaults/7.14/

	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_miniupnpd)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/share/miniupnpd
	$(INSTALL_DATA) ./files/firewall.include $(DEST_DIR)/share/miniupnpd/firewall.include
endef

$(eval $(call BuildPackage,miniupnpd))
