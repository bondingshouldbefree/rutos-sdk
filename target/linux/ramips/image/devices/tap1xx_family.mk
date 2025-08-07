define Device/TEMPLATE_teltonika_tap100
	$(Device/tlt-mt7628-hw-common)
	$(Device/teltonika_tap100)

	DEVICE_NET_CONF :=       \
		ula           false, \
		disable_vlan  true,  \
		ip6assign     false, \
		vlans         16,    \
		no_metric     true,  \
		max_mtu       1500

	DEVICE_WLAN_BSSID_LIMIT := wlan0 4

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.3 device eth0 ipv6 0 fallback 1 proto dhcp, \
		dhcp6 device br-lan proto dhcpv6

	DEVICE_FEATURES := access_point wifi ethernet sw_rst_on_init single_port small_flash reset_button

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/System_Characteristics/RAM := $(HW_RAM_SIZE_64M) $(HW_RAM_TYPE_DDR2)
	HARDWARE/Ethernet/Port :=1 $(HW_ETH_RJ45_PORT)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/Ethernet/Standard := $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_4), 2x2 MIMO
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_RJ45)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_POE_2)
	TECHNICAL/Power/PoE_Standards := $(HW_POE_STD_80203AF)
	TECHNICAL/Power/Power_Consumption := < 2 W Max
	TECHNICAL/Physical_Interfaces/Power :=
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/Ethernet := 1 $(HW_ETH_RJ45_PORT), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x Power LED, 1 x ETH status LED
	TECHNICAL/Physical_Interfaces/Antennas := 2 x Internal for 2.4 GHz Wi-Fi
	TECHNICAL/Physical_Interfaces/Antennas_Specifications := 2 x 2400 - 2500 MHz, 50 Ω, VSWR <2.7, gain < 4.9 dBi, omnidirectional
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_UV_PLASTIC)
  	TECHNICAL/Physical_Specification/Dimensions := 158 mm x 30 mm
  	TECHNICAL/Physical_Specification/Weight := 190 g
  	TECHNICAL/Physical_Specification/Mounting_Options := AP Mounting Bracket (for ceiling mount)
	TECHNICAL/Operating_Environment/Operating_Temperature := $(HW_OPERATING_TEMP)
  	TECHNICAL/Operating_Environment/Operating_Humidity := $(HW_OPERATING_HUMIDITY)
  	TECHNICAL/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP30)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory :=  CE, UKCA, CB, FCC, IC, WEEE
	REGULATORY/EMC_Emissions_&_Immunity/Standards := EN 55032:2015+A11:2020; \
	EN 55035:2017+A11:2020; EN 61000-3-3:2013+A1:2019+A2:2021;\
	$(HW_EI_STANDARDS_EN_IEC_61000-3-2)+A1:2021; $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4);
  	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
  	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
  	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
  	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
  	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
  	REGULATORY/EMC_Emissions_&_Immunity/DIP := EN IEC 61000-4-11:2020
  	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2)
	REGULATORY/Safety/Standards := IEC 62368-1:2018; EN IEC 62368-1:2020+A11:2020; EN IEC 62311:2020;
endef
