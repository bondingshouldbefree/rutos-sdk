include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for SNMP application

ifeq (m, $(CONFIG_PACKAGE_vuci-app-snmp-ui))
	APP_TLT_NAME:=SNMP
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=snmp
endif

include ../app.mk

define Package/vuci-app-snmp-ui/description
	SNMP is an SNMP protocol implementation with custom
	Teltonika modules, a unique MIB file and SNMP Traps.
endef

# call BuildPackage - OpenWrt buildroot signature
