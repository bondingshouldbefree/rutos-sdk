define Package/base-files/install-target
	if [ -d "$(PLATFORM_SUBDIR)/teltonika/boot/$(call device_shortname)" ]; then \
		$(CP) -r $(PLATFORM_SUBDIR)/teltonika/boot/$(call device_shortname)/* $(1)/; \
	fi;

	if [ -e "$(PLATFORM_DIR)/teltonika/sysctl.d/10-default.conf-$(call device_shortname)" ]; then \
		$(CP) $(PLATFORM_DIR)/teltonika/sysctl.d/10-default.conf-$(call device_shortname) $(1)/etc/sysctl.d/10-default.conf; \
	fi;

endef
