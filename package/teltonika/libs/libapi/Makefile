#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libapi
PKG_SOURCE_VERSION:=1.3.2
PKG_SOURCE_DATE:=2024-11-25
PKG_ABI_VERSION:=$(call abi_version_str,$(PKG_SOURCE_DATE))

PKG_LICENSE:=Teltonika-closed
GPL_INCLUDE_HEADERS:=1

include $(INCLUDE_DIR)/package.mk

MAKE_FLAGS += \
	FPIC="$(FPIC)" \
	SOVERSION="$(PKG_ABI_VERSION)"

define Package/libapi
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=RUTOS API communication library
	DEPENDS:=+libblobmsg-json +libubus
	ABI_VERSION:=$(PKG_ABI_VERSION)
endef

define Package/libapi/description
	A helper library for RUTOS API communication.
	It provides an easy way to interact with the RUTOS API, \
	including access control, data manipulation, and other features.
endef


define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/libapi/libapi.so* $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libapi/include/libapi.h $(1)/usr/include/
endef

define Package/libapi/install
	$(INSTALL_DIR) $(1)/usr/lib $(1)/usr/share/libapi/acl.d
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/libapi/files/acl.d/default.json.min \
			$(1)/usr/share/libapi/acl.d/default.json
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libapi/libapi.so.$(PKG_ABI_VERSION) $(1)/usr/lib/libapi.so.$(PKG_ABI_VERSION)
endef

$(eval $(call BuildPackage,libapi))
