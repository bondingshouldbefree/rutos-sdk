#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=ledman

PKG_SOURCE_VERSION:=2.25.1

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/ledman-full
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=LED status manager
	PROVIDES:=ledman
	VARIANT:=full
	DEPENDS:= +libubus +libubox +libblobmsg-json +libuci +libnl-tiny +MOBILE_SUPPORT:libgsm +MOBILE_SUPPORT:liburc
	USERID:=ledman:ledman
	FATTRS:=/usr/bin/ledman::::cap_net_admin+ep
endef

# TODO SOMEHOW DEPS FROM 'FULL' IS NEEDED TO COMPILE 'TINY'
define Package/ledman
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=LED status manager
	PROVIDES:=ledman
	CONFLICTS:=ledman-full
	VARIANT:=tiny
	USERID:=ledman:ledman
endef

define Package/ledman-full/description
	Daemon for handling and controlling LEDs
endef

define Package/ledman/description
	Daemon for handling and controlling LEDs
endef

ifeq ($(BUILD_VARIANT),full)
	TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include/libnl-tiny
	TARGET_CFLAGS += -I$(PKG_BUILD_DIR)/src
endif

define Package/ledman-full/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/usr/bin $(1)/usr/share/acl.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ledman.init $(1)/etc/init.d/ledman
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ledman $(1)/usr/bin/ledman
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/ledman.json $(1)/usr/share/acl.d/ledman.json
endef


define Package/ledman/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ledman_lite.sh $(1)/usr/bin/ledman
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ledman_lite.init $(1)/etc/init.d/ledman
endef







$(eval $(call BuildPackage,ledman))
$(eval $(call BuildPackage,ledman-full))
