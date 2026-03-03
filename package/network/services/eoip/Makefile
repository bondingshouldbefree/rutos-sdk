include $(TOPDIR)/rules.mk

PKG_NAME:=eoip
PKG_VERSION:=1.0
PKG_RELEASE:=8

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Nat-Lab/eoip.git
PKG_SOURCE_DATE:=2025-09-16
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_MIRROR_HASH:=skip

PKG_LICENSE:=MIT
PKG_LICENSE_FILE:=LICENSE
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/eoip
	SECTION:=net
	CATEGORY:=Network
	SUBMENU:=VPN
	TITLE:=Ethernet over IP tunnel (Mikrotik compatible)
	DEPENDS:=+kmod-tun
	FATTRS:=/usr/sbin/eoip::::cap_net_admin,cap_net_raw+ep
	USERID:=eoip:eoip
endef

define Build/Install
    true
endef

define Package/eoip/install
	mkdir -p $(1)/usr/sbin
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/eoip $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) ./files/eoip.config $(1)/etc/config/eoip
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN_USR) ./files/eoip.init $(1)/etc/init.d/eoip
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/eoip.permtab $(1)/etc/permtab.d/eoip
endef

$(eval $(call BuildPackage,eoip))