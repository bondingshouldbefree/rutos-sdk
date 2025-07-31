#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=ser4cpp
PKG_VERSION:=1.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/automatak/ser4cpp.git
PKG_SOURCE_VERSION:=3c449734dc530a8f465eb0982de29165cc4e23d5

PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/ser4cpp
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Safe low-level serializations routines for C++
	URL:=https://github.com/automatak/ser4cpp
endef

define Build/Compile
	@echo "ser4cpp is header-only"
endef

define Package/ser4cpp/description
	Ser4cpp is a C++ library that provides safe low-level serialization routines for C++.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/src/ser4cpp $(1)/usr/include/
endef

define Build/Install
	$(INSTALL_DIR) $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/src/ser4cpp $(1)/usr/include/
endef

$(eval $(call BuildPackage,ser4cpp))
