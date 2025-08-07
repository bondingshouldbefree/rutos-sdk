#
# Copyright (C) 2022 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=mdcollect
PKG_VERSION:=2025-05-12
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed

PKG_SOURCE_VERSION:=7.16
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

include $(INCLUDE_DIR)/package.mk

define Package/mdcollectd
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=mdcollectd
	DEPENDS:=+lsqlite3 +libuci +libtlt_uci +libmdcollect +libubus +libubox \
		+libtlt-logger +libnftnl +MOBILE_SUPPORT:libgsm
	USERID:=mdcollectd:mdcollectd
endef

define Package/libmdcollect
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=A library for mdcollectd
	DEPENDS:=+lsqlite3 +libjson-c +libubus +libubox +libblobmsg-json
endef

define Package/mdcollectd/conffiles
/etc/config/mdcollectd
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR)/usr/lib $(STAGING_DIR)/usr/include
	$(CP) $(PKG_BUILD_DIR)/*.so $(STAGING_DIR)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/src/include/libmdcollect.h $(STAGING_DIR)/usr/include/
endef


define Package/mdcollectd/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ \
		$(1)/usr/bin/ $(1)/usr/share/acl.d/ $(1)/etc/permtab.d/
	$(INSTALL_CONF_USR) ./files/mdcollectd.config $(1)/etc/config/mdcollectd
	$(INSTALL_BIN) ./files/mdcollectd.init $(1)/etc/init.d/mdcollectd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/mdcollectd $(1)/usr/bin/mdcollectd
	$(INSTALL_DATA) ./files/mdcollectd_acl.json $(1)/usr/share/acl.d/mdcollectd_acl.json
	$(INSTALL_DATA) ./files/mdcollect.permtab $(1)/etc/permtab.d/mdcollect
endef

define Package/libmdcollect/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libmdcollect.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,mdcollectd))
$(eval $(call BuildPackage,libmdcollect))
