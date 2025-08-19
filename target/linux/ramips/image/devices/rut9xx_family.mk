define Device/teltonika_rut9x_common
	$(Device/tlt-mt7628-hw-common)
	HARDWARE/Mobile/Module := 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/Mobile/eSIM/Tooltip := $(HW_MOBILE_ESIM_TOOLTIP)
	HARDWARE/WAN/Port := 1 $(HW_ETH_WAN_PORT)
	HARDWARE/WAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/WAN/Standard := $(HW_ETH_WAN_STANDARD)
	HARDWARE/LAN/Port := 3 $(HW_ETH_LAN_PORTS)
	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_STANDARD)
	TECHNICAL/Power/Power_Consumption := < 2 W idle, < 7 W Max
	TECHNICAL/Physical_Interfaces/Ethernet := 4 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x Bi-color connection status, 5 x Mobile connection strength, 4 x ETH status, 1 x Power
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL_PL)
	TECHNICAL/Physical_Specification/Dimensions := 110 x 50 x 100 mm
	TECHNICAL/Physical_Specification/Weight := 287 g
	TECHNICAL/Physical_Specification/Mounting_Options := DIN rail (can be mounted on two sides), flat surface placement
endef

define Device/template_rut9x

	DEVICE_SWITCH_CONF := switch0 0:lan:1 1:lan:2 2:lan:3 4:wan 6@eth0

	DEVICE_WLAN_BSSID_LIMIT := wlan0 4

	DEVICE_CHECK_PATH := usb_check /sys/bus/usb/drivers/usb/1-1 reboot

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 2,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false vlan

	DEVICE_FEATURES := dual_sim ios mobile nat_offloading port_link \
		wifi ethernet xfrm-offload soft_port_mirror reset_button 128mb_ram
endef

define Device/template_rut9x_io

	DEVICE_USB_JACK_PATH := /usb1/1-1/1-1.1/
	DEVICE_FEATURES += usb gps rs232 rs485

	DEVICE_SERIAL_CAPABILITIES := \
		"rs232"                                                           \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200"        \
			"5 6 7 8"                                                     \
			"rts/cts xon/xoff none"                                       \
			"1 2"                                                         \
			"even odd mark space none"                                    \
			"none"                                                        \
			"/usb1/1-1/1-1.3/",                                           \
		"rs485"                                                           \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400" \
			"5 6 7 8"                                                     \
			"xon/xoff none"                                               \
			"1 2"                                                         \
			"even odd mark space none"                                    \
			"half full"                                                   \
			"/tty/ttyS1"
endef

define Device/TEMPLATE_teltonika_rut901
	$(Device/teltonika_rut9m)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	DEVICE_MODEL := RUT901
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.3.1
	DEVICE_FEATURES += small_flash

	HARDWARE/Mobile/3GPP_Release := Release 9
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi antenna connectors
	TECHNICAL/Input_Output/Input := 1 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 1 $(HW_OUTPUT_DO_30V)
	TECHNICAL/Physical_Specification/Weight := 297 g
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, IMDA, Anatel, RCM, E-mark, ECE R118, CB, RoHS, REACH, NCC
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032) + A1:2020; $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2);\
	$(HW_EI_STANDARDS_EN_61000-3-3) + A2:2021; $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); \
	$(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.1.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13-V13.1.1);
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), $(HW_SAFETY_EN_5066); \
	CB:$(HW_SAFETY_IEC_62368-1); RCM:$(HW_SAFETY_AS/NZS_62368);
endef

define Device/TEMPLATE_teltonika_rut906
	$(Device/teltonika_rut9m)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	$(Device/template_rut9x_io)
	DEVICE_MODEL := RUT906
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.4.2
	DEVICE_FEATURES += small_flash

	HARDWARE/Mobile/3GPP_Release := Release 9
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_10PIN)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNSS
	TECHNICAL/Physical_Interfaces/Input_Output := 1 x 10-pin industrial socket for inputs/outputs
	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_DB9)
	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
	TECHNICAL/Physical_Interfaces/USB := 1 $(HW_INTERFACE_USB)
	TECHNICAL/Physical_Specification/Weight := 295 g
	TECHNICAL/Input_Output/Input := 1 x digital dry input (0 - 3 V), 1 x digital galvanically isolated input (0 - 30 V), \
	1 x analog input (0 - 24 V), 1 x Digital non-isolated input (on 4-pin power connector, 0 - 5 V detected as logic low,\
	8 - 30 V detected as logic high)
	TECHNICAL/Input_Output/Output := 1 x digital open collector output (30 V, 250 mA), 1 x SPST relay output (40 V, 4 A), \
	1 x Digital open collector output (30 V, 300 mA, on 4-pin power connector)
	HARDWARE/Serial/RS232 := $(HW_SERIAL_RS232) 300 to 115200 baud rate
	HARDWARE/Serial/RS485 := $(HW_SERIAL_RS485)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem
	HARDWARE/USB/Data_Rate := $(HW_USB_2_DATA_RATE)
	HARDWARE/USB/Applications := $(HW_USB_APPLICATIONS)
	HARDWARE/USB/External_Devices := $(HW_USB_EXTERNAL_DEV)
	HARDWARE/USB/Storage_Formats := $(HW_USB_STORAGE_FORMATS)
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, RCM, CB, E-mark
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); \
	$(HW_EI_STANDARDS_EN_IEC_61000-3-2); $(HW_EI_STANDARDS_EN_61000-3-3); \
	$(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); \
	$(HW_EI_STANDARDS_EN_301_489-52_V1.2.1); EN 301 489-19 V2.2.0;
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := EN 61000-4-6:2014
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := EN 301 908-1; EN 301 908-2; EN 301 908-13; EN 300 328;
	REGULATORY/Safety/Standards := CE:EN 62311; CB:IEC 62368-1:2018;
endef

define Device/TEMPLATE_teltonika_rut951
	$(Device/teltonika_rut9m)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	DEVICE_MODEL := RUT951
	DEVICE_FEATURES += small_flash

	TECHNICAL/PoE_In_(Optional)/PoE_Ports := 1 x PoE In
	TECHNICAL/PoE_In_(Optional)/PoE_Standards := 802.3af/at
	TECHNICAL/PoE_Out_(Optional)/PoE_Ports := 1 x PoE Out
	TECHNICAL/PoE_Out_(Optional)/PoE_Standards := 802.3af and 802.3at Alternative B
	TECHNICAL/PoE_Out_(Optional)/PoE_Max_Power_per_Port_(at_PSE) := 24 W Max (power supply unit dependent)
	TECHNICAL/Power/PoE_Standards  := Optional: $(HW_POWER_POE_PASSIVE_30V)
	HARDWARE/Mobile/3GPP_Release := Release 10/11
	HARDWARE/Mobile/3GPP_Release/Tooltip := $(HW_MOBILE_3GPP_TOOLTIP)
	TECHNICAL/Input_Output/Input := 1 $(HW_INPUT_DI_30V) (Not available with active PoE)
	TECHNICAL/Input_Output/Output := 1 $(HW_OUTPUT_DO_30V) (Not available with active PoE)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi antenna connectors
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, CITC, ICASA, FCC, IC, PTCRB, RCM, Giteki, \
	ECE R118, E-mark, CB, UL/CSA Safety, RoHS, REACH, C1D2
	REGULATORY/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2); \
	$(HW_EI_STANDARDS_EN_61000-3-3); $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); \
	$(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := EN 61000-4-6:2014
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1);
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), $(HW_SAFETY_EN_5066); RCM:$(HW_SAFETY_AS/NZS_62368); \
	CB:$(HW_SAFETY_IEC_62368-1); UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	REGULATORY/Safety_(Ordinary_Locations)/Standards := CE:EN IEC 62368-1:2020 + A11:2020, EN IEC 62311:2020, EN 50665:2017; RCM:AS/NZS 62368.1:2022; \
	CB:IEC 62368-1:2018; UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	REGULATORY/Safety_(Hazardous_Locations)/Standards := UL/CSA Safety:UL 121201, 9th Ed., Rev. April 1, 2021, CAN/CSA C22.2 No. 213, 3rd Ed. April 2021
	REGULATORY/Safety_(Hazardous_Locations)/Hazardous_Environments := Class I, Division 2, Groups A, B, C, D; Class I, Zone 2, \
	Group IIC; -40°C ≤ Ta ≤ 75°C, T4, IP30;
endef

define Device/TEMPLATE_teltonika_rut956
	$(Device/teltonika_rut9m)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	$(Device/template_rut9x_io)
	DEVICE_MODEL := RUT956
	DEVICE_FEATURES += small_flash

	HARDWARE/Mobile/3GPP_Release := Release 11
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_10PIN) (available from HW revision 1600)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNSS
	TECHNICAL/Physical_Interfaces/USB := 1 $(HW_INTERFACE_USB)
	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_DB9)
	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
	TECHNICAL/Physical_Interfaces/Input_Output := 1 x 10-pin industrial socket for inputs/outputs
	TECHNICAL/Input_Output/Input := 1 x digital dry input (0 - 3 V), 1 x digital galvanically isolated input (0 - 30 V), 1 x analog input (0 - 24 V), \
	1 x Digital non-isolated input (on 4-pin power connector, 0 - 5 V detected as logic low, 8 - 30 V detected as logic high)
	TECHNICAL/Input_Output/Output := 1 x digital open collector output (30 V, 250 mA), 1 x SPST relay output (40 V, 4 A), \
	1 x Digital open collector output (30 V, 300 mA, on 4-pin power connector)
	HARDWARE/Serial/RS232 := $(HW_SERIAL_RS232)
	HARDWARE/Serial/RS485 := $(HW_SERIAL_RS485)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem, MODBUS gateway, NTRIP Client
	HARDWARE/USB/Data_Rate := $(HW_USB_2_DATA_RATE)
	HARDWARE/USB/Applications := $(HW_USB_APPLICATIONS)
	HARDWARE/USB/External_Devices := $(HW_USB_EXTERNAL_DEV)
	HARDWARE/USB/Storage_Formats := $(HW_USB_STORAGE_FORMATS)
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, CITC, ICASA, FCC, IC, PTCRB, Anatel, RCM, Giteki, IMDA, ECE R118, \
	E-mark, UL/CSA Safety, CB, RoHS, REACH, NCC, C1D2
	REGULATORY/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2); \
	$(HW_EI_STANDARDS_EN_61000-3-3); $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); \
	EN 301 489-19 V2.1.1; $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1); EN 303 413 V1.1.1;
	REGULATORY/Safety_(Ordinary_Locations)/Standards := CE:EN IEC 62368-1:2020 + A11:2020, EN IEC 62311:2020, EN 50665:2017; RCM:AS/NZS 62368.1:2022; \
	CB:IEC 62368-1:2018; UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	REGULATORY/Safety_(Hazardous_Locations)/Standards := UL/CSA Safety:UL 121201, 9th Ed., Rev. April 1, 2021, CAN/CSA C22.2 No. 213, 3rd Ed. April 2021
	REGULATORY/Safety_(Hazardous_Locations)/Hazardous_Environments := Class I, Division 2, Groups A, B, C, D; Class I, Zone 2, \
	Group IIC; -40°C ≤ Ta ≤ 75°C, T4, IP30;
endef

define Device/TEMPLATE_teltonika_rut971
	$(Device/teltonika_rute)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	DEVICE_MODEL := RUT971
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13

	HARDWARE/Mobile/Module := 5G up to 223 DL/ 123 UL Mbps; 4G LTE up to 195 DL/ 105 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 17
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi antenna connectors
	TECHNICAL/Input_Output/Input := 1 $(HW_INPUT_DI_30V)
	TECHNICAL/Input_Output/Output := 1 $(HW_OUTPUT_DO_30V)
	TECHNICAL/Physical_Specification/Weight := 297 g
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, IMDA, Anatel, RCM, E-mark, ECE R118, CB, RoHS, REACH, NCC
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032) + A1:2020; $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2);\
	$(HW_EI_STANDARDS_EN_61000-3-3) + A2:2021; $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); \
	$(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN IEC 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.1.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13-V13.1.1);
	REGULATORY/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), $(HW_SAFETY_EN_5066); \
	CB:$(HW_SAFETY_IEC_62368-1); RCM:$(HW_SAFETY_AS/NZS_62368);
endef

define Device/TEMPLATE_teltonika_rut976
	$(Device/teltonika_rute)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	$(Device/template_rut9x_io)
	DEVICE_MODEL := RUT976
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.12.1

	HARDWARE/Mobile/Module := 5G up to 223 DL/ 123 UL Mbps; 4G LTE up to 195 DL/ 105 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 17
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_10PIN)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNSS
	TECHNICAL/Physical_Interfaces/USB := 1 $(HW_INTERFACE_USB)
	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_DB9)
	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
	TECHNICAL/Physical_Interfaces/Input_Output := 1 x 10-pin industrial socket for inputs/outputs
	TECHNICAL/Input_Output/Input := 1 x digital dry input (0 - 3 V), 1 x digital galvanically isolated input (0 - 30 V), 1 x analog input (0 - 24 V), \
	1 x Digital non-isolated input (on 4-pin power connector, 0 - 5 V detected as logic low, 8 - 30 V detected as logic high)
	TECHNICAL/Input_Output/Output := 1 x digital open collector output (30 V, 250 mA), 1 x SPST relay output (40 V, 4 A), \
	1 x Digital open collector output (30 V, 300 mA, on 4-pin power connector)
	HARDWARE/Serial/RS232 := $(HW_SERIAL_RS232)
	HARDWARE/Serial/RS485 := $(HW_SERIAL_RS485)
	HARDWARE/Serial/Serial_Functions := Console, Serial over IP, Modem, MODBUS gateway, NTRIP Client
	HARDWARE/USB/Data_Rate := $(HW_USB_2_DATA_RATE)
	HARDWARE/USB/Applications := $(HW_USB_APPLICATIONS)
	HARDWARE/USB/External_Devices := $(HW_USB_EXTERNAL_DEV)
	HARDWARE/USB/Storage_Formats := $(HW_USB_STORAGE_FORMATS)
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, CITC, ICASA, FCC, IC, PTCRB, Anatel, RCM, Giteki, IMDA, ECE R118, \
	E-mark, UL/CSA Safety, CB, RoHS, REACH, NCC, C1D2
	REGULATORY/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile
	REGULATORY/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2); \
	$(HW_EI_STANDARDS_EN_61000-3-3); $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); \
	EN 301 489-19 V2.1.1; $(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	REGULATORY/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	REGULATORY/EMC_Emissions_&_Immunity/Radiated_Immunity := EN 61000-4-3:2020
	REGULATORY/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	REGULATORY/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	REGULATORY/EMC_Emissions_&_Immunity/CS := $(HW_IMUNITY_EMISION_CS)
	REGULATORY/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	REGULATORY/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1); EN 303 413 V1.1.1;
	REGULATORY/Safety_(Ordinary_Locations)/Standards := CE:EN IEC 62368-1:2020 + A11:2020, EN IEC 62311:2020, EN 50665:2017; RCM:AS/NZS 62368.1:2022; \
	CB:IEC 62368-1:2018; UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	REGULATORY/Safety_(Hazardous_Locations)/Standards := UL/CSA Safety:UL 121201, 9th Ed., Rev. April 1, 2021, CAN/CSA C22.2 No. 213, 3rd Ed. April 2021
	REGULATORY/Safety_(Hazardous_Locations)/Hazardous_Environments := Class I, Division 2, Groups A, B, C, D; Class I, Zone 2, \
	Group IIC; -40°C ≤ Ta ≤ 75°C, T4, IP30;
endef

define Device/TEMPLATE_teltonika_rut981
	$(Device/teltonika_rute)
	$(Device/teltonika_rut9x_common)
	$(Device/template_rut9x)
	DEVICE_MODEL := RUT981
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.15

	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_32M), $(HW_FLASH_TYPE_NOR)
	HARDWARE/Power/PoE_Standards  := Optional: $(HW_POWER_POE_PASSIVE_30V)
	HARDWARE/Mobile/3GPP_Release := Release 10
	HARDWARE/Input_Output/Input := 1 $(HW_INPUT_DI_30V)
	HARDWARE/Input_Output/Output := 1 $(HW_OUTPUT_DO_30V)
	HARDWARE/Physical_Interfaces/Antennas := 2 x SMA for LTE, 2 x RP-SMA for Wi-Fi antenna connectors
	HARDWARE/Regulatory_&_Type_Approvals/Regulatory := CE, UKCA, ANRT, Kenya, CITC, ICASA, FCC, IC, PTCRB, RCM, Giteki, \
	ECE R118, E-mark, CB, UL/CSA Safety, RoHS, REACH, C1D2
	HARDWARE/Regulatory_&_Type_Approvals/Operator := AT&T, Verizon, T-Mobile
	HARDWARE/EMC_Emissions_&_Immunity/Standards := $(HW_EI_STANDARDS_EN_55032); $(HW_EI_STANDARDS_EN_55035); $(HW_EI_STANDARDS_EN_IEC_61000-3-2); \
	$(HW_EI_STANDARDS_EN_61000-3-3); $(HW_EI_STANDARDS_EN_301_489-1_V2.2.3); $(HW_EI_STANDARDS_EN_301_489-17_V3.2.4); \
	$(HW_EI_STANDARDS_EN_301_489-52_V1.2.1);
	HARDWARE/EMC_Emissions_&_Immunity/ESD := $(HW_IMUNITY_EMISION_ESD)
	HARDWARE/EMC_Emissions_&_Immunity/Radiated_Immunity := EN 61000-4-3:2020
	HARDWARE/EMC_Emissions_&_Immunity/EFT := $(HW_IMUNITY_EMISION_EFT)
	HARDWARE/EMC_Emissions_&_Immunity/Surge_Immunity_(AC_Mains_Power_Port) := $(HW_IMUNITY_EMISION_SURGE)
	HARDWARE/EMC_Emissions_&_Immunity/CS := EN 61000-4-6:2014
	HARDWARE/EMC_Emissions_&_Immunity/DIP := $(HW_IMUNITY_EMISION_DIP)
	HARDWARE/RF/Standards := $(HW_RF_EN_300_328_V2.2.2); $(HW_RF_EN_301_511_V12.5.1); $(HW_RF_EN_301_908-1_V15.2.1); $(HW_RF_EN_301_908-2_V13.1.1); \
	$(HW_RF_EN_301_908-13_V13.2.1);
	HARDWARE/Safety/Standards := CE:$(HW_SAFETY_EN_IEC_62368-1), $(HW_SAFETY_EN_IEC_62311), $(HW_SAFETY_EN_5066); RCM:$(HW_SAFETY_AS/NZS_62368); \
	CB:$(HW_SAFETY_IEC_62368-1); UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	HARDWARE/Safety_(Ordinary_Locations)/Standards := CE:EN IEC 62368-1:2020 + A11:2020, EN IEC 62311:2020, EN 50665:2017; RCM:AS/NZS 62368.1:2022; \
	CB:IEC 62368-1:2018; UL/CSA Safety:UL 62368-1 (3rd Ed., Rev. December 13, 2019), C22.2 No. 62368-1:19 (3rd Ed., Rev. December 13, 2019);
	HARDWARE/Safety_(Hazardous_Locations)/Standards := UL/CSA Safety:UL 121201, 9th Ed., Rev. April 1, 2021, CAN/CSA C22.2 No. 213, 3rd Ed. April 2021
	HARDWARE/Safety_(Hazardous_Locations)/Hazardous_Environments := Class I, Division 2, Groups A, B, C, D; Class I, Zone 2, \
	Group IIC; -40°C ≤ Ta ≤ 75°C, T4, IP30;
endef
