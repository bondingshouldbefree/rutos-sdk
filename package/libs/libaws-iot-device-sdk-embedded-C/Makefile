#
# Copyright (C) 2020 Amazon.com, Inc. or its affiliates.  All Rights Reserved.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libaws-iot-device-sdk-embedded-C
PKG_VERSION:=202211.00
PKG_RELEASE:=1

PKG_HASH:=d57bec3db322111e3bcfda56ebdc6673

PKG_SOURCE_VERSION:=202211.00
PKG_SOURCE:=aws-iot-device-sdk-embedded-C-$(PKG_SOURCE_VERSION).zip
PKG_SOURCE_URL:=https://github.com/aws/aws-iot-device-sdk-embedded-C/releases/download/$(PKG_SOURCE_VERSION)

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

CUSTOM_COMPILE:= \
	$(CP) source/include/*.h $(PKG_BUILD_DIR)/libraries/libaws/include; \
	$(TARGET_CC) -I source/include -c -fpic source/*.c; \
	mv *.o $(PKG_BUILD_DIR)/libraries/libaws \
	; \

define Package/libaws-iot-device-sdk-embedded-C
	SECTION:=base
	CATEGORY:=Base system
	DEPENDS:=+libopenssl
	TITLE:=AWS IoT Device SDK for Embedded C
endef

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/libraries/libaws
	mkdir -p $(PKG_BUILD_DIR)/libraries/libaws/include

	cd $(PKG_BUILD_DIR)/libraries/standard/coreJSON && $(CUSTOM_COMPILE)
	cd $(PKG_BUILD_DIR)/libraries/aws/jobs-for-aws-iot-embedded-sdk && $(CUSTOM_COMPILE)

	cd $(PKG_BUILD_DIR)/libraries/libaws && $(TARGET_CC) -shared -o libaws.so *.o
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR)/usr/lib $(STAGING_DIR)/usr/include/aws
	$(CP) $(PKG_BUILD_DIR)/libraries/libaws/libaws.so $(STAGING_DIR)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libraries/libaws/include/*.h $(STAGING_DIR)/usr/include/aws
endef

define Package/libaws-iot-device-sdk-embedded-C/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libraries/libaws/libaws.so $(1)/usr/lib
endef

$(eval $(call BuildPackage,libaws-iot-device-sdk-embedded-C))
