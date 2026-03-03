define Device/teltonika_otd5_common
	$(Device/tlt-mt7621-hw-common)
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
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

define Device/template_otd5_common
	$(Device/teltonika_otd5)

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
endef

define Device/TEMPLATE_teltonika_otd500
	$(Device/teltonika_otd5_common)
	$(Device/template_otd5_common)

	DEVICE_MODEL := OTD500
	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
	DEVICE_FEATURES := ethernet mobile dual_sim at_sim dsa hw_nat \
		nat_offloading multi_tag port_link gigabit_port poe xfrm-offload \
		tpm networks_external reset_button dot1x-server

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
endef

define Device/TEMPLATE_teltonika_otd501
	$(Device/teltonika_otd5_common)
	$(Device/template_otd5_common)

	DEVICE_MODEL := OTD501
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13.5
	DEVICE_FEATURES := ethernet mobile dual_sim at_sim dsa hw_nat \
		nat_offloading multi_tag port_link gigabit_port poe xfrm-offload \
		tpm networks_external reset_button dot1x-server

	HARDWARE/Mobile/Module := 5G SA: DL 2Gbps,UL 1Gbps; NSA: DL 2.6Gbps, UL 650 Mbps; 4G LTE: DL 600 Mbps, UL 150 Mbps;
	HARDWARE/Mobile/3GPP_Release := Release 15
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/Mobile/eSIM/Tooltip := $(HW_MOBILE_ESIM_TOOLTIP)
endef
