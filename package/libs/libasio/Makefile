#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libasio
PKG_VERSION:=1.16.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/chriskohlhoff/asio.git
PKG_SOURCE_VERSION:=asio-1-16-0

PKG_LICENSE:=BSL-1.0
PKG_LICENSE_FILES:=LICENSE_1_0.txt COPYING

include $(INCLUDE_DIR)/package.mk

define Package/libasio
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=Asio C++ library
	URL:=https://think-async.com/Asio/
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	@echo "Preparing libasio package..."
	mv $(PKG_BUILD_DIR)/asio/* $(PKG_BUILD_DIR)/
	rm -r $(PKG_BUILD_DIR)/asio
endef

define Build/Compile
	@echo "ASIO is header-only"
endef

define Package/libasio/description
	Asio is a cross-platform C++ library for network and low-level I/O programming.
	It provides developers with a consistent asynchronous model using a modern C++ approach.
	It is widely used in various applications, including networking, file I/O, and more.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/asio.hpp $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/asio $(1)/usr/include/
endef

$(eval $(call BuildPackage,libasio))
