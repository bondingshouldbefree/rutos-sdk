#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=tpm2_importer

PKG_SOURCE_VERSION:=7.21
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+tpm2-tools +openssl-util
  TITLE:=TPM2 importer
endef

define Package/$(PKG_NAME)/description
  TPM2 key import utility. Works with ecc and rsa keys.
endef

define Package/libtpm2_importer
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=RUTOS TPM Importer library
	ABI_VERSION:=$(PKG_ABI_VERSION)
endef

define Package/libtpm2_importer/description
	A helper library for key management. It provides helper functions for working with TPM keys.
endef


define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libtpm_importer.so $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/include/libtpm_importer.h $(1)/usr/include/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin/
	$(INSTALL_BIN) ./files/tpm2_importer $(1)/bin/
endef

define Package/libtpm2_importer/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libtpm_importer.so \
			$(1)/usr/lib/libtpm_importer.so
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,libtpm2_importer))
