define Device/teltonika_otd1xx_common
	$(Device/tlt-mt7628-hw-common)
	HARDWARE/Mobile/Module := 4G LTE up to 150 DL/50 UL Mbps; 3G up to 21 DL/ 5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Ethernet/Port := 2 $(HW_ETH_ETH_PORTS)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/Power/Connector := $(HW_POWER_CONNECTOR_RJ45)
	HARDWARE/Power/Input_voltage_range := $(HW_POWER_VOLTAGE_RJ45)
	HARDWARE/Power/PoE_Standards :=
	HARDWARE/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_RJ45)
	HARDWARE/Physical_Interfaces/IO:=
	HARDWARE/PoE_In/PoE_ports := 1 x PoE In
	HARDWARE/PoE_In/PoE_standards := 802.3af/at
	HARDWARE/PoE_Out/PoE_ports := 1 x PoE Out
	HARDWARE/PoE_Out/PoE_standards := 802.3af and 802.3at Alternative B
	HARDWARE/PoE_Out/PoE_Max_Power_per_Port_(at_PSE) := 24 W Max (power supply unit dependent)
	HARDWARE/Physical_Specification/Casing_material := Plastic (PC+ASA)
	HARDWARE/Physical_Specification/Dimensions := 110 x 49.30 x 235 mm
	HARDWARE/Physical_Specification/Weight := 855 g
	HARDWARE/Physical_Specification/Mounting_options := Mounting Bracket (for vertical flat surface or pole mounting)
endef

define Device/template_otd1xx

	DEVICE_SWITCH_CONF := switch0 4:lan:1 1:lan:2 6@eth0

	DEVICE_WLAN_BSSID_LIMIT := wlan0 4

	DEVICE_CHECK_PATH := usb_check /sys/bus/usb/drivers/usb/1-1 reboot

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 2,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_POE_CONF := 2 1 _lan1 3 15400

	DEVICE_POE_CHIP := 0X77 0:_lan1, 0X2F 1:_lan1

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false vlan

	DEVICE_FEATURES := dual_sim mobile ethernet nat_offloading poe \
		port_link xfrm-offload networks_external reset_button 128mb_ram
endef

define Device/TEMPLATE_teltonika_otd140
	$(Device/tlt-mt7628-hw-common)
	$(Device/teltonika_otd140)

	DEVICE_SWITCH_CONF := switch0 4:lan:1 1:lan:2 6@eth0

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 1,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_POE_CONF := 2 1 _lan1 3 15400

	DEVICE_POE_CHIP := 0X77 0:_lan1, 0X2F 1:_lan1

	DEVICE_FEATURES := dual_sim mobile ethernet nat_offloading poe \
		port_link xfrm-offload networks_external small_flash reset_button

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/Mobile/Module := 4G LTE up to 150 DL/50 UL Mbps; 3G up to 21 DL/ 5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 9
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M) $(HW_FLASH_TYPE_NOR_SERIAL)
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	HARDWARE/Ethernet/Port := 2 $(HW_ETH_ETH_PORTS)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/Ethernet/Standard := (can be configured as WAN), $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_RJ45)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_RJ45)
	TECHNICAL/Power/PoE_Standards :=
	TECHNICAL/Power/Power_Consumption := Idle: < 2.5 W / Max: < 6 W / PoE Max < 21 W
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_RJ45)
	TECHNICAL/Physical_Interfaces/IO:=
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x Mobile connection type, 3 x Mobile connection strength, 4 x ETH status LEDs
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_TRAY)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x Internal antennas
	TECHNICAL/Physical_Interfaces/Antennas_Specifications := 1 x 698 - 960 / 1710 - 2690MHz, 50 Ω, VSWR <3.5, gain <3 dBi, omnidirectional; \
	1 x 698 - 960 / 1710 - 2690MHz, 50 Ω, VSWR <3, gain <4.5 dBi, omnidirectional;
	TECHNICAL/PoE_In/PoE_Ports := 1 x PoE In
	TECHNICAL/PoE_In/PoE_Standards := 802.3af/at
	TECHNICAL/PoE_Out/PoE_Ports := 1 x PoE Out
	TECHNICAL/PoE_Out/PoE_Standards := 802.3af and 802.3at Alternative B
	TECHNICAL/PoE_Out/PoE_Max_Power_per_Port_(at_PSE) := 24 W Max (power supply unit dependent)
	TECHNICAL/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP55)
	TECHNICAL/Physical_Specification/Casing_Material := Plastic (PC+ASA)
	TECHNICAL/Physical_Specification/Dimensions := 110 x 49.30 x 235 mm
	TECHNICAL/Physical_Specification/Weight := 855 g
	TECHNICAL/Physical_Specification/Mounting_Options := Mounting Bracket (for vertical flat surface or pole mounting)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, EAC, UCRF, RCM
endef

define Device/TEMPLATE_teltonika_otd144
	$(Device/teltonika_rute)
	$(Device/teltonika_otd1xx_common)
	$(Device/template_otd1xx)

	DEVICE_MODEL := OTD144
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.15.1

	DEVICE_FEATURES += large_flash wifi dual_sim mobile ethernet nat_offloading poe \
		port_link xfrm-offload networks_external 128mb_ram

	HARDWARE/Mobile/3GPP_Release := Release 9
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M) $(HW_FLASH_TYPE_NOR_SERIAL)
	HARDWARE/Ethernet/Standard := (can be configured as WAN), $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/Power/Power_consumption := Idle: < 2.5 W / Max: < 6 W / PoE Max < 21 W
	HARDWARE/Physical_Interfaces/Status_leds := 3 x Mobile connection type, 3 x Mobile connection strength, 4 x ETH status LEDs
	HARDWARE/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_TRAY)
	HARDWARE/Physical_Interfaces/Antennas := 2 x Internal antennas, 2 x Internal for 2.4 GHz Wi-Fi
	HARDWARE/Physical_Interfaces/Antennas_specifications := 1 x 698 - 960 / 1710 - 2690MHz, 50 Ω, VSWR <3.5, gain <3 dBi, omnidirectional; \
	1 x 698 - 960 / 1710 - 2690MHz, 50 Ω, VSWR <3, gain <4.5 dBi, omnidirectional;
	HARDWARE/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP55)
	HARDWARE/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, EAC, UCRF, RCM
endef
