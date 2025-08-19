include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Firmware

include ../app.mk

define install_open_gpl
	$(Build/InstallGPL/Default)
	mv $(1)/src/views/system/FwVerifyGPL.vue \
			$(1)/src/views/system/FwVerify.vue
endef


# call BuildPackage - OpenWrt buildroot signature
