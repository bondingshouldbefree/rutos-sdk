#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=exe4cpp
PKG_VERSION:=1.12.2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/automatak/exe4cpp.git
PKG_SOURCE_VERSION:=fb878a4de598ba9d6e4338afebf83f96e03af1b8

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/exe4cpp
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Executor abstractions for C++ with implementations for ASIO
	URL:=https://github.com/automatak/exe4cpp/
endef

define Build/Compile
	@echo "exe4cpp is header-only"
endef

define Package/exe4cpp/description
	exe4cpp is a header-only library that provides executor abstractions for C++ with implementations for ASIO.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/src/exe4cpp $(1)/usr/include/
endef

$(eval $(call BuildPackage,exe4cpp))
