include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Port mirroring

ifeq (m, $(CONFIG_PACKAGE_vuci-app-port-mirroring-ui))
	APP_TLT_NAME:=Port Mirroring
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=port_mirroring
endif

NO_API_DEPEND:=y
ifneq ($(CONFIG_USES_SOFT_PORT_MIRROR),)
	APP_DEPENDS:=+vuci-app-software-port-mirroring-api
	APP_HW_INFO:=soft_port_mirror
endif

include ../app.mk

define Package/vuci-app-port-mirroring-ui/description
	Port mirroring is used on a network switch to send a copy of network packets seen on one switch 
	port to a network monitoring connection on another switch port
endef

# call BuildPackage - OpenWrt buildroot signature