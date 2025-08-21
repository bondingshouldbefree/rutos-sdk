include $(TOPDIR)/rules.mk

PKG_NAME:=letsencrypt
PKG_VERSION:=2024-11-26
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=7cc12390f8d291e2d573906d795feadd1dfdeebd
PKG_SOURCE_URL=https://github.com/bruncsak/ght-acme.sh.git

PKG_LICENSE:=GPL-2.0-only
PKG_LICENSE_FILES:=LICENCE

include $(INCLUDE_DIR)/package.mk

define Package/letsencrypt
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Letsencrypt (ACME) script
  DEPENDS:=+openssl-util +curl
  PKGARCH:=all
  ifeq (m, $(CONFIG_PACKAGE_letsencrypt))
    PKG_TLT_NAME:=Let's encrypt
    PKG_ROUTER:=$(TLT_PLATFORM_NAME)
  endif
endef

define Package/letsencrypt/description
 This package contains Certificate Manager Let's Encrypt support.
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/letsencrypt/install
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/letsencrypt.sh $(1)/sbin/letsencrypt
endef

$(eval $(call BuildPackage,letsencrypt))
