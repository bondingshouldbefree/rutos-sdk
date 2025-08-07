include $(TOPDIR)/rules.mk

PKG_NAME:=tpm2-tools
PKG_VERSION:=5.7

PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=5.7
PKG_SOURCE_URL:=https://github.com/tpm2-software/tpm2-tools.git

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=docs/LICENSE

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  SUBMENU:=TPM2
  TITLE:=TPM2-TOOLS
  URL:=https://github.com/tpm2-software/tpm2-tools
  DEPENDS:= +tpm2-tss +libopenssl +libcurl
endef

define Package/$(PKG_NAME)/description
  TPM (Trusted Platform Module) 2 tools
endef

CONFIGURE_ARGS += \
	--disable-fapi \
	--disable-doxygen-doc

TARGET_CFLAGS += -DFALSE=0 -DTRUE=1

define Build/Prepare
$(call Build/Prepare/Default)
	( cd $(PKG_BUILD_DIR) ; \
		[ -f ./configure ] || { \
			PKG_VERSION=$(PKG_SOURCE_VERSION) \
			./bootstrap ; \
		} \
	)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_activatecredential $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_certify $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_certifycreation $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_create $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_createak $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_createek $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_createpolicy $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_createprimary $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_import $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_clearcontrol $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_clear $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_changeauth $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_dictionarylockout $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_encryptdecrypt $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_evictcontrol $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_flushcontext $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_getcap $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_getekcertificate $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_getrandom $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_hash $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_hmac $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_load $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_loadexternal $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_makecredential $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvdefine $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvundefine $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvread $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvreadpublic $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvreadlock $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_nvwrite $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_pcrevent $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_pcrextend $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_pcrread $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_quote $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_rc_decode $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_readpublic $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_rsadecrypt $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_rsaencrypt $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_send $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_sign $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_startup $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_startauthsession $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_pcrread $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_policysecret $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_policypcr $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_policyauthorize $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_unseal $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ipkg-install/usr/bin/tpm2_verifysignature $(1)/usr/bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
