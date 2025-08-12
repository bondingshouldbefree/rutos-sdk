include $(TOPDIR)/rules.mk

PKG_NAME:=rpcd-mod-rrdns

PKG_VERSION:=2025-03-25


PKG_LICENSE:=ISC

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += $(FPIC)

define Package/rpcd-mod-rrdns
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=Rapid reverse DNS rpcd module
  DEPENDS:=+rpcd +libubox +libubus
endef

define Package/rpcd-mod-rrdns/description
	Provides rapid mass reverse DNS lookup functionality.
endef

define Package/rpcd-mod-rrdns/install
	$(INSTALL_DIR) $(1)/usr/lib/rpcd/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/rrdns.so $(1)/usr/lib/rpcd/
endef

$(eval $(call BuildPackage,rpcd-mod-rrdns))
