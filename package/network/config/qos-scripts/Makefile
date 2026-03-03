#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=qos-scripts
PKG_VERSION:=1.3.1
PKG_RELEASE:=$(AUTORELEASE).1
PKG_LICENSE:=GPL-2.0-only

PKG_ORIGIN_URL:=https://github.com/openwrt/openwrt/tree/openwrt-21.02/package/network/config/qos-scripts

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>

include $(INCLUDE_DIR)/package.mk

define Package/qos-scripts
  SECTION:=utils
  CATEGORY:=Base system
  DEPENDS:=+tc +kmod-sched-core +kmod-sched-connmark +kmod-ifb +iptables \
	  +iptables-mod-ipopt +iptables-mod-conntrack-extra
  TITLE:=QoS scripts
  PKGARCH:=all
  USERID:=qos:qos
endef

define Package/qos-scripts/description
 A set of scripts that abstract QoS configuration into a simple 
 configuration file supporting stanzas that specify any number of QoS 
 entries.
endef

define Package/qos-scripts/conffiles
/etc/config/qos
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/qos-scripts/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/hotplug.d/iface $(1)/etc/init.d $(1)/usr/bin $(1)/usr/lib/qos $(1)/etc/permtab.d
	$(INSTALL_BIN) ./files/usr/bin/* $(1)/usr/bin
	$(INSTALL_BIN) ./files/etc/hotplug.d/iface/10-qos $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/etc/init.d/qos $(1)/etc/init.d
	$(INSTALL_BIN) ./files/usr/lib/qos/generate.sh $(1)/usr/lib/qos
	$(INSTALL_DATA) ./files/usr/lib/qos/tcrules.awk $(1)/usr/lib/qos
	$(INSTALL_CONF_USR) ./files/etc/config/qos $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/permtab.d/qos $(1)/etc/permtab.d/qos
endef

$(eval $(call BuildPackage,qos-scripts))
