include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-json

PKG_VERSION:=2025-01-06


PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += $(FPIC)

define Package/luci-lib-jsonc
	SECTION:=libs
	CATEGORY:=Libraries
	TITLE:=LuCI Lua JSON-C bindings
	DEPENDS:=+liblua +libjson-c
endef

define Package/luci-lib-jsonc/description
	LuCI JSON-C Lua bindings, used for encoding and decoding JSON within Lua scripts.
endef

define Package/luci-lib-jsonc/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/jsonc.so $(1)/usr/lib/lua/luci
endef

$(eval $(call BuildPackage,luci-lib-jsonc))
