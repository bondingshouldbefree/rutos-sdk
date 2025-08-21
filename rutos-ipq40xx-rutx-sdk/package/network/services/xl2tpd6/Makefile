include $(TOPDIR)/rules.mk

PKG_NAME:=xl2tpd6
PKG_VERSION:=1.3.17
PKG_RELEASE:=3

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_URL:=https://github.com/ulysse31/xl2tpd6.git

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_LICENSE:=GPL-2.0-or-later
PKG_LICENSE_FILES:=LICENSE

PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/xl2tpd6
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=VPN
  TITLE:=L2TP daemon with IPv6 support
  URL:=https://github.com/ulysse31/xl2tpd6
  DEPENDS:=+libpthread +kmod-l2tp +kmod-l2tp-eth +kmod-l2tp-ip
  USERID:=xl2tpd:xl2tpd
  FATTRS:=/usr/sbin/xl2tpd6-control:xl2tpd::y:
  ifeq (m, $(CONFIG_PACKAGE_xl2tpd6))
    PKG_TLT_NAME:=L2TPV6 support
    PKG_ROUTER:=$(TLT_PLATFORM_NAME)
  endif
endef

define Package/xl2tpd6/description
  xl2tpd6 is a daemon that manages Layer 2 Tunneling Protocol (L2TP) tunnels.
  It is based on xl2tpd with added IPv6 support.
endef

define Package/xl2tpd6/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/xl2tpd6 $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/xl2tpd6-control $(1)/usr/sbin/
endef

define Package/xl2tpd6/postrm
  #!/bin/sh
  if [ "$$(uci -q get xl2tpd.@service[0].use_ipv6)" = "1" ]; then
    uci -q set xl2tpd.@service[0].use_ipv6=0
    uci commit xl2tpd
    /etc/init.d/xl2tpd reload
  fi
endef

$(eval $(call BuildPackage,xl2tpd6))

