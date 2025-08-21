#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=networkmap
PKG_VERSION:=2025-04-11
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=2.1.1
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/networkmap
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Networkmap tool
	DEPENDS:=+libpcap +libpthread +libsqlite3 +libubus +libubox
	FATTRS:=/bin/networkmap:networkmap::y:cap_net_raw=ep
	USERID:=networkmap=526:networkmap=526
endef

define Package/networkmap/description
	Devices scanner.
endef


define Package/networkmap/install
	$(INSTALL_DIR) $(1)/bin $(1)/usr/share/acl.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/networkmap $(1)/bin/networkmap
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/networkmap.json $(1)/usr/share/acl.d/networkmap.json
endef

$(eval $(call BuildPackage,networkmap))
