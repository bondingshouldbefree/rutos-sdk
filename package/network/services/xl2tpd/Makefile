#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=xl2tpd
PKG_VERSION:=1.3.16
PKG_RELEASE:=10
PKG_MAINTAINER:=Yousong Zhou <yszhou4tech@gmail.com>
PKG_LICENSE:=GPL-2.0-or-later
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE_VERSION:=1.3.16
PKG_SOURCE=xl2tpd-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/xelerance/xl2tpd/archive/refs/tags/v$(PKG_SOURCE_VERSION).tar.gz?
PKG_HASH:=c28608b315adb25c8bf9579c1d6ab52ab47c4c43b68a5ab63c5d039196fd180f

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/xl2tpd
  SECTION:=net
  CATEGORY:=Network
  TITLE:=An L2TP (Layer 2 Tunneling Protocol) daemon
  URL:=http://www.xelerance.com/software/xl2tpd/
  SUBMENU:=VPN
  DEPENDS:=+ppp-mod-pppol2tp +resolveip
  USERID:=xl2tpd:xl2tpd
  FATTRS:=/usr/sbin/xl2tpd-control:xl2tpd::y:
endef

define Package/xl2tpd/description
l2tpd is the open source implementation of the L2TP tunneling protocol (RFC2661).
It does implement both LAC and LNS role in a L2TP networking architecture. The
main goal of this protocol is to tunnel PPP frame trough an IP network.
endef

ifneq (0,0)
  # debugging options from Makefile of xl2tpd package
  EXTRA_CFLAGS += \
	-DDEBUG_ZLB \
	-DDEBUG_HELLO \
	-DDEBUG_CLOSE \
	-DDEBUG_FLOW \
	-DDEBUG_FILE \
	-DDEBUG_AAA \
	-DDEBUG_PAYLOAD \
	-DDEBUG_CONTROL \
	-DDEBUG_PPPD \
	-DDEBUG_HIDDEN \
	-DDEBUG_ENTROPY \
	-DDEBUG_CONTROL_XMIT \
	-DDEBUG_MAGIC \
	-DDEBUG_FLOW_MORE \
	-DDEBUG_AUTH
endif

define Package/xl2tpd/conffiles
/etc/xl2tpd/xl2tpd.conf
/etc/xl2tpd/xl2tp-secrets
/etc/ppp/options.xl2tpd
/etc/config/xl2tpd
endef

define Package/xl2tpd/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/local/sbin/xl2tpd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/local/sbin/xl2tpd-control $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) /dev/null $(1)/etc/config/xl2tpd

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/xl2tpd.init $(1)/etc/init.d/xl2tpd

	$(INSTALL_DIR) $(1)/etc/xl2tpd
	$(INSTALL_DATA) ./files/xl2tpd.conf $(1)/etc/xl2tpd/
	$(INSTALL_CONF) ./files/xl2tp-secrets $(1)/etc/xl2tpd/

	$(INSTALL_DIR) $(1)/etc/ppp
	$(INSTALL_DATA) ./files/options.xl2tpd $(1)/etc/ppp/
	$(INSTALL_DATA) ./files/options.l2tp $(1)/etc/ppp/
	$(INSTALL_BIN) ./files/xl2tpd-up $(1)/etc/ppp/
	$(INSTALL_BIN) ./files/xl2tpd-down $(1)/etc/ppp/

	$(INSTALL_DIR) $(1)/lib/netifd $(1)/usr/local/usr/lib/netifd/proto
	$(INSTALL_BIN) ./files/l2tp.sh $(1)/usr/local/usr/lib/netifd/proto/

	$(INSTALL_BIN) ./files/l2tp-up $(1)/lib/netifd/
	$(INSTALL_BIN) ./files/l2tp-down $(1)/lib/netifd/

	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_BIN) ./files/00-l2tp_slow_retry.hotplug $(1)/etc/hotplug.d/iface/00-l2tp_slow_retry

	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.15
	$(CP) ./files/defaults/99_l2tp_device_name $(1)/etc/uci-defaults/7.15/99_l2tp_device_name

endef

$(eval $(call BuildPackage,xl2tpd))
