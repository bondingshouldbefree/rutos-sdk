include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for MPLS

ifeq (m, $(CONFIG_PACKAGE_vuci-app-mpls-ui))
	APP_TLT_NAME:=MPLS
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=mpls
endif

include ../app.mk

define Package/vuci-app-mpls-ui/description
	Multiprotocol Label Switching (MPLS) is a routing technique that uses labels instead of network addresses for routing decisions 
endef

# call BuildPackage - OpenWrt buildroot signature
