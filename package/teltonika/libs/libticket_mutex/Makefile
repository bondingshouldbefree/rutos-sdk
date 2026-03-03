#
# Copyright (C) 2025 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libticket_mutex
PKG_SOURCE_VERSION:=7.21
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/libticket_mutex
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=An implementation of a ticket lock.
	DEPENDS:=+libtlt-logger +libatomic
endef

define Package/libticket_mutex/description
	An implementation of a ticket lock which uses a blocking mutex.

	Works across processess and is able to recover from a situation where the process which was holding
	the lock has been killed without unlocking.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/
	$(CP) $(PKG_BUILD_DIR)/include/libticket_mutex.h $(STAGING_DIR)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/libticket_mutex.so $(STAGING_DIR)/usr/lib/
endef

define Package/libticket_mutex/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libticket_mutex.so $(1)/usr/lib/
endef


$(eval $(call BuildPackage,libticket_mutex))
