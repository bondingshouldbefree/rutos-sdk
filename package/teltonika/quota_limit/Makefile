#
# Copyright (C) 2023 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=quota_limit
PKG_VERSION:=2025-07-09
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed

PKG_SOURCE_VERSION:=7.17
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/quota_limit
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=quota_limit
	DEPENDS:=+libuci +libtlt_uci +libgsm +libtlt-logger +!CUSTOM_DATA_LIMIT:kmod-nft-netdev +libmdcollect +libnftnl
	USERID:=quota_limit:quota_limit
	FATTRS:=/usr/bin/quota_limit::::cap_net_admin=ep
endef

TARGET_CFLAGS += -D_GNU_SOURCE

QUOTA_PERMTAB="quota_limit.permtab"

ifeq ($(TLT_PLATFORM_TRB500), y)
	QUOTA_PERMTAB="quota_limit.permtab-trb500"
endif

define Package/quota_limit/description
	3G data counter
endef

define Package/quota_limit/conffiles
/etc/config/quota_limit
endef


define Package/quota_limit/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ $(1)/usr/bin/ \
		$(1)/usr/share/acl.d/ $(1)/etc/permtab.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/quota_limit.init $(1)/etc/init.d/quota_limit
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/quota_limit_acl.json $(1)/usr/share/acl.d/quota_limit_acl.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/$(QUOTA_PERMTAB) $(1)/etc/permtab.d/quota_limit
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quota_limit $(1)/usr/bin/quota_limit
endef

$(eval $(call BuildPackage,quota_limit))
