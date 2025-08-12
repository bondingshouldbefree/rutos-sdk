include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for I/O Scheduler

ifeq (m, $(CONFIG_PACKAGE_vuci-app-io-scheduler-ui))
	APP_TLT_NAME:=I/O Scheduler
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=io_scheduler
	APP_HW_INFO:=ios
endif

include ../app.mk

define Package/vuci-app-io-scheduler-ui/description
	I/O Scheduler package which can be used to configure a 
	timetable of when an pin state should change, 
	based on days of the week or month and hours of the day. 
endef

# call BuildPackage - OpenWrt buildroot signature

