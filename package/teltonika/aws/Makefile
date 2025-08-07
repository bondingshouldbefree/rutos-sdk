#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=aws
PKG_VERSION:=2025-05-15
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=1.4

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/aws
	SECTION:=base
	CATEGORY:=Base system
	DEPENDS:=+libubus +libuci +libaws-iot-device-sdk-embedded-C \
		 +libmosquitto +libtlt-logger +libubox +libblobmsg-json \
		 +libatomic +libapi +libopenssl +libcurl +libmnfinfo
	TITLE:=AWS client
	USERID:=aws=508:aws=508
endef

define Package/aws/description
	AWS Cloud support.
endef

define Package/aws/conffiles
/etc/config/aws_jobs
endef


define Package/aws/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/usr/lib $(1)/etc/init.d $(1)/etc/config $(1)/etc/aws \
		       $(1)/usr/share/acl.d $(1)/etc/permtab.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aws_jobs/aws_jobs $(1)/usr/sbin/aws_jobs
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aws_jobs/files/aws.init $(1)/etc/init.d/aws
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/aws_provisioning/aws_provisioning.so \
		       $(1)/usr/lib/libaws_provisioning.so
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/aws_jobs/files/aws.conf $(1)/etc/config/aws_jobs
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/aws_jobs/files/aws.json $(1)/usr/share/acl.d/aws.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/aws_jobs/files/aws.permtab $(1)/etc/permtab.d/aws
endef

$(eval $(call BuildPackage,aws))
