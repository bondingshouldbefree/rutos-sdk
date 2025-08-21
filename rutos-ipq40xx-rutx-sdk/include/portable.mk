#
# Copyright (C) 2023 Teltonika-Networks
#

# export Kconfig option to CPPFLAGS
# 1 -> Kconfig option name
# 2 -> define option name (optional)
define export_feature
TARGET_CPPFLAGS+=$(if $(value $1),-D$(if $(2),$(2),$(subst CONFIG_,,$(1))))
endef

# export TLT_PLATFORM_<device_name> variable
# device name is taken from device shortname and converted into all-capital letters
# additionally double `x` letters are removed (rut9xx becomes rut9)
# note: this variable is deprecated
TLT_DEV_NAME:=$(call toupper,$(subst xx,,$(call device_shortname)))
export TLT_PLATFORM_$(TLT_DEV_NAME):=y

# export TLT_PLATFORM_NAME variable
# it is based off the same variable used by TLT_PLATFORM_<device_name>
# however some devices must have `0` instead of `X` at the end: RUT300/RUT360
# note: this variable is deprecated
export TLT_PLATFORM_NAME:=$(subst 6X,60,$(subst 0X,00,$(TLT_DEV_NAME)))

TARGET_CPPFLAGS += -D$(TLT_PLATFORM_NAME)_PLATFORM

# Export the modified variable
TARGET_CPPFLAGS += -DDEVICE_MODEM_VENDORS="$(subst $(space),$(comma),$(CONFIG_DEVICE_MODEM_VENDORS))"
TARGET_CPPFLAGS += -DDEVICE_MODEM_LIST="$(subst $(space),$(comma),$(CONFIG_DEVICE_MODEM_LIST))"

$(eval $(call export_feature,CONFIG_GATEWAY_DEVICE))
$(eval $(call export_feature,CONFIG_HAS_SINGLE_ETH_PORT,SINGLE_ETH_PORT))
$(eval $(call export_feature,CONFIG_MOBILE_SUPPORT))
$(eval $(call export_feature,CONFIG_DUAL_SIM_SUPPORT))
$(eval $(call export_feature,CONFIG_GPS_SUPPORT))
$(eval $(call export_feature,CONFIG_BLUETOOTH_SUPPORT))
$(eval $(call export_feature,CONFIG_WIFI_SUPPORT))
$(eval $(call export_feature,CONFIG_IO_SUPPORT))
$(eval $(call export_feature,CONFIG_POWER_CONTROL_SUPPORT))
$(eval $(call export_feature,CONFIG_BASEBAND_SUPPORT))
$(eval $(call export_feature,CONFIG_DSA_SUPPORT))
$(eval $(call export_feature,CONFIG_PPP_MOBILE_SUPPORT))
$(eval $(call export_feature,CONFIG_USB_SUPPORT_EXTERNAL))
$(eval $(call export_feature,CONFIG_USES_VENDOR_WIFI_DRIVER))
$(eval $(call export_feature,CONFIG_BACNET_MODULE_SUPPORT))
$(eval $(call export_feature,CONFIG_HNAT))
$(eval $(call export_feature,CONFIG_MBUS))
$(eval $(call export_feature,CONFIG_HW_OFFLOAD))
$(eval $(call export_feature,CONFIG_PCMCIA_SUPPORT))
$(eval $(call export_feature,CONFIG_BASIC_ROUTER))
$(eval $(call export_feature,CONFIG_WPS_SUPPORT))
$(eval $(call export_feature,CONFIG_POE_SUPPORT))
$(eval $(call export_feature,CONFIG_SWITCH_DEVICE))
$(eval $(call export_feature,CONFIG_MODEM_RESET_QUIRK))
$(eval $(call export_feature,CONFIG_HAS_DOWNSTREAM_KERNEL))
$(eval $(call export_feature,CONFIG_BYPASS_MOBILE_COUNTERS))
$(eval $(call export_feature,CONFIG_CUSTOM_DATA_LIMIT))
$(eval $(call export_feature,CONFIG_USES_SOFT_PORT_MIRROR))
$(eval $(call export_feature,CONFIG_NO_WIRED_WAN))
$(eval $(call export_feature,CONFIG_PROD_IMAGE))
