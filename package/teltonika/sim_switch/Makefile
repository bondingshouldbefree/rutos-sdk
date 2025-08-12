include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=sim_switch
PKG_VERSION:=2025-07-31
PKG_RELEASE:=1

PKG_SOURCE_VERSION:=7.17
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/sim_switch
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=SIM Switch management daemon
	DEPENDS:=+libubus +libubox +libblobmsg-json +libuci +libgsm +liblog \
			  +libboardjson
	USERID:=sim_switch=502:sim_switch=502
endef

define Package/sim_switch/description
	Package enables automated SIM switching based on specified criteria.
endef

define Package/sim_switch/conffiles
/etc/config/sim_switch
endef


define Package/sim_switch/install
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/usr/bin $(1)/usr/share/acl.d/ $(1)/etc/permtab.d

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/sim_switch.init $(1)/etc/init.d/sim_switch
	$(INSTALL_CONF_USR) $(PKG_BUILD_DIR)/files/sim_switch.conf $(1)/etc/config/sim_switch
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sim_switch $(1)/usr/bin/sim_switch

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/acl.d/sim_switch.json $(1)/usr/share/acl.d/sim_switch.json
	$(CP) $(PKG_BUILD_DIR)/files/permtab.d/sim_switch $(1)/etc/permtab.d/sim_switch

endef

$(eval $(call BuildPackage,sim_switch))

