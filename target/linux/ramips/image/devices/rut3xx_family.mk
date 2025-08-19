define Device/TEMPLATE_teltonika_rut301
	$(Device/tlt-mt7628-hw-common)
	$(Device/teltonika_rut301)

	DEVICE_SWITCH_CONF := switch0 0:lan:1 1:lan:2 \
		2:lan:3 3:lan:4 4:wan 6@eth0

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false vlan

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 2,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_USB_JACK_PATH := /usb1/1-1/

	DEVICE_USB_JACK_PATH_LOW_SPEED := /usb2/2-1/

	DEVICE_FEATURES := usb ethernet ios nat_offloading port_link xfrm-offload small_flash reset_button 128mb_ram

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M) $(HW_FLASH_TYPE_NOR_SERIAL)
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	HARDWARE/WAN/Port := 1 $(HW_ETH_WAN_PORT)
  	HARDWARE/WAN/Speed := $(HW_ETH_SPEED_100)
  	HARDWARE/WAN/Standard := $(HW_ETH_WAN_STANDARD)
  	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
  	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_100)
  	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/PoE_Standards := $(HW_POWER_POE_INSTALL)
	TECHNICAL/Power/Power_Consumption := Idle:< 0.8 W, Max:< 3.8 W
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_4PIN_IOS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x WAN type LED, 4 x LAN status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/USB := 1 $(HW_INTERFACE_USB)
	HARDWARE/USB/Data_Rate := $(HW_USB_2_DATA_RATE)
	HARDWARE/USB/Applications := $(HW_USB_APPLICATIONS)
	HARDWARE/USB/External_Devices := $(HW_USB_EXTERNAL_DEV)
	HARDWARE/USB/Storage_Formats := $(HW_USB_STORAGE_FORMATS)
	TECHNICAL/Input_Output/Input := 2 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 2 $(HW_OUTPUT_DO_40V)
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL)
	TECHNICAL/Physical_Specification/Dimensions := 100 x 30 x 85 mm
	TECHNICAL/Physical_Specification/Weight := 233 g
	TECHNICAL/Physical_Specification/Mounting_Options := $(HW_PHYSICAL_MOUNTING)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, FCC, IC, CB, EAC, UCRF, WEEE
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x WAN type LED, 4 x LAN status LEDs, 1 x Power LED
endef

define Device/TEMPLATE_teltonika_rut361
	$(Device/tlt-mt7628-hw-common)
	$(Device/teltonika_rut361)

	DEVICE_SWITCH_CONF := switch0 1:lan 0:wan:2 6@eth0

	DEVICE_WLAN_BSSID_LIMIT := wlan0 4

	DEVICE_CHECK_PATH := usb_check /sys/bus/usb/drivers/usb/1-1 reboot

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false vlan

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 2,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_FEATURES := mobile wifi ios ethernet nat_offloading port_link xfrm-offload small_flash reset_button 128mb_ram

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/Mobile/Module := 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 12
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M) $(HW_FLASH_TYPE_NOR_SERIAL)
	HARDWARE/Wireless/Wireless_Mode := 802.11 b/g/n, 2x2 MIMO
	HARDWARE/Wireless/Wi\-Fi_Users := $(HW_WIFI_50_USERS)
	HARDWARE/WAN/Port := 1 $(HW_ETH_WAN_PORT)
	HARDWARE/WAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/WAN/Standard := $(HW_ETH_WAN_STANDARD)
	HARDWARE/LAN/Port := 1 $(HW_ETH_LAN_PORT)
	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/PoE_Standards := $(HW_POWER_POE_INSTALL)
	TECHNICAL/Power/Power_Consumption := Idle:< 2.4 W, Max:< 4.7 W
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_4PIN_IOS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 2 x Mobile connection type, 3 x Mobile connection strength, 2 x Eth status, 1 x Power
	TECHNICAL/Physical_Interfaces/SIM := 1 $(HW_INTERFACE_SIM_HOLDER)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi
	TECHNICAL/Input_Output/Input := 2 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 2 $(HW_OUTPUT_DO_30V)
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL)
	TECHNICAL/Physical_Specification/Dimensions := 100 x 30 x 85 mm
	TECHNICAL/Physical_Specification/Weight := 243 g
	TECHNICAL/Physical_Specification/Mounting_Options := $(HW_PHYSICAL_MOUNTING)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, UCRF, EAC, WEEE, CB
endef
