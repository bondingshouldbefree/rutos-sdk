#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=relayd
PKG_VERSION:=2020-04-25
PKG_RELEASE:=1

PKG_SOURCE_DATE:=2020-04-25

PKG_MAINTAINER:=Felix Fietkau <nbd@nbd.name>
PKG_LICENSE:=GPL-2.0-only

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=$(PROJECT_GIT)/project/relayd.git
PKG_SOURCE_VERSION:=f4d759be54ceb37714e9a6ca320d5b50c95e9ce9

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/relayd
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=Transparent routing / relay daemon
  DEPENDS:=+libubox +libubus
  USERID:=relayd:relayd
  $(eval CAP_DIR:=$(if $(findstring m,$(CONFIG_PACKAGE_relayd)),,/usr/local))
  FATTRS:=$(CAP_DIR)/usr/sbin/relayd::::cap_net_admin,cap_net_raw=ep
endef

TARGET_CFLAGS += -I$(STAGING_DIR)/usr/include

define Package/relayd/conffiles
/etc/config/relayd
endef

define Package/relayd/install
	$(eval DEST_DIR:=$$(1)$(if $(findstring m,$(CONFIG_PACKAGE_relayd)),,/usr/local))
	$(INSTALL_DIR) $(DEST_DIR)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/relayd $(DEST_DIR)/usr/sbin/relayd

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/relayd $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) ./files/etc/config/relayd $(1)/etc/config/

	$(INSTALL_DIR) $(1)/usr/share/acl.d/
	$(INSTALL_DATA) ./files/relayd_acl.json $(1)/usr/share/acl.d/relayd_acl.json

	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.11
	$(INSTALL_DATA) ./files/relayd.defaults $(1)/etc/uci-defaults/7.11/10-move-relayd-from-network-conf

	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/relayd.permtab $(1)/etc/permtab.d/relayd
endef

$(eval $(call BuildPackage,relayd))
