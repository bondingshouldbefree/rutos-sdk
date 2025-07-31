include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support Dynamic routes nhrp application

ifeq (m, $(CONFIG_PACKAGE_vuci-app-dynamic-routes-nhrp-ui))
	APP_APP_NAME:=frr-nhrp
	APP_TLT_NAME:= NHRP daemon
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
endif

include ../app.mk

define Package/vuci-app-dynamic-routes-nhrp-ui/description
	Next Hop Resolution Protocol (NHRP) is a protocol or method that can
	be used so that a computer sending data to another computer can learn
	the most direct route (the fewest number of hops) to the receiving computer. 
endef

# call BuildPackage - OpenWrt buildroot signature
