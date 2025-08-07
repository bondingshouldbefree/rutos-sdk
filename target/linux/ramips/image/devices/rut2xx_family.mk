define Device/teltonika_rut2x_common
	$(Device/tlt-mt7628-hw-common)
	HARDWARE/Wireless/Wi\-Fi_Users := $(HW_WIFI_50_USERS)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_4)
	HARDWARE/WAN/Port := 1 $(HW_ETH_WAN_PORT)
	HARDWARE/WAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/WAN/Standard := $(HW_ETH_WAN_STANDARD)
	HARDWARE/LAN/Port := 1 $(HW_ETH_LAN_PORT)
	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/Power_Consumption := < 6.5 W Max
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x Connection type status LEDs, 5 x Connection strength LEDs, 2 x LAN status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/SIM := 1 $(HW_INTERFACE_SIM_HOLDER)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 1 x RP-SMA for Wi-Fi antenna connectors
	TECHNICAL/Input_Output/Input := 1 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 1 $(HW_OUTPUT_DO_30V)
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL_PL)
	TECHNICAL/Physical_Specification/Dimensions := 83 x 25 x 74 mm
	TECHNICAL/Physical_Specification/Weight := 125 g
	TECHNICAL/Physical_Specification/Mounting_Options := Bottom and sideways DIN rail mounting slots
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/Mobile/eSIM/Tooltip := $(HW_MOBILE_ESIM_TOOLTIP)
endef

define Device/template_rut2x
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

	DEVICE_FEATURES := mobile wifi ethernet nat_offloading port_link xfrm-offload reset_button
endef

define Device/template_rut2x6_io
	$(Device/teltonika_rute)
	$(Device/template_rut2x)

	DEVICE_SERIAL_CAPABILITIES := \
		"rs232"                                                                                          \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400"                                \
			"5 6 7 8"                                                                                    \
			"xon/xoff none"                                                                              \
			"1 2"                                                                                        \
			"even odd mark space none"                                                                   \
			"none"                                                                                       \
			"/tty/ttyS1",                                                                                \
		"rs485"                                                                                          \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400 460800 921600 1500000 2000000"  \
			"5 6 7 8"                                                                                    \
			"none"                                                                                       \
			"1 2"                                                                                        \
			"even odd mark space none"                                                                   \
			"half"                                                                                       \
			"usb1/1-1/1-1.4/1-1.4:1.0/"
endef

define Device/TEMPLATE_teltonika_rut200
	$(Device/teltonika_rut2m)
	$(Device/teltonika_rut2x_common)
	$(Device/template_rut2x)
	DEVICE_MODEL := RUT200
	DEVICE_FEATURES += ios small_flash
	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/Mobile/Module := 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 9
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, EAC, Anatel, ANRT, Kenya, ICASA, NCC, \
	ETA-WPC, SIRIM, IMDA, NTC, NBTC, MTC NOM, E-mark, CB, RoHS, REACH, R118
	REGULATORY/EMC_Emissions_&_Immunity/Standards := EN 55032:2015 + A1:2020; $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2); \
	$(HW_EI_STANDARDS_EN_61000-3-3); $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.1.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13-V13.1.1)
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), $(HW_SAFETY_EN_5066); RCM:$(HW_SAFETY_AS/NZS_62368); \
	CB: $(HW_SAFETY_IEC_62368-1);
endef

define Device/TEMPLATE_teltonika_rut241
	$(Device/teltonika_rut2m)
	$(Device/teltonika_rut2x_common)
	$(Device/template_rut2x)
	DEVICE_MODEL := RUT241
	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
	DEVICE_FEATURES += esim-p ios small_flash

	HARDWARE/Mobile/Module := 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 10/11
	HARDWARE/Mobile/3GPP_Release/Tooltip := $(HW_MOBILE_3GPP_TOOLTIP)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, ICASA, FCC, IC, PTCRB, NOM, RCM, KC, Giteki, \
	IMDA, E-mark, CB, UL/CSA Safety, RoHS, REACH, R118
	REGULATORY/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile, Uscellula
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); \
	$(HW_EI_STANDARDS_EN_IEC_61000-3-2); $(HW_EI_STANDARDS_EN_61000-3-3); \
	$(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); Final Draft EN 301 489-52 V1.2.0;
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1);
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), EN 50665:201; RCM:$(HW_SAFETY_AS/NZS_62368); \
	CB: $(HW_SAFETY_IEC_62368-1); UL/CSA Safety:UL 62368-1, Ed. 3 dated December 13, 20, CAN/CSA C22.2 No. 62368-1:19
endef

define Device/TEMPLATE_teltonika_rut260
	$(Device/teltonika_rut2m)
	$(Device/teltonika_rut2x_common)
	$(Device/template_rut2x)
	DEVICE_MODEL := RUT260
	DEVICE_FEATURES += ios small_flash
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.4.1

	HARDWARE/Mobile/Module := 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 12
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Power/Power_Consumption := Idle:< 2 W, Max:< 6.5 W
	TECHNICAL/Physical_Interfaces/Status_Leds := 2 x Connection type status, 5 x Mobile connection strength, 1 x LAN status, 1 x WAN status, 1 x Power
	TECHNICAL/Physical_Specification/Weight := 130 g
	TECHNICAL/Physical_Specification/Mounting_Options:= $(HW_PHYSICAL_MOUNTING)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE/RED, UKCA, UCRF, RCM, EAC, WEEE, RCM, R118
endef

define Device/TEMPLATE_teltonika_rut271
	$(Device/teltonika_rute)
	$(Device/teltonika_rut2x_common)
	$(Device/template_rut2x)
	DEVICE_MODEL := RUT271
	DEVICE_FEATURES += ios
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.12.1

	HARDWARE/Mobile/Module := 5G up to 223 DL/ 123 UL Mbps; 4G LTE up to 195 DL/ 105 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 17
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, ICASA, FCC, IC, PTCRB, NOM, RCM, KC, Giteki, \
	IMDA, E-mark, CB, UL/CSA Safety, RoHS, REACH, R118
	REGULATORY/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile, Uscellula
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); \
	$(HW_EI_STANDARDS_EN_IEC_61000-3-2); $(HW_EI_STANDARDS_EN_61000-3-3); \
	$(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); Final Draft EN 301 489-52 V1.2.0;
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1);
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), EN 50665:201; RCM:$(HW_SAFETY_AS/NZS_62368); \
	CB: $(HW_SAFETY_IEC_62368-1); UL/CSA Safety:UL 62368-1, Ed. 3 dated December 13, 20, CAN/CSA C22.2 No. 62368-1:19
endef

define Device/TEMPLATE_teltonika_rut206
	$(Device/template_rut2x6_io)
	DEVICE_MODEL := RUT206
	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
	DEVICE_FEATURES += dual_sim sd_card rs232 rs485

	HARDWARE/Mobile/Module := 4G LTE up to 150 DL/50 UL Mbps; 3G up to 21 DL/ 5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 10/11
	HARDWARE/Mobile/3GPP_Release/Tooltip := $(HW_MOBILE_3GPP_TOOLTIP)
	TECHNICAL/Input_Output/Input :=
	TECHNICAL/Input_Output/Output :=
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_2PIN)
	TECHNICAL/Power/PoE_Standards := $(HW_POWER_POE_PASSIVE_ACTIVE)
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_TRAY)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x Connection type status LEDs, 3 x Connection strength LEDs, 2 x LAN status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_2PIN)
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_6PIN)
	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
	HARDWARE/Serial/RS232 := $(HW_SERIAL_RS232_FLOW)
	HARDWARE/Serial/RS485 := $(HW_SERIAL_RS485_HALF)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem, MODBUS gateway, NTRIP Client
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
endef

define Device/TEMPLATE_teltonika_rut276
	$(Device/template_rut2x6_io)
	DEVICE_MODEL := RUT276
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13.4
	DEVICE_FEATURES += dual_sim sd_card rs232 rs485

	HARDWARE/Mobile/Module := 5G up to 223 DL/ 123 UL Mbps; 4G LTE up to 195 DL/ 105 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 17
	TECHNICAL/Input_Output/Input :=
	TECHNICAL/Input_Output/Output :=
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_2PIN)
	TECHNICAL/Power/PoE_Standards := $(HW_POWER_POE_PASSIVE_ACTIVE)
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_TRAY)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x Connection type status LEDs, 3 x Connection strength LEDs, 2 x LAN status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_2PIN)
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_6PIN)
	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
	HARDWARE/Serial/RS232 := $(HW_SERIAL_RS232_FLOW)
	HARDWARE/Serial/RS485 := $(HW_SERIAL_RS485_HALF)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem, MODBUS gateway, NTRIP Client
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
endef

define Device/TEMPLATE_teltonika_rut281
	$(Device/teltonika_rute)
	$(Device/teltonika_rut2x_common)
	$(Device/template_rut2x)
	DEVICE_MODEL := RUT281
	DEVICE_FEATURES += ios
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.15

	HARDWARE/Mobile/Module := 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 10
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
endef
