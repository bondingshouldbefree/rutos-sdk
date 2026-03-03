#
# Copyright (C) 2025 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=scep
PKG_VERSION:=2025-05-12
PKG_RELEASE:=1

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/scep
	CATEGORY:=Utilities
	TITLE:=Meta package for SCEP packages
	DEPENDS:=strongswan +strongswan-libtls +strongswan-mod-pkcs7 +strongswan-mod-curl +strongswan-pki +strongswan-mod-kdf

	ifeq (m, $(CONFIG_PACKAGE_scep))
		PKG_TLT_NAME:=SCEP
		PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	endif
endef



define Package/scep/install
	$(INSTALL_DIR) $(1)/etc/uci-defaults/7.15
	$(INSTALL_DATA) ./files/defaults/99-migrate_crontab $(1)/etc/uci-defaults/7.15/99-migrate_crontab
endef

$(eval $(call BuildPackage,scep))
