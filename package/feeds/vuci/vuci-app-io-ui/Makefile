include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for I/O

CUSTOM_INSTALL=1
include ../app.mk


define SelectPinoutIcon
	$(INSTALL_DIR) $(1)/www/icons ; \
	$(CP) ./pinout-icons/$(2) $(1)/www/icons/; \
	gzip -f $(1)/www/icons/$(2);
endef

define Package/$(PKG_NAME)/install
	$(call Package/$(PKG_NAME)/install/Default,$(1))
	if [ $(TLT_PLATFORM_TRB1) ]; then \
		$(call SelectPinoutIcon,$(1),io_16pin.svg) \
	elif [ $(TLT_PLATFORM_TRB2M) ]; then \
		$(call SelectPinoutIcon,$(1),io_16pin_rs.svg) \
	elif [ $(TLT_PLATFORM_RUTM) ]; then \
		$(call SelectPinoutIcon,$(1),io_16pin_rs_rutm.svg) \
	elif [ $(TLT_PLATFORM_RUT9) ] || [ $(TLT_PLATFORM_RUT9M) ] || [ $(TLT_PLATFORM_RUTE) ]; then \
		$(call SelectPinoutIcon,$(1),io_10pin.svg) \
	fi;
endef

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
