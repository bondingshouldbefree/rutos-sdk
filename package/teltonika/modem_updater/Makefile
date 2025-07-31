#
# Copyright (C) 2021 Teltonika
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/download.mk

PKG_NAME:=modem_updater
PKG_SOURCE_VERSION:=7.16

PKG_LICENSE:=Teltonika-closed

include $(INCLUDE_DIR)/package.mk

define Package/modem_updater/Default
	SECTION:=utils
	CATEGORY:=Utilities
	DEPENDS:=+libusb-1.0 +libstdcpp

	PKG_ROUTER:=$(TLT_PLATFORM_NAME)
	PKG_HIDDEN:=1
endef

define Package/modem_updater-offline
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool by Teltonika, all files included
	PKG_TLT_NAME:=Modem Updater Offline
endef
define Package/modem_updater
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool by Teltonika, required files are downloaded automatically
	PKG_TLT_NAME:=Modem Updater
endef

define Package/quectel_flash
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Quectel modems
	PKG_TLT_NAME:=Modem Updater Quectel Flash
endef

define Package/QDLoader
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Quectel modems
	PKG_TLT_NAME:=Modem Updater QDLoader
endef

define Package/Meig_Firehose
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Meiglink modems
	PKG_TLT_NAME:=Modem Updater Meig Firehose
endef

define Package/fbfdownloader
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Meiglink modems
	PKG_TLT_NAME:=Modem Updater FBFDownloader
endef

define Package/uxfp
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Telit modems
	PKG_TLT_NAME:=Modem Updater UXFP
endef

define Package/qdownload
	$(call Package/modem_updater/Default)
	TITLE:=Modem firmware update tool for Eigencomm modems
	PKG_TLT_NAME:=Modem Updater QDownload
endef

define Package/modem_updater-offline/description
	Modem firmware update tool for offline use by Teltonika, all files included
endef
define Package/modem_updater/description
	Modem firmware update tool for online use by Teltonika, required files are downloaded automatically
endef

define Package/quectel_flash/description
	Modem firmware update tool for Quectel modems
endef

define Package/QDLoader/description
	Modem firmware update tool for Quectel modems
endef

define Package/Meig_Firehose/description
	Modem firmware update tool for Meiglink modems
endef

define Package/fbfdownloader/description
	Modem firmware update tool for Meiglink modems
endef

define Package/uxfp/description
	Modem firmware update tool for Telit modems
endef

define Package/qdownload/description
	Modem firmware update tool for Eigencomm modems
endef


define Package/modem_updater-offline/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/permtab.d
	$(if $(findstring Quectel,$(CONFIG_DEVICE_MODEM_VENDORS)),
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel_flash/quectel_flash $(1)/usr/bin/quectel_flash
		$(if $(TLT_PLATFORM_TRB2M)$(TLT_PLATFORM_RUT361),,
			$(INSTALL_BIN) $(PKG_BUILD_DIR)/QDLoader/quectel_loader $(1)/usr/bin/QDLoader
		)
		$(if $(TLT_PLATFORM_TRB2M),
			$(INSTALL_BIN) $(PKG_BUILD_DIR)/qdownload/qdownload $(1)/usr/bin/qdownload
		),
	)
	$(if $(findstring Meiglink,$(CONFIG_DEVICE_MODEM_VENDORS)),
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/Meig_Firehose/meig_firehose $(1)/usr/bin/meig_firehose
		$(if $(TLT_PLATFORM_RUT2M)$(TLT_PLATFORM_RUTE),,
			$(INSTALL_BIN) $(PKG_BUILD_DIR)/fbfdownloader/fbfdownloader $(1)/usr/bin/fbfdownloader
		),
	)
	$(if $(findstring Telit,$(CONFIG_DEVICE_MODEM_VENDORS)),
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/telit_uxfp/uxfp/linux/uxfp $(1)/usr/bin/uxfp
	)
	$(if $(findstring Teltonika,$(CONFIG_DEVICE_MODEM_VENDORS)),
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/fbfdownloader/fbfdownloader $(1)/usr/bin/fbfdownloader
	)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_updater.sh $(1)/usr/bin/modem_updater
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/permtab.d/modem_updater $(1)/etc/permtab.d/modem_updater

endef

define Package/modem_updater/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/usr/share/modem_updater $(1)/etc/permtab.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_updater.sh $(1)/usr/bin/modem_updater
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modem_updater_installer.sh $(1)/usr/share/modem_updater/modem_updater_installer
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/permtab.d/modem_updater $(1)/etc/permtab.d/modem_updater
endef

define Package/quectel_flash/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/quectel_flash/quectel_flash $(1)/usr/bin/quectel_flash
endef
define Package/Meig_Firehose/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/Meig_Firehose/meig_firehose $(1)/usr/bin/meig_firehose
endef
define Package/QDLoader/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/QDLoader/quectel_loader $(1)/usr/bin/QDLoader
	#Only for EC200 RG500
endef
define Package/fbfdownloader/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/fbfdownloader/fbfdownloader $(1)/usr/bin/fbfdownloader
	#Only for SML770
endef
define Package/uxfp/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/telit_uxfp/uxfp/linux/uxfp $(1)/usr/bin/uxfp
endef
define Package/qdownload/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/qdownload/qdownload $(1)/usr/bin/qdownload
	#Only for EG915Q
endef

$(eval $(call BuildPackage,modem_updater-offline))
$(eval $(call BuildPackage,modem_updater))
$(eval $(call BuildPackage,quectel_flash))
$(eval $(call BuildPackage,Meig_Firehose))
$(eval $(call BuildPackage,QDLoader))
$(eval $(call BuildPackage,fbfdownloader))
$(eval $(call BuildPackage,uxfp))
$(eval $(call BuildPackage,qdownload))
