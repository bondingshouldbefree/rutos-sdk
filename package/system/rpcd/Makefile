#
# Copyright (C) 2013-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=rpcd
PKG_VERSION:=2025-12-10
PKG_MAINTAINER:=Jo-Philipp Wich <jo@mein.io>
PKG_LICENSE:=ISC
PKG_LICENSE_FILES:=main.c
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=ccb75178cf6a726896729c6904bd623636aa0b29
PKG_SOURCE_URL:=$(PROJECT_GIT)/project/rpcd.git
PKG_HASH:=87b1839275c209f9767057d6da5272cae973a064767fa28f380a37fb65e2e643

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)

PKG_BUILD_PARALLEL:=1
PKG_ASLR_PIE_REGULAR:=1

PKG_CONFIG_DEPENDS += \
	CONFIG_RPCD_PAM \
	CONFIG_USE_PROCD \
	CONFIG_USE_OPENRC

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/include/rpcd $(1)/usr/include/
endef

define Package/rpcd/default
  SECTION:=utils
  CATEGORY:=Base system
  TITLE:=OpenWrt ubus RPC backend server
  DEPENDS:=+libubus +libubox +libcap +libtlt-logger
  USERID:=rpcd:rpcd
  FATTRS:=/sbin/rpcd::::cap_setuid,cap_net_admin,cap_setgid,cap_sys_boot,cap_sys_admin,cap_dac_override=p
endef

define Package/session
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Session Daemon
  DEPENDS:=+libubox +libubus +libuci +libblobmsg-json +libtlt-logger
endef

define Package/rpcd
  $(Package/rpcd/default)
  DEPENDS+= +libuci +libblobmsg-json +libjson-c
  MENU:=1
endef

define Package/rpcd/config
  source "$(SOURCE)/Config.in"
endef

define Package/rpcd/description
 This package provides the UBUS RPC backend server to expose various
 functionality to frontend programs via JSON-RPC.
endef

define Package/session/description
  A standalone session management daemon with token and ACL support.
endef

define Package/rpcd/conffiles
/etc/config/rpcd
endef

TARGET_LDFLAGS += -lcrypt

define Package/rpcd/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/init.d/rpcd.init $(1)/etc/init.d/rpcd
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rpcd $(1)/sbin/rpcd
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/unauthenticated.json $(1)/usr/share/rpcd/acl.d/unauthenticated.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/superuser.json $(1)/usr/share/rpcd/acl.d/superuser.json
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/rpcd.config $(1)/etc/config/rpcd
	$(INSTALL_DIR) $(1)/usr/share/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/* $(1)/usr/share/acl.d/
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/libexec/* $(1)/usr/libexec/rpcd/

	$(if $(filter y,$(CONFIG_PACKAGE_vuci-app-channel-analysis-ui)), \
		$(if $(CONFIG_AP_DEVICE), \
			$(SED) "s@%%WIRELESS_CHANNEL_ANALYSIS_ACL%%@list read '!status/channel_analysis*'@g" \
				$(1)/etc/config/rpcd; \
		, \
			$(SED) "s@%%WIRELESS_CHANNEL_ANALYSIS_ACL%%@list read '!status/wireless/channel_analysis*'@g" \
				$(1)/etc/config/rpcd; \
		) \
	, \
		$(SED) "/%%WIRELESS_CHANNEL_ANALYSIS_ACL%%/d" $(1)/etc/config/rpcd; \
	)

	$(if $(filter y,$(CONFIG_PACKAGE_vuci-app-coovachilli-ui)),\
		$(SED) "s@%%USER_SCRIPTS_HOTSPOT_ACL%%@list read '!services/hotspot/general/userscripts*'@g" \
			$(1)/etc/config/rpcd; \
	,\
		$(SED) "/%%USER_SCRIPTS_HOTSPOT_ACL%%/d" $(1)/etc/config/rpcd; \
	)

	$(if $(filter y,$(CONFIG_PACKAGE_vuci-app-mobile-utilities-ui)),\
		$(SED) "s@%%MOBILE_UTILS_SMS_SEND_ACL%%@list read '!services/mobile_utilities/sms_messages/send*'@g" \
			$(1)/etc/config/rpcd; \
	,\
		$(SED) "/%%MOBILE_UTILS_SMS_SEND_ACL%%/d" $(1)/etc/config/rpcd; \
	)

	$(if $(filter y,$(CONFIG_PACKAGE_vuci-app-setup-wizard-ui)),\
		$(SED) "s@%%SETUP_WIZARD_READ_ACL%%@list read '!system/wizard*'@g" \
			  -e "s@%%SETUP_WIZARD_WRITE_ACL%%@list write '!system/wizard*'@g" \
			  $(1)/etc/config/rpcd; \
	,\
		$(SED) "/%%SETUP_WIZARD_READ_ACL%%/d" -e "/%%SETUP_WIZARD_WRITE_ACL%%/d" $(1)/etc/config/rpcd; \
	)

	$(if $(filter y,$(CONFIG_PACKAGE_vuci-app-uscripts-ui)),\
		$(SED) "s@%%USER_SCRIPTS_READ_ACL%%@list read '!system/maintenance/uscripts*'@g" \
			  -e "s@%%USER_SCRIPTS_WRITE_ACL%%@list write '!system/maintenance/uscripts*'@g" \
			  $(1)/etc/config/rpcd; \
	,\
		$(SED) "/%%USER_SCRIPTS_READ_ACL%%/d" -e "/%%USER_SCRIPTS_WRITE_ACL%%/d" $(1)/etc/config/rpcd; \
	)

	$(if $(CONFIG_USE_OPENRC),\
		$(OPENRC_INSTALL) boot rpcd $(PKG_BUILD_DIR)/files/rpcd.openrc $(1))

	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.11
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-defaults/7.11/99_rpcd_sesitive_info_flag $(1)/etc/uci-defaults/7.11/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.13
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-defaults/7.13/99_rpcd_increase_timeout $(1)/etc/uci-defaults/7.13/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-defaults/7.13/99_rpcd_rename_usb_tools_paths $(1)/etc/uci-defaults/7.13/
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.19
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/uci-defaults/7.19/99_rpcd_migrate_shadow_entry $(1)/etc/uci-defaults/7.19/
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/rpcd.permtab $(1)/etc/permtab.d/rpcd
endef

define Package/session/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/session $(1)/usr/sbin/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN_USR) $(PKG_BUILD_DIR)/files/init.d/session.init $(1)/etc/init.d/session
endef

# 1: plugin name
# 2: extra dependencies
# 3: plugin title/description
define BuildPlugin

  PKG_CONFIG_DEPENDS += CONFIG_PACKAGE_luci-rpc-mod-$(1)

  define Package/rpcd-mod-$(1)
    $(Package/rpcd/default)
    TITLE+= ($(1) plugin)
    DEPENDS+=rpcd $(2)
    USER_GROUPS:=
  endef

  define Package/rpcd-mod-$(1)/description
    $(3)
  endef

  define Package/rpcd-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/rpcd
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(1).so $$(1)/usr/lib/rpcd/
  endef

  $$(eval $$(call BuildPackage,rpcd-mod-$(1)))

endef

CMAKE_OPTIONS += -DPAM_SUPPORT=$(if $(CONFIG_RPCD_PAM),"ON","OFF")
CMAKE_OPTIONS += -DIWINFO_SUPPORT=$(if $(CONFIG_PACKAGE_libiwinfo),"ON","OFF")
CMAKE_OPTIONS += -DUCI_SUPPORT=$(if $(CONFIG_PACKAGE_libuci),"ON","OFF")

$(eval $(call BuildPackage,rpcd))
$(eval $(call BuildPackage,session))
$(eval $(call BuildPlugin,file,,Provides ubus calls for file and directory operations.))
$(eval $(call BuildPlugin,rpcsys,,Provides ubus calls for sysupgrade and password changing.))
$(eval $(call BuildPlugin,iwinfo,+libiwinfo,Provides ubus calls for accessing iwinfo data.))
$(eval $(call BuildPlugin,uci,,Provides ubus calls for uci operations.))
$(eval $(call BuildPlugin,rc,,Provides ubus calls for init operations.))
