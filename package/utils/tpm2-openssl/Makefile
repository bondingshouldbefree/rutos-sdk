include $(TOPDIR)/rules.mk

PKG_NAME:=tpm2-openssl
PKG_VERSION:=1.3.0
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/tpm2-software/tpm2-openssl.git
PKG_SOURCE_VERSION:=8a5572639742dee5bc0b370ac04547b4b8ab2e0f

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TPM2
  TITLE:=TPM2-OPENSSL
  URL:=https://github.com/tpm2-software/tpm2-openssl
  DEPENDS:= +tpm2-tss +openssl-util
endef

define Package/$(PKG_NAME)/description
  TPM (Trusted Platform Module) 2 openssl
endef

CONFIGURE_ARGS += \
	--exec-prefix=/usr \
	--prefix=/

TARGET_CFLAGS += -DFALSE=0 -DTRUE=1

define Build/Prepare
$(call Build/Prepare/Default)
	( cd $(PKG_BUILD_DIR) ; \
		[ -f ./configure ] || { \
			PKG_VERSION=$(PKG_VERSION) \
			./bootstrap ; \
		} \
	)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/lib/ossl-modules/
	$(CP) $(PKG_BUILD_DIR)/.libs/tpm2.so* $(1)/usr/lib/ossl-modules/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
