define Device/teltonika_trb2m_common
	$(Device/tlt-mt7628-hw-common)
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	HARDWARE/Ethernet/Port :=1 $(HW_ETH_ETH_PORT)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/Ethernet/Standard := $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/Mobile/3GPP_Release := Release 11
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_16PIN)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_16PIN)
	TECHNICAL/Power/PoE_Standards :=
	TECHNICAL/Physical_Interfaces/Ethernet := 1 $(HW_ETH_RJ45_PORT), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_16PIN)
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_16PIN)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 1 x power LED, 1 x Eth port status LED
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_TRAY)
	TECHNICAL/Physical_Interfaces/Antennas := 1 x SMA connector for LTE, 1 x SMA connector for GNSS
	TECHNICAL/Physical_Interfaces/RS232 := $(HW_INTERFACE_RS232_4PIN)
	TECHNICAL/Physical_Interfaces/RS485 := $(HW_INTERFACE_RS485_4PIN)
	TECHNICAL/Input_Output/Input := 3 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 3 $(HW_OUTPUT_DO_30V)
	HARDWARE/Serial/RS232 := Terminal block connector:TX, RX, RTS, CTS
	HARDWARE/Serial/RS485 := Terminal block connector:D+, D-, R+, R- (2 or 4 wire interface)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem, MODBUS gateway, NTRIP Client
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL)
	TECHNICAL/Physical_Specification/Dimensions := 83 x 25 x 74.2 mm
	TECHNICAL/Physical_Specification/Weight := 165 g
	TECHNICAL/Physical_Specification/Mounting_Options := $(HW_PHYSICAL_MOUNTING)
endef

define Device/template_trb2m
	$(Device/teltonika_trb2m)

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan device eth0 default_ip 192.168.1.1

	DEVICE_FEATURES := gateway dual_sim mobile gps ethernet ios modbus rs232 rs485 \
		sw_rst_on_init xfrm-offload nat_offloading small_flash reset_button 128mb_ram \
		dot1x-server dot1x-client single_port port_link

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false single_port

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
endef

define Device/TEMPLATE_teltonika_trb236
	$(Device/teltonika_trb2m_common)
	$(Device/template_trb2m)
	DEVICE_MODEL := TRB236

	DEVICE_FEATURES := gateway dual_sim mobile ethernet ios rs232 rs485 \
		sw_rst_on_init xfrm-offload nat_offloading small_flash reset_button \
		128mb_ram port_link

	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.21.1
	HARDWARE/Mobile/Module := 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps;
	TECHNICAL/Physical_Interfaces/Status_Leds := 2 x connection status LEDs, 3 x connection strength LEDs, 1 x power LED, 1 x Eth port status LED
	TECHNICAL/Physical_Interfaces/Antennas := 1 x SMA connector for LTE
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, CB, WEEE
endef

define Device/TEMPLATE_teltonika_trb246
	$(Device/teltonika_trb2m_common)
	$(Device/template_trb2m)
	DEVICE_MODEL := TRB246

	HARDWARE/Mobile/Module := 4G LTE up to 150 DL/50 UL Mbps; 3G up to 42 DL/5.76 UL Mbps; 2G up to 296 DL/236.8 UL Kbps
	TECHNICAL/Power/Power_Consumption := Idle:< 1.5 W, Max:< 3.5 W
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, CB, EAC, UCRF, WEEE
endef

define Device/TEMPLATE_teltonika_trb247
	$(Device/teltonika_trb2m_common)
	$(Device/template_trb2m)
	DEVICE_MODEL := TRB247

	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13
	HARDWARE/Mobile/Module := 4G LTE Cat 1 up to 10 DL/5 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 14
endef

define Device/TEMPLATE_teltonika_trb256
	$(Device/teltonika_trb2m_common)
	$(Device/template_trb2m)
	DEVICE_MODEL := TRB256

	HARDWARE/Mobile/Module := 4G LTE Cat M1 up to 588 DL/ 1119 UL Kbps, Cat NB2 up to 127 DL/158.5 UL Kbps, Cat NB1 up to 32 DL/70 UL Kbps \
							(simultaneous operation of cellular and GNSS connectivity is not supported)
	HARDWARE/Mobile/3GPP_Release := Release 14
	TECHNICAL/Power/Power_Consumption := Idle:< 2 W, Max:< 35 W
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, EAC, CB
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032) + A1:2020; $(HW_EI_STANDARDS_EN_55035); EN IEC 61000-3-2:2019 + A1:2021; \
	EN 61000-3-3:2013 + A1:2019 + A2:2021; $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); EN 301 489-19 V2.2.1; $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-13_V13.2.1); EN 303 413 V1.2.1;
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311); RCM:$(HW_SAFETY_AS/NZS_62368); CB:$(HW_SAFETY_IEC_62368-1);
endef

define Device/TEMPLATE_teltonika_ntp001
	$(Device/tlt-mt7628-hw-common)
	$(Device/teltonika_trb2m)
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	TECHNICAL/Power/PoE_Standards :=
	TECHNICAL/Physical_Interfaces/SIM :=
	HARDWARE/Ethernet/Port :=1 $(HW_ETH_ETH_PORT)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/Ethernet/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_16PIN)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_16PIN)
	TECHNICAL/Physical_Interfaces/Ethernet := 1 $(HW_ETH_RJ45_PORT), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_16PIN)
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_16PIN)
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x Power, 2x GNSS status LEDs, 1x NTP Server status LED, 3 x IO status LEDs
	TECHNICAL/Physical_Interfaces/Antennas := 1 x SMA connector for GNSS
	TECHNICAL/Physical_Interfaces/RS232 := $(HW_INTERFACE_RS232_4PIN)
	TECHNICAL/Physical_Interfaces/RS485 := $(HW_INTERFACE_RS485_4PIN)
	TECHNICAL/Input_Output/Input := 3 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 3 $(HW_OUTPUT_DO_30V)
	HARDWARE/Serial/RS232 := Terminal block connector:TX, RX, RTS, CTS
	HARDWARE/Serial/RS485 := Terminal block connector:D+, D-, R+, R- (2 or 4 wire interface)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, MODBUS gateway, NTRIP Client
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AND_PANELS_AL)
	TECHNICAL/Physical_Specification/Dimensions := 82.6 x 25 x 83 mm
	TECHNICAL/Physical_Specification/Weight := 180 g
	TECHNICAL/Physical_Specification/Mounting_Options := $(HW_PHYSICAL_MOUNTING)
	TECHNICAL/Power/Power_Consumption := Idle:< 2 W, Max:< 3.5 W
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, CB, UCRF, EAC, WEEE
	DEVICE_MODEL := NTP001
	DEVICE_FEATURES := gateway dual_sim mobile gps ethernet ios modbus rs232 rs485 \
		sw_rst_on_init xfrm-offload nat_offloading small_flash reset_button 128mb_ram \
		dot1x-client dot1x-server single_port
endef
