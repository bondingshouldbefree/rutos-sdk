#
# Copyright (C) 2025 Teltonika-Networks
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=tpm_manager
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.2
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/tpm_manager
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=TPM Manager
	DEPENDS:=+libubox +libubus +libuci +libblobmsg-json +libjson-c +libopenssl +tpm2-tss +liblog
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include

	$(CP) $(PKG_BUILD_DIR)/api/include/* $(1)/usr/include
endef


define Package/tpm_manager/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tpm_manager/tpm_manager $(1)/usr/sbin/

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/tpm_manager.init $(1)/etc/init.d/tpm_manager
endef

$(eval $(call BuildPackage,tpm_manager))
