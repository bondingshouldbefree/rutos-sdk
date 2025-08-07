#
# Copyright (C) 2021 Tetlonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=smppd
PKG_VERSION:=2025-05-15

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=1.11
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_BUILD_DEPENDS:=ustream-ssl

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/smpp
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=SMPP Transceiver
	DEPENDS:=+libsmpp34 +libubox +libtlt-logger +libgsm +liburc \
		+libubus +libboardjson
	USERID:=smppd=520:smppd=520
endef

define Package/smpp/description
	SMPP package that provides SMPP protocol
	services for flexible short message data transfer.
endef

define Package/smpp/conffiles
/etc/config/smpp
endef


define Package/smpp/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d $(1)/etc/config \
		$(1)/usr/share/acl.d $(1)/etc/permtab.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/smppd $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/smpp.init $(1)/etc/init.d/smpp
	$(CP) $(PKG_BUILD_DIR)/files/smpp.conf $(1)/etc/config/smpp
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/smpp.json $(1)/usr/share/acl.d/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/smpp.permtab $(1)/etc/permtab.d/
endef

$(eval $(call BuildPackage,smpp))
