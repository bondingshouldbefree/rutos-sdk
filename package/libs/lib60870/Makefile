include $(TOPDIR)/rules.mk

PKG_NAME:=lib60870

# Upstream source version points to v2.3.6 tag
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=63028a9287da3b075d4225effcf1dfaf5ea47ed1
PKG_SOURCE_URL:=https://github.com/mz-automation/lib60870.git

PKG_LICENSE:=Commercial-License-Agreement
PKG_LICENSE_FILES:=COPYING

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

CMAKE_SOURCE_SUBDIR:=lib60870-C

define Package/lib60870
	SECTION:=libs
	CATEGORY:=Libraries
	URL:=https://github.com/mz-automation/lib60870
	TITLE:=IEC 60870-5-101/104 protocol stack
endef

define Package/lib60870/description
	lib60870 library for IEC 60870-5 based protocols in C

	The current implementation contains code for the IEC 60870-5-101 (application layer and serial link layer) and IEC 60870-5-104 (protocool over TCP/IP) specifications.
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_INSTALL_DIR)/usr/include/* $(1)/usr/include/

	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/liblib60870.so* $(1)/usr/lib/
endef

define Package/lib60870/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/liblib60870.so* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,lib60870))
