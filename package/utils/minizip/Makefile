#
# Copyright © 2020 David Woodhouse <dwmw2@infradead.org>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.

include $(TOPDIR)/rules.mk

PKG_NAME:=minizip-ng
PKG_VERSION:=4.0.7
PKG_RELEASE:=2

PKG_SOURCE_VERSION:=4.0.7
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_URL:=https://codeload.github.com/zlib-ng/minizip-ng/tar.gz/$(PKG_SOURCE_VERSION)?
PKG_HASH:=a87f1f734f97095fe1ef0018217c149d53d0f78438bcb77af38adc21dff2dfbc

PKG_MAINTAINER:=David Woodhouse <dwmw2@infradead.org>
PKG_LICENSE:=Zlib
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:zlib-ng:minizip-ng

PKG_BUILD_FLAGS:=lto

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_OPTIONS += \
	-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
	-DINSTALL_INC_DIR=/usr/include/minizip \
	-DBUILD_SHARED_LIBS=OFF \
	-DMZ_BZIP2=OFF \
	-DMZ_ICONV=OFF \
	-DMZ_LIBBSD=OFF \
	-DMZ_LZMA=OFF \
	-DMZ_OPENSSL=ON \
	-DMZ_WZAES=ON \
	-DMZ_PKCRYPT=OFF \
	-DMZ_ZSTD=OFF \
	-DMZ_BUILD_TESTS=ON

define Package/minizip
  TITLE:=Fork of the popular zip manipulation library found in the zlib distribution
  SECTION:=libs
  CATEGORY:=Libraries
  DEPENDS:=+zlib +libopenssl
  URL:=https://github.com/zlib-ng/minizip-ng
endef

define Package/minizip-dev
  SECTION:=devel
  CATEGORY:=Development
  SUBMENU:=Libraries
  DEPENDS:=minizip
  TITLE:=Development files for the minizip library
endef

define Package/minizip/description
  minizip is a zip manipulation library written in C that is supported on Windows, macOS, and Linux
endef

define Package/minizip/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/bin/minizip $(1)/usr/bin/
endef

define Build/InstallDev
	$(call Build/InstallDev/cmake,$(1))
	$(SED) 's,/usr/include,$$$${prefix}/include,g' $(1)/usr/lib/pkgconfig/minizip.pc
	$(SED) 's,/usr/lib,$$$${exec_prefix}/lib,g' $(1)/usr/lib/pkgconfig/minizip.pc
endef

$(eval $(call BuildPackage,minizip))