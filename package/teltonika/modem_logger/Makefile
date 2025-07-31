#
# Copyright (C) 2023 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=modem_logger

PKG_SOURCE_VERSION:=7.16

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/Default
	SECTION:=utils
	CATEGORY:=Utilities
	DEPENDS:=+libusb-1.0 +libstdcpp +libpthread

	PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	PKG_HIDDEN:=1
endef

define Package/$(PKG_NAME)-offline
	$(call Package/$(PKG_NAME)/Default)
	TITLE:=Modem logging tool by Teltonika, all file included
	PKG_TLT_NAME:=Modem Logger Offline
endef

define Package/$(PKG_NAME)
	$(call Package/$(PKG_NAME)/Default)
	TITLE:=Modem logging tool by Teltonika, required files are downloaded automatically
	PKG_TLT_NAME:=Modem Logger
endef

define Package/qlog
	$(call Package/$(PKG_NAME)/Default)
	TITLE:=Modem logging tool for Quectel and Meiglink modems
	PKG_TLT_NAME:=Modem Logger Qlog
endef

define Package/qc_trace_collector
	$(call Package/$(PKG_NAME)/Default)
	TITLE:=Modem logging tool for Telit modems
	PKG_TLT_NAME:=Modem Logger QC Trace Collector
endef

define Package/$(PKG_NAME)-offline/description
	Modem firmware logging tool by Teltonika, all files included
endef

define Package/$(PKG_NAME)/description
	Modem firmware logging tool by Teltonika, required files are downloaded automatically
endef

define Package/qlog/description
	Modem firmware logging tool for Quectel and Meiglink modems
endef

define Package/qc_trace_collector/description
	Modem firmware logging tool fo Telit modems
endef


define Package/$(PKG_NAME)-offline/install
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qlog $(1)/usr/bin/qlog
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_logger.sh $(1)/usr/bin/modem_logger

	#If not one of the listed PLATFORMS install qc_trace_collector
	$(if $(TLT_PLATFORM_TRB2M)$(TLT_PLATFORM_RUT361)$(TLT_PLATFORM_OTD140)$(TLT_PLATFORM_RUT9M)$(TLT_PLATFORM_RUT2M),,
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/qc_trace_collector/qc-trace-collector/linux/qc_trace_collector $(1)/usr/bin/qc_trace_collector
	)

	$(if $(CONFIG_BASEBAND_SUPPORT), \
		$(INSTALL_DIR) $(1)/etc; \
		$(CP) $(PKG_BUILD_DIR)/src/qlog/conf/default.cfg $(1)/etc/modem_logger_default.cfg)
	$(if $(TLT_PLATFORM_RUTM)$(TLT_PLATFORM_RUTE), \
		$(INSTALL_DIR) $(1)/etc; \
		$(CP) $(PKG_BUILD_DIR)/src/qlog/conf/unisoc_ps_dsp_important_log.conf $(1)/etc/unisoc_ps_dsp_important_log.conf; \
		$(CP) $(PKG_BUILD_DIR)/src/qc_trace_collector/filter/QXDM_Mask_default_telit.dmc $(1)/etc/QXDM_Mask_default_telit.dmc)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/modem_logger
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_logger.sh $(1)/usr/bin/modem_logger
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_logger_installer.sh $(1)/usr/share/modem_logger/modem_logger_installer

	$(if $(CONFIG_BASEBAND_SUPPORT), \
		$(INSTALL_DIR) $(1)/etc; \
		$(CP) $(PKG_BUILD_DIR)/src/qlog/conf/default.cfg $(1)/etc/modem_logger_default.cfg)
endef

define Package/qlog/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qlog $(1)/usr/bin/qlog

	$(if $(TLT_PLATFORM_RUTM), \
		$(INSTALL_DIR) $(1)/etc; \
		$(CP) $(PKG_BUILD_DIR)/src/qlog/conf/unisoc_ps_dsp_important_log.conf $(1)/etc/unisoc_ps_dsp_important_log.conf)
endef

define Package/qc_trace_collector/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/qc_trace_collector/qc-trace-collector/linux/qc_trace_collector $(1)/usr/bin/qc_trace_collector

	$(if $(TLT_PLATFORM_RUTM)$(TLT_PLATFORM_RUTE), \
		$(INSTALL_DIR) $(1)/etc; \
		$(CP) $(PKG_BUILD_DIR)/src/qc_trace_collector/filter/QXDM_Mask_default_telit.dmc $(1)/etc/QXDM_Mask_default_telit.dmc)
endef

$(eval $(call BuildPackage,$(PKG_NAME)-offline))
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,qlog))
$(eval $(call BuildPackage,qc_trace_collector))
