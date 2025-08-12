# Copyright (C) 2012-2016 PIVA Software <www.pivasoftware.com>
# 	Author: MOHAMED Kallel <mohamed.kallel@pivasoftware.com>
# 	Author: ANIS ELLOUZE <anis.ellouze@pivasoftware.com>

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=easycwmp
PKG_VERSION:=2025-07-31
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.8.3
PKG_SOURCE_URL:=https://github.com/pivasoftware/easycwmp/archive/refs/tags/
PKG_SOURCE:=EasyCwmp-$(PKG_SOURCE_VERSION).tar.gz
PKG_HASH:=3c54ada0b0cc82d903c27cc84f27b5ee076002163bcda5a94c32a5c89a8793da

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)

PKG_ORIGIN_URL:=https://easycwmp.org/get
PKG_LICENSE:=GPL-2.0

PKG_FIXUP:=autoreconf

PKG_CONFIG_DEPENDS:= \
	CONFIG_EASYCWMP_DEBUG \
	CONFIG_EASYCWMP_DEVEL

include $(INCLUDE_DIR)/package.mk

define Package/easycwmp
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=CWMP client (using libcurl)
  DEPENDS:=+libubus +libuci +libubox +libmicroxml +libjson-c +libcurl +curl
  USERID:=easycwmp=521:easycwmp=521
  USER_GROUPS:=easycwmp:network gsm chilli dnsmasq
endef

define Package/easycwmp/description
 TR-069 is an open source implementation of the client CWMP (TR-069)
 protocol for data transfer to Auto Configuration Server (ACS).
endef

define Package/easycwmp/config
	source "$(SOURCE)/Config.in"
endef

TARGET_CFLAGS += \
	-D_GNU_SOURCE

TARGET_LDFLAGS += \
	-Wl,-rpath-link=$(STAGING_DIR)/usr/lib

CONFIGURE_ARGS += \
	--with-uci-include-path=$(STAGING_DIR)/usr/include \
	--with-libubox-include-path=$(STAGING_DIR)/usr/include \
	--with-libubus-include-path=$(STAGING_DIR)/usr/include

ifeq ($(CONFIG_EASYCWMP_DEBUG),y)
CONFIGURE_ARGS += \
	--enable-debug
endif

ifeq ($(CONFIG_EASYCWMP_DEVEL),y)
CONFIGURE_ARGS += \
	--enable-devel
endif

ifeq ($(CONFIG_EASYCWMP_BACKUP_DATA_CONFIG),y)
CONFIGURE_ARGS += \
	--enable-backupdatainconfig
endif

CONFIGURE_ARGS += \
	--enable-jsonc=1

define Package/easycwmp/conffiles
/etc/config/easycwmp
endef

define Package/easycwmp/install
	$(INSTALL_DIR) $(1)/usr/share/acl.d/ $(1)/etc/uci-defaults/7.14 \
			$(1)/lib/upgrade/keep.d/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ext/openwrt/files/900-easycwmp.sh $(1)/etc/uci-defaults/99_easycwmp
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ext/openwrt/files/easycwmp.json $(1)/usr/share/acl.d/easycwmp.json
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/easycwmpd $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/ext/openwrt/config/easycwmp $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ext/openwrt/init.d/easycwmpd $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ext/openwrt/files/easycwmp.permtab $(1)/etc/permtab.d/easycwmp
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/ext/openwrt/files/easycwmp.keep $(1)/lib/upgrade/keep.d/easycwmpd
ifeq ($(EASYCWMP_BACKUP_DATA_FILE),y)
	$(INSTALL_DIR) $(1)/etc/easycwmp
endif
ifeq ($(CONFIG_EASYCWMP_SCRIPTS_FULL),y)
	$(INSTALL_DIR) $(1)/usr/share/easycwmp/functions/
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/common/* $(1)/usr/share/easycwmp/functions/
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/custom/* $(1)/usr/share/easycwmp/functions/
ifeq ($(CONFIG_EASYCWMP_SCRIPT_GPS), y)
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/gps/* $(1)/usr/share/easycwmp/functions/
endif
ifeq ($(CONFIG_EASYCWMP_SCRIPT_HOTSPOT), y)
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/hotspot/* $(1)/usr/share/easycwmp/functions/
endif
ifeq ($(CONFIG_EASYCWMP_DATA_MODEL_TR181),y)
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/tr181/* $(1)/usr/share/easycwmp/functions/
else
	$(CP) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/tr098/* $(1)/usr/share/easycwmp/functions/
endif
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ext/openwrt/scripts/easycwmp.sh $(1)/usr/sbin/easycwmp
	chmod +x $(1)/usr/share/easycwmp/functions/*
else
	$(INSTALL_DIR) $(1)/usr/share/easycwmp/functions/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ext/openwrt/scripts/functions/common/ipping_launch $(1)/usr/share/easycwmp/functions/ipping_launch
endif
endef

$(eval $(call BuildPackage,easycwmp))
