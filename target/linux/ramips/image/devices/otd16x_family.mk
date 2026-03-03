define Device/TEMPLATE_teltonika_otd164
	$(Device/tlt-mt7621-hw-common)
	$(Device/teltonika_otd16x)

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        2030, \
		readonly_vlans 1,    \
		vlans          4094

	DEVICE_LAN_OPTION := "lan1 lan2"

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_POE_CONF := 2 1 _lan2 3 15400

	DEVICE_POE_CHIP := 0X77 0:_lan2, 0X2F 1:_lan2

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	DEVICE_CHECK_PATH := pcie_check /sys/class/pci_bus/0000:00 reboot , usb_check /sys/bus/usb/drivers/usb/2-1 reboot

	DEVICE_MODEL := OTD164
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.19

	DEVICE_FEATURES := ncm poe wifi at_sim mobile networks_external tpm reset_button dual_sim ethernet nat_offloading port_link xfrm-offload dot1x-server dsa hw_nat multi_tag gigabit_port tlt-failsafe-boot portlink hw-offload modem-reset-quirk framed-routing no-wired-wan dual_band_ssid

	DEVICE_WLAN_BSSID_LIMIT := wlan0 8, wlan1 8

	HARDWARE/Mobile/Module := 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 10
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_5)
	HARDWARE/Ethernet/Port := 2 $(HW_ETH_ETH_PORTS)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_1000)
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
