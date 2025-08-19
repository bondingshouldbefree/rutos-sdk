#
# Copyright (C) 2024 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lua_extra_validators
PKG_VERSION:=2021-12-28
PKG_LICENSE:=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk

define Package/lua_extra_validators
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=A library for providing string validators which you cant do in Lua
	DEPENDS:=+liblua +lua +libc
endef


define Package/lua_extra_validators/install
	$(INSTALL_DIR) $(1)/usr/lib/lua
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lua_extra_validators.so $(1)/usr/lib/lua
endef

$(eval $(call BuildPackage,lua_extra_validators))
