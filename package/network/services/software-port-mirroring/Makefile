include $(TOPDIR)/rules.mk

PKG_NAME:=software-port-mirroring
PKG_RELEASE:=2
PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/software-port-mirroring
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Software Port Mirroring
  PKGARCH:=all
  DEPENDS=+tc +ebtables
endef

define Package/software-port-mirroring/description
 Provides Port Mirroring support where there is no hardware support for it.
endef

define Package/software-port-mirroring/conffiles
/etc/config/port_mirroring
endef



define Package/software-port-mirroring/install
	$(INSTALL_DIR) $(1)/etc/init.d/ $(1)/etc/config/ $(1)/usr/sbin/ $(1)/usr/share/port_mirroring $(1)/etc/permtab.d
	$(INSTALL_BIN) ./files/port_mirroring.init $(1)/etc/init.d/port_mirroring
	$(INSTALL_DATA) ./files/port_mirroring.config $(1)/etc/config/port_mirroring
	$(INSTALL_BIN) ./files/port_mirroring.sh $(1)/usr/sbin/port_mirroring.sh
	$(INSTALL_BIN) ./files/port_mirroring.permtab $(1)/etc/permtab.d/port_mirroring
	$(INSTALL_BIN) ./files/port_mirroring.hotplug $(1)/usr/share/port_mirroring/99-port_mirroring.hotplug
endef

$(eval $(call BuildPackage,software-port-mirroring))
