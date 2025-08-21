include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support Dynamic routes eigrp application

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dynamic-routes-eigrp-ui))
	APP_APP_NAME:=frr-eigrpd
	APP_TLT_NAME:= EIGRP daemon
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-dynamic-routes-eigrp-ui/description
	Enhanced Interior Gateway Routing Protocol (EIGRP) is an
	advanced distance-vector routing protocol that is used on a
	computer network for automating routing decisions and configuration.
endef

# call BuildPackage - OpenWrt buildroot signature
