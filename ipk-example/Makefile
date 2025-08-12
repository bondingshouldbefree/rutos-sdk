#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=example_package
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/example_package
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Example package
	DEPENDS:=+busybox
	ifeq (m, $(CONFIG_PACKAGE_example_package))
		PKG_TLT_NAME:=example_package
		PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	endif
endef

define Build/Compile
endef

define Package/example_package/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/example.sh $(1)/usr/bin/example.sh
endef

$(eval $(call BuildPackage,example_package))
