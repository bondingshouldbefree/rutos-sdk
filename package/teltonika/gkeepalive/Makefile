#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=gkeepalive
PKG_VERSION:=2024-06-19
PKG_RELEASE:=1
PKG_SOURCE_VERSION=1.2
PKG_LICENSE:=Teltonika-closed


include $(INCLUDE_DIR)/package.mk

define Package/gkeepalive
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+libpcap +libpthread +libtlt-logger +libubus
  TITLE:=GRE keepalive
  USERID:=gkeepalive:gkeepalive
  FATTRS:=/usr/bin/gkeepalive::::cap_net_raw=ep
endef

define Package/gkeepalive/description
  GRE keepalive packet sender/receiver.
endef


define Package/gkeepalive/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/usr/share/acl.d/
	$(INSTALL_DIR) $(1)/usr/share/gkeepalive
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/gre_tunnel.init $(1)/etc/init.d/gre_tunnel
	$(INSTALL_BIN) ./files/90-gre-keep-alive $(1)/usr/share/gkeepalive/90-gre-keep-alive
	$(INSTALL_DATA) ./files/gkeepalive.json $(1)/usr/share/acl.d/gkeepalive.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/gkeepalive $(1)/usr/bin
endef

$(eval $(call BuildPackage,gkeepalive))
