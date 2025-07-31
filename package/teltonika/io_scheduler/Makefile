#
# Copyright (C) 2024 Teltonika-Networks
#

include $(TOPDIR)/rules.mk

PKG_NAME:=io_scheduler

PKG_SOURCE_VERSION:=1.3

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/io_scheduler
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Daemon providing I/O scheduling features
	DEPENDS:=+libuci +libubus +libubox +libtlt-logger +iomand
	USERID:=iosch=532:iosch=532
endef

define Package/io_scheduler/conffiles
/etc/config/io_scheduler
endef


define Package/io_scheduler/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/config $(1)/etc/init.d \
			$(1)/etc/uci-defaults/7.13 $(1)/usr/share/acl.d \
			$(1)/etc/permtab.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/scheduler $(1)/usr/bin/scheduler
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/ioman_scheduler.init \
			$(1)/etc/init.d/ioman_scheduler
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/io_scheduler.conf \
			$(1)/etc/config/io_scheduler
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/io_scheduler.json \
			$(1)/usr/share/acl.d/io_scheduler.json
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/io_scheduler.permtab $(1)/etc/permtab.d/
endef

$(eval $(call BuildPackage,io_scheduler))
