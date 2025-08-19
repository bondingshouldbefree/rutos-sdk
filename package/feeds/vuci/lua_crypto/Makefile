#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lua_crypto
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=Teltonika-nda-source

include $(INCLUDE_DIR)/package.mk

define Package/lua_crypto
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=A library for exposing OpenSSL cryptographic functions to LUA.
	DEPENDS:=+liblua +openssl-util +libopenssl
endef

define Package/lua_crypto/description
	A simple lib that exposes OpenSSL cryptographic function for use in LUA.
endef


define Package/lua_crypto/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/
	$(CP) $(PKG_BUILD_DIR)/lua_crypto.so $(1)/usr/lib/lua/
endef

$(eval $(call BuildPackage,lua_crypto))
