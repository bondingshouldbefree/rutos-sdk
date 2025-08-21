#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=tpm2_importer
PKG_VERSION:=2025-05-15
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=base
  CATEGORY:=Base system
  DEPENDS:=+strongswan-pki +tpm2-tools
  TITLE:=TPM2 importer
endef



define Package/$(PKG_NAME)/description
  TPM2 key import utility. Works with ecc and rsa keys.
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/bin/
	$(INSTALL_BIN) ./files/tpm2_importer $(1)/bin/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
