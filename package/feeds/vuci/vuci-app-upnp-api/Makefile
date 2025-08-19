include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI API Support for UPnP

APP_DEPENDS:=+miniupnpd

define Package/vuci-app-upnp-api/prerm
#!/bin/sh
	uci -q get firewall.miniupnpd > /dev/null || exit 0
	uci -q delete firewall.miniupnpd
	uci -q commit firewall
	/etc/init.d/firewall reload
	exit 0
endef

include ../api.mk

# call BuildPackage - OpenWrt buildroot signature
