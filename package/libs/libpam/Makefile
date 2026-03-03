#
# Copyright (C) 2006-2014 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libpam
PKG_VERSION:=1.7.1
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.7.1
PKG_SOURCE:=Linux-PAM-$(PKG_SOURCE_VERSION).tar.xz
PKG_SOURCE_URL:=https://github.com/linux-pam/linux-pam/releases/download/v$(PKG_SOURCE_VERSION)

PKG_HASH:=21dbcec6e01dd578f14789eac9024a18941e6f2702a05cf91b28c232eeb26ab0

PKG_MAINTAINER:=Nikos Mavrogiannopoulos <n.mavrogiannopoulos@gmail.com>
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=COPYING
PKG_CPE_ID:=cpe:/a:linux-pam:linux-pam

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1
PKG_BUILD_PARALLEL:=1
PKG_BUILD_DEPENDS := libgpg-error libgcrypt meson/host

include $(INCLUDE_DIR)/package.mk
include ../../devel/meson/meson.mk

define Package/libpam/Default
	SECTION:=libs
	CATEGORY:=Libraries
	URL:=http://www.kernel.org/pub/linux/libs/pam
endef

define Package/libpam
	$(call Package/libpam/Default)
 	 TITLE:=the Linux-PAM libraries and modules.
  	MENU:=1
endef

define Package/libpam/description
	The Linux-PAM Pluggable Authentication Modules.
endef

define Package/libpam-mod-unix
  $(call Package/libpam/Default)
  DEPENDS:=libpam
  TITLE:=Module for traditional password authentication
endef

define Package/libpam-mod-deny
  $(call Package/libpam/Default)
  DEPENDS:=libpam
  TITLE:=The locking-out PAM module
endef

define Package/libpam-mod-deny/description
	This module can be used to deny access. \
	It always indicates a failure to the application through the PAM framework
endef

define Package/libpam-mod-permit
  $(call Package/libpam/Default)
  DEPENDS:=libpam
  TITLE:=The promiscuous module
endef

define Package/libpam-mod-permit/description
	pam_permit is a PAM module that always permit access. It does nothing else.
endef

define Package/libpam-mod-umask
  $(call Package/libpam/Default)
  DEPENDS:=libpam
  TITLE:=PAM module to set the file mode creation mask
endef
define Package/libpam-mod-extra
  $(call Package/libpam/Default)
  DEPENDS:=libpam
  TITLE:=Extra PAM modules
endef

MESON_ARGS += \
	-Dpamlocking=true \
	-Daudit=disabled \
	-Ddocs=disabled \
	-Deconf=disabled \
	-Dlckpwdf=false \
	-Dnis=disabled \
	-Dselinux=disabled \
	-Dmailspool=disabled \
	-Ddb=db \
	-Dxauth=disabled \
	-Dexamples=false \
	-Di18n=disabled \
	-Dvendordir=/var/run/pamd \
	-Dlibdir=/lib \
	$(if $(filter m,$(CONFIG_PACKAGE_libpam)), \
		-Dsecuredir=/usr/local/lib/security \
		-Dsbindir=/usr/local/usr/sbin \
	)

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/lib/* $(1)/usr/lib/
endef

define Package/libpam/install
	$(INSTALL_DIR) $(1)/etc $(1)/etc/pam.d
	$(INSTALL_DIR) $(1)/lib $(1)/lib/security $(1)/lib/security/pam_filter
	$(INSTALL_DIR) $(1)/usr/sbin
	$(CP) $(PKG_INSTALL_DIR)/etc/* $(1)/etc/
	$(CP) ./files/* $(1)/etc/
	$(CP) $(PKG_INSTALL_DIR)/lib/*.so* $(1)/lib/
	$(if $(filter m,$(CONFIG_PACKAGE_libpam)), \
		$(CP) $(PKG_INSTALL_DIR)/usr/local/lib/security/pam_filter/* $(1)/lib/security/pam_filter/; \
		$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/local/usr/sbin/* $(1)/usr/sbin/, \
		$(CP) $(PKG_INSTALL_DIR)/lib/security/pam_filter/* $(1)/lib/security/pam_filter/; \
		$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/* $(1)/usr/sbin/ \
	)
	$(INSTALL_DIR) $(1)/etc/permtab.d
	$(INSTALL_DATA) ./files/libpam.permtab $(1)/etc/permtab.d/libpam
endef

define BuildPlugin
  define Package/libpam-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/lib/security
	for m in $(2); do \
		$(if $(filter m,$(CONFIG_PACKAGE_libpam)), \
			$(CP) $(PKG_INSTALL_DIR)/usr/local/lib/security/pam_$$$$$$$${m}.so* $$(1)/lib/security/ ;, \
			$(CP) $(PKG_INSTALL_DIR)/lib/security/pam_$$$$$$$${m}.so* $$(1)/lib/security/ ; \
		) \
	done
  endef
  $$(eval $$(call BuildPackage,libpam-mod-$(1)))
endef

PAM_EXTRA_MODULES:= \
	access debug deny echo env exec faildelay fil filter ftp group issue keyinit \
	limits listfile localuser loginuid mail mkhomedir motd namespace nologin permit \
	pwhistory rootok securetty shells stress succeed_if tally2 tally time timestamp \
	umask unix warn wheel xauth \

$(eval $(call BuildPackage,libpam))
$(eval $(call BuildPlugin,unix,unix))
$(eval $(call BuildPlugin,deny,deny))
$(eval $(call BuildPlugin,permit,permit))
$(eval $(call BuildPlugin,umask,umask))
$(eval $(call BuildPlugin,extra,$(PAM_EXTRA_MODULES)))
