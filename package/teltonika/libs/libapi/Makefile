#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=libapi
PKG_SOURCE_VERSION:=1.5
PKG_SOURCE_DATE:=2025-06-13

PKG_LICENSE:=Teltonika-closed
GPL_INCLUDE_HEADERS:=1

include $(INCLUDE_DIR)/package.mk

MAKE_FLAGS += \
	FPIC="$(FPIC)" \

define Package/libapi
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=RUTOS API communication library
	DEPENDS:=+libblobmsg-json +libubus
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
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libapi/libapi.so $(1)/usr/lib/libapi.so
endef

$(eval $(call BuildPackage,libapi))
