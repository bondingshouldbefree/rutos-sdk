define Device/teltonika_rutm_common
	$(Device/tlt-mt7621-hw-common)
	HARDWARE/WAN/Port := 1 $(HW_ETH_WAN_PORT)
	HARDWARE/WAN/Speed := $(HW_ETH_SPEED_1000)
	HARDWARE/WAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/LAN/Port := 3 $(HW_ETH_LAN_PORTS)
	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_1000)
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	TECHNICAL/Physical_Interfaces/Ethernet := 4 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Physical_Interfaces/USB := 1 $(HW_INTERFACE_USB)
	HARDWARE/USB/Data_Rate := $(HW_USB_2_DATA_RATE)
	HARDWARE/USB/Applications := $(HW_USB_APPLICATIONS)
	HARDWARE/USB/External_Devices := $(HW_USB_EXTERNAL_DEV)
	HARDWARE/USB/Storage_Formats := $(HW_USB_STORAGE_FORMATS)
	TECHNICAL/Input_Output/Input := 1 $(HW_INPUT_DI_50V)
	TECHNICAL/Input_Output/Output := 1 $(HW_OUTPUT_DO_50V)
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AND_PANELS_AL)
	TECHNICAL/Physical_Specification/Mounting_Options := $(HW_PHYSICAL_MOUNTING_KIT)
endef

define Device/template_rutm_common
	$(Device/teltonika_rutm)

	DEVICE_WLAN_BSSID_LIMIT := wlan0 8, wlan1 8

	DEVICE_USB_JACK_PATH := /usb1/1-1/

	DEVICE_NET_CONF :=       \
		vlans          4094, \
		max_mtu        2030, \
		readonly_vlans 1

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_CHECK_PATH := pcie_check /sys/class/pci_bus/0000:00 reboot
endef

define Device/TEMPLATE_teltonika_rutm08
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM08
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.6.1
	DEVICE_FEATURES := usb ethernet ios dsa hw_nat nat_offloading multi_tag port_link \
		soft_port_mirror gigabit_port xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3"
	DEVICE_WAN_OPTION := wan
	DEVICE_WLAN_BSSID_LIMIT :=
	DEVICE_CHECK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	TECHNICAL/Physical_Interfaces/SIM :=
	TECHNICAL/Physical_Interfaces/Status_Leds := 8 x LAN status LEDs, 1 x Power LEDs
	TECHNICAL/Power/Power_Consumption := Idle < 1.8 W / Max < 5.5 W
	TECHNICAL/Physical_Specification/Weight := 353 g
	TECHNICAL/Physical_Specification/Dimensions := 115 x 32.2 x 95.2 mm
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm08

define Device/TEMPLATE_teltonika_rutm09
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM09
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.6.1
	DEVICE_FEATURES := usb ethernet ios gps mobile dual_sim dsa \
		hw_nat nat_offloading multi_tag port_link soft_port_mirror \
		gigabit_port xfrm-offload reset_button

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1
	DEVICE_LAN_OPTION := "lan1 lan2 lan3"
	DEVICE_WAN_OPTION := wan
	DEVICE_WLAN_BSSID_LIMIT :=
	DEVICE_CHECK_PATH :=

	HARDWARE/Mobile/Module := 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 12
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x WAN type LEDs, 3 x Mobile connection type, 5 x Mobile connection strength, 8 x LAN status, 1 x Power
	TECHNICAL/Power/Power_Consumption := Idle < 2.65 W, Max < 9.82 W
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for Mobile, 1 x SMA for GNSS
	TECHNICAL/Physical_Specification/Weight := 457 g
	TECHNICAL/Physical_Specification/Dimensions := 115 x 44.2 x 95.1 mm
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm09

define Device/TEMPLATE_teltonika_rutm10
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM10
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.6.1
	DEVICE_FEATURES := usb ethernet ios wifi dual_band_ssid dsa \
		hw_nat nat_offloading multi_tag port_link soft_port_mirror \
		gigabit_port xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3"
	DEVICE_WAN_OPTION := wan
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	TECHNICAL/Physical_Interfaces/SIM :=
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_5)
	TECHNICAL/Physical_Interfaces/Status_Leds := 8 x LAN status, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Power/Power_Consumption := Idle < 3.51 W, Max < 8.65 W
	TECHNICAL/Physical_Interfaces/Antennas := 2 x RP-SMA for Wi-Fi
	TECHNICAL/Physical_Specification/Weight := 359 g
	TECHNICAL/Physical_Specification/Dimensions := 115 x 32.2 x 95.2 mm
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm10

define Device/TEMPLATE_teltonika_rutm11
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM11
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.6.1
	DEVICE_FEATURES := usb ethernet ios gps mobile wifi \
		dual_band_ssid dual_sim dsa hw_nat nat_offloading multi_tag \
		port_link soft_port_mirror gigabit_port xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3"
	DEVICE_WAN_OPTION := wan
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 12
	TECHNICAL/Physical_Interfaces/Status_Leds := 4 x WAN type LEDs, 2 x Mobile connection type, 5 x Mobile connection strength, 8 x LAN status, 1 x Power, 2 x 2.4G and 5G Wi-Fi
	TECHNICAL/Power/Power_Consumption := Idle < 3.9 W, Max < 12.3 W
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNSS
	TECHNICAL/Physical_Specification/Weight := 460 g
	TECHNICAL/Physical_Specification/Dimensions := 115 x 44.2 x 95.1 mm
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm11

define Device/TEMPLATE_teltonika_rutm12
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM12
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.9
	DEVICE_FEATURES := ethernet ios gps mobile wifi \
		dual_band_ssid dual_modem dsa hw_nat nat_offloading multi_tag \
		port_link soft_port_mirror gigabit_port custom_usbcfg xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 2 x 4G LTE Cat 6 up to 300 DL/ 50 UL Mbps; 3G up to 42 DL/ 5.76 UL Mbps
	HARDWARE/Mobile/3GPP_Release := Release 12
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	TECHNICAL/Physical_Interfaces/Status_Leds := 4 x WAN type LEDs, 2 x Mobile connection type, 5 x Mobile connection strength, 8 x LAN status, 1 x Power, 2 x 2.4G and 5G Wi-Fi
	TECHNICAL/Power/Power_Consumption := Idle < 3.9 W, Max < 12.3 W
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNSS
	TECHNICAL/Physical_Specification/Weight := 460 g
	TECHNICAL/Physical_Specification/Dimensions := 115 x 44.2 x 95.1 mm
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm12

define Device/TEMPLATE_teltonika_rutm20
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM20
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.12
	DEVICE_POE_CONF := 1 1 _lan 4 15400
	DEVICE_POE_CHIP := 0X2F 4:_lan
	DEVICE_FEATURES := wifi ethernet mobile dual_band_ssid dual_sim \
		at_sim dsa hw_nat nat_offloading multi_tag port_link \
		gigabit_port m2_modem poe tpm reset_button

	DEVICE_LAN_OPTION := "lan "
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH :=
	DEVICE_CHECK_PATH += , usb_check /sys/bus/usb/drivers/usb/2-1 reboot
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G SA: DL 2Gbps,UL 1Gbps; NSA: DL 2.6Gbps, UL 650 Mbps; 4G LTE: DL 600 Mbps, UL 150 Mbps;
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	HARDWARE/LAN/Port := 1 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 2 x Ethernet port status LEDs, 2 x WAN status LEDs and 1 x Power LED
	TECHNICAL/Physical_Interfaces/Ethernet := 2 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm20

define Device/TEMPLATE_teltonika_rutm30
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM30
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13.1
	DEVICE_FEATURES := wifi ethernet ios mobile dual_band_ssid dual_sim \
		at_sim dsa hw_nat nat_offloading multi_tag port_link \
		gigabit_port tpm reset_button

	DEVICE_LAN_OPTION := "lan "
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G SA: DL 2Gbps,UL 1Gbps; NSA: DL 2.6Gbps, UL 650 Mbps; 4G LTE: DL 600 Mbps, UL 150 Mbps;
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	HARDWARE/LAN/Port := 1 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 2 x Ethernet port status LEDs, 2 x WAN status LEDs and 1 x Power LED
	TECHNICAL/Physical_Interfaces/Ethernet := 2 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm30

define Device/TEMPLATE_teltonika_rutm31
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM31
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.13.4
	DEVICE_FEATURES := wifi ethernet ios mobile dual_band_ssid dual_sim \
		at_sim dsa hw_nat nat_offloading multi_tag port_link \
		gigabit_port tpm reset_button

	DEVICE_LAN_OPTION := "lan "
	DEVICE_WAN_OPTION := wan
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G Sub-6GHz SA: 2 Gbps DL, 1 Gbps UL; NSA: 2.6 Gbps DL, 650 Mbps UL; 4G (LTE) - Cat 12: 600 Mbps DL, Cat 13: 150 Mbps UL; 3G - 42.2 Mbps DL, 11 Mbps UL
	HARDWARE/Mobile/3GPP_Release := Release 15
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	HARDWARE/LAN/Port := 1 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 2 x Ethernet port status LEDs, 2 x WAN status LEDs and 1 x Power LED
	TECHNICAL/Physical_Interfaces/Ethernet := 2 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm31

define Device/TEMPLATE_teltonika_rutm50
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM50
	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
	DEVICE_FEATURES := usb ethernet ios mobile wifi dual_band_ssid \
		dual_sim at_sim dsa hw_nat nat_offloading multi_tag \
		port_link soft_port_mirror gigabit_port xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH := /usb1/1-2/
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4 Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6 Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm50

define Device/TEMPLATE_teltonika_rutm51
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM51
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.4.4
	DEVICE_USB_JACK_PATH := /usb1/1-2/
	DEVICE_FEATURES := usb ethernet ios mobile wifi dual_band_ssid \
		dual_sim at_sim dsa hw_nat nat_offloading multi_tag \
		soft_port_mirror port_link gigabit_port xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G SA: DL 2Gbps,UL 1Gbps; NSA: DL 2.6 Gbps, UL 650 Mbps; 4G LTE: DL 600 Mbps, UL 150 Mbps;
	HARDWARE/Mobile/3GPP_Release := Release 15
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm51

define Device/TEMPLATE_teltonika_rutm52
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM52
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.10
	DEVICE_FEATURES := gps ethernet ios mobile wifi dual_band_ssid dual_sim \
		at_sim dsa hw_nat nat_offloading multi_tag soft_port_mirror port_link \
		gigabit_port dual_modem custom_usbcfg sd_card xfrm-offload tpm reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 4 x connection status LEDs, 6 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm52

define Device/TEMPLATE_teltonika_rutm54
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM54
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.11
	DEVICE_FEATURES := gps usb ethernet ios mobile wifi dual_band_ssid \
		dual_sim at_sim dsa hw_nat nat_offloading multi_tag soft_port_mirror \
		port_link gigabit_port m2_modem xfrm-offload tpm reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH := /usb1/1-2/
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 3.4Gbps DL, 0.55Gbps UL, SA 2.5Gbps DL, 0.9Gbps UL; 4G LTE CAT 19 DL 1.6Gbps on DL, CAT. 18 UL 211 Mbps, \
	3G HSPA+ Rel9 DL/UL 42/5.7 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm54

define Device/TEMPLATE_teltonika_rutm55
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM55
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.14
	DEVICE_USB_JACK_PATH := /usb1/1-2/1-2.1/
	DEVICE_FEATURES := gps ethernet ios mobile wifi dual_band_ssid \
		at_sim dsa hw_nat nat_offloading multi_tag port_link \
		soft_port_mirror gigabit_port rs232 rs485 usb xfrm-offload \
		dual_sim tpm reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3"
	DEVICE_WAN_OPTION := wan
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate
	DEVICE_SERIAL_CAPABILITIES := \
		"rs232"                                                            \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400"  \
			"7 8"                                                          \
			"rts/cts xon/xoff none"                                        \
			"1 2"                                                          \
			"even odd mark space none"                                     \
			"none"                                                         \
			"/tty/ttyS1",                                                  \
		"rs485"                                                            \
			"300 600 1200 2400 4800 9600 19200 38400 57600 115200          \
			230400 460800 921600 3000000"                                  \
			"5 6 7 8"                                                      \
			"none"                                                         \
			"1 2"                                                          \
			"even odd mark space none"                                     \
			"half"                                                         \
			"/usb1/1-1/1-1\:1.0/"

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/LAN/Port := 3 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 8 x Ethernet port status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/Ethernet := 4 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm (TODO)
	TECHNICAL/Physical_Specification/Weight := 519 g (TODO)
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm55

define Device/TEMPLATE_teltonika_rutm56
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM56
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.12.1
	DEVICE_FEATURES := gps ethernet ios mobile wifi dual_band_ssid \
		at_sim dsa hw_nat nat_offloading multi_tag soft_port_mirror \
		port_link gigabit_port dual_modem custom_usbcfg xfrm-offload \
		dual_sim tpm reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 1 x 5G Sub-6Ghz SA/NSA 2.4/3.4Gbps DL (4x4 MIMO), 900/550 Mbps UL (2x2); 4G (LTE) – LTE Cat 20 2.0Gbps DL, 210 Mbps UL; 3G – 42 Mbps DL, 5.76 Mbps UL, \
	1 x 4G LTE Cat 4 up to 150 DL/50 UL Mbps; 3G up to 21 DL/5.76 UL Mbps; 2G up to 236.8 DL/236.8 UL Kbps
	HARDWARE/Mobile/3GPP_Release := Release 16, Release 9
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	TECHNICAL/Physical_Interfaces/USB :=
	HARDWARE/USB/Data_Rate :=
	HARDWARE/USB/Applications :=
	HARDWARE/USB/External_Devices :=
	HARDWARE/USB/Storage_Formats :=
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 4 x connection status LEDs, 6 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/SIM := 4 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 6 x SMA for Mobile, 2 x RP-SMA for Wi-Fi, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm56

define Device/TEMPLATE_teltonika_rutm59
	$(Device/teltonika_rutm_common)
	$(Device/template_rutm_common)
	DEVICE_MODEL := RUTM59
	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.9.3
	DEVICE_FEATURES := usb ethernet ios mobile dual_sim \
		at_sim dsa hw_nat nat_offloading multi_tag port_link \
		soft_port_mirror gigabit_port gps xfrm-offload reset_button

	DEVICE_LAN_OPTION := "lan1 lan2 lan3 lan4"
	DEVICE_WAN_OPTION := wan
	DEVICE_USB_JACK_PATH := /usb1/1-2/
	DEVICE_WLAN_BSSID_LIMIT :=
	DEVICE_CHECK_PATH :=
	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Wireless/Wireless_Mode :=
	HARDWARE/Wireless/Wi\-Fi_Users :=
	HARDWARE/LAN/Port := 4 $(HW_ETH_LAN_PORTS)
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 10 x Ethernet port status LEDs, 3 x WAN status LEDs, 1 x Power LED
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle <5 W, Max <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for Mobile, 1 x SMA for GNNS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g
endef
TARGET_DEVICES += TEMPLATE_teltonika_rutm59
