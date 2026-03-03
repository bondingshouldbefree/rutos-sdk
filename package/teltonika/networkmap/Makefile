#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=networkmap
PKG_VERSION:=2026-01-13
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=2.4
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/networkmap
	SECTION:=net
	CATEGORY:=Network
	TITLE:=Networkmap tool
	DEPENDS:=+libpcap +libpthread +libsqlite3 +libubus +libubox +libcap +libtlt-logger
	FATTRS:=/bin/networkmap::::cap_net_raw=ep;/usr/libexec/rpcd/networkmap:networkmap:networkmap::
	USERID:=networkmap=526:networkmap=526
endef

define Package/networkmap/description
	Devices scanner.
endef

define Package/networkmap/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/rpcd ]; then
	/etc/init.d/rpcd reload
fi
exit 0
endef

define Package/networkmap/postrm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ -x /etc/init.d/rpcd ]; then
	/etc/init.d/rpcd reload
fi
exit 0
endef


define Package/networkmap/install
	$(INSTALL_DIR) $(1)/bin $(1)/usr/share/acl.d $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/networkmap $(1)/bin/networkmap
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/networkmap.json $(1)/usr/share/acl.d/networkmap.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/networkmap.sh $(1)/usr/libexec/rpcd/networkmap
endef

$(eval $(call BuildPackage,networkmap))
