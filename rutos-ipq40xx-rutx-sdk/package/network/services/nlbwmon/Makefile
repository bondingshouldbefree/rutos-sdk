include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=nlbwmon
PKG_VERSION:=2025-03-25
PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>
PKG_LICENSE:=ISC
PKG_LICENSE_FILES:=COPYING
PKG_RELEASE:=2

PKG_SOURCE_VERSION:=c7616bcfaaef440848152f4dc738c990b2d0b90b
PKG_SOURCE_URL:=https://codeload.github.com/jow-/nlbwmon/tar.gz/$(PKG_SOURCE_VERSION)?
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_HASH:=affec077cee3b4c2477ee454f6af0ff61fd7d650716bab5c8129d5c3ee4c165d

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)

PKG_ORIGIN_URL:=https://github.com/jow-/nlbwmon

CMAKE_INSTALL:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += -DLIBNL_LIBRARY_TINY=ON
TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include/libnl-tiny

define Package/nlbwmon
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=+libubox +libnl-tiny +zlib +kmod-nf-conntrack-netlink +libsqlite3
  TITLE:=OpenWrt Traffic Usage Monitor
  FATTRS:=/usr/sbin/nlbwmon::::cap_net_admin=ep
  USERID:=nlbwmon=546:nlbwmon=546
endef

define Package/nlbwmon/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/local/share/nlbwmon $(1)/etc/init.d $(1)/etc/config $(1)/etc/hotplug.d/iface
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/protocols.txt $(1)/usr/local/share/nlbwmon/protocols
	$(INSTALL_BIN) ./files/nlbwmon.init $(1)/etc/init.d/nlbwmon
	$(INSTALL_CONF_USR) ./files/nlbwmon.config $(1)/etc/config/nlbwmon
	$(INSTALL_BIN) ./files/nlbwmon.hotplug $(1)/etc/hotplug.d/iface/30-nlbwmon
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/nlbwmon $(1)/usr/sbin/nlbwmon
	$(LN) nlbwmon $(1)/usr/sbin/nlbw

	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/nlbwmon.permtab $(1)/etc/permtab.d/nlbwmon
endef

define Package/nlbwmon/conffiles
/etc/config/nlbwmon
/usr/local/share/nlbwmon/protocols
endef

$(eval $(call BuildPackage,nlbwmon))
