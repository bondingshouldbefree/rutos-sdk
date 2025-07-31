#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mwan3
PKG_VERSION:=2.10.12
PKG_RELEASE:=13
PKG_MAINTAINER:=Florian Eckert <fe@dev.tdt.de>, \
		Aaron Goodman <aaronjg@alumni.stanford.edu>
PKG_LICENSE:=GPL-2.0-only
PKG_CONFIG_DEPENDS:=CONFIG_IPV6

PKG_ORIGIN_URL:=https://github.com/openwrt/packages/tree/openwrt-21.02/net/mwan3

include $(INCLUDE_DIR)/package.mk

define Package/mwan3
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:= \
     +rpcd \
     +ip \
     +ipset \
     +iptables \
     +iptables-mod-conntrack-extra \
     +iptables-mod-ipopt \
     +jshn
   TITLE:=Multiwan hotplug script with connection tracking support
   MAINTAINER:=Florian Eckert <fe@dev.tdt.de>
   PKGARCH:=all
endef

define Package/mwan3/description
Hotplug script which makes configuration of multiple WAN interfaces simple
and manageable. With loadbalancing/failover support for up to 250 wan
interfaces, connection tracking and an easy to manage traffic ruleset.
endef

define Package/mwan3/conffiles
/etc/config/mwan3
/etc/mwan3/mwan3.user
endef

define Package/mwan3/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/rpcd ]; then
	/etc/init.d/rpcd reload
fi
exit 0
endef

define Package/mwan3/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/rpcd ]; then
	/etc/init.d/rpcd reload
fi
exit 0
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/files/
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	$(CP) ./files/* $(PKG_BUILD_DIR)/files/
	$(Build/Patch)
endef

define Build/Compile
	$(TARGET_CC) $(CFLAGS) $(LDFLAGS) $(FPIC) \
		-shared \
		-o $(PKG_BUILD_DIR)/libwrap_mwan3_sockopt.so.1.0 \
		$(if $(CONFIG_IPV6),-DCONFIG_IPV6) \
		$(PKG_BUILD_DIR)/sockopt_wrap.c \
		-ldl
endef

define Package/mwan3/install
	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_mwan3)),,/usr/local))
	$(INSTALL_DIR) $(1)/etc/config
	$(if $(wildcard $(PKG_BUILD_DIR)/files/etc/config/mwan3-$(call device_shortname)), \
		$(INSTALL_CONF_USR) "$(PKG_BUILD_DIR)/files/etc/config/mwan3-$(call device_shortname)" $(1)/etc/config/mwan3, \
		$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/etc/config/mwan3 $(1)/etc/config/mwan3)

	$(INSTALL_DIR) $(DEST_DIR)/usr/share/mwan3
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/usr/share/15-mwan3 \
		$(DEST_DIR)/usr/share/mwan3/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/usr/share/16-mwan3-user \
		$(DEST_DIR)/usr/share/mwan3/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/mwan3 \
		$(1)/etc/init.d/

	$(INSTALL_DIR) $(DEST_DIR)/usr/lib/mwan3
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lib/mwan3/common.sh \
		$(DEST_DIR)/usr/lib/mwan3/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lib/mwan3/mwan3.sh \
		$(DEST_DIR)/usr/lib/mwan3/

	$(INSTALL_DIR) $(DEST_DIR)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/libexec/rpcd/mwan3 \
		$(DEST_DIR)/usr/libexec/rpcd/

	$(INSTALL_DIR) $(DEST_DIR)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/mwan3 \
		$(DEST_DIR)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/mwan3rtmon \
		$(DEST_DIR)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/usr/sbin/mwan3track \
		$(DEST_DIR)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/mwan3
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/mwan3/mwan3.user \
		$(1)/etc/mwan3/

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/mwan3.defaults $(1)/etc/uci-defaults/
	$(if $(CONFIG_NO_WIRED_WAN), \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/mwan3-no-wan.defaults $(1)/etc/uci-defaults/)

	$(CP) $(PKG_BUILD_DIR)/libwrap_mwan3_sockopt.so.1.0 $(DEST_DIR)/usr/lib/mwan3/
endef

$(eval $(call BuildPackage,mwan3))
