include $(TOPDIR)/rules.mk

PKG_LICENSE:=Teltonika-nda-source

APP_TITLE:=VuCI UI Support for SIM Idle protection

ifeq (m, $(CONFIG_PACKAGE_vuci-app-sim-idle-protection-ui))
	APP_APP_NAME:=sim_idle_protection
	APP_TLT_NAME:=SIM Idle Protection
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_HW_INFO:=dual_sim/esim
endif

define Package/vuci-app-sim-idle-protection-ui/description
	Package enabling periodic switching to a secondary SIM card for data
	connection, preventing SIM card blockage due to inactivity.
endef

include ../app.mk

# call BuildPackage - OpenWrt buildroot signature
