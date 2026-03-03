#
# Copyright (C) 2025 Teltonika-Networks
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=tpm_flasher
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.0
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=License.txt

include $(INCLUDE_DIR)/package.mk

define Package/tpm_flasher
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=TPM Flasher
	DEPENDS:=+libopenssl +tpm2-tss
endef

define Package/tpm_flasher/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tpm_flasher/TPMFactoryUpd $(1)/usr/sbin/tpm_flasher
endef

$(eval $(call BuildPackage,tpm_flasher))
