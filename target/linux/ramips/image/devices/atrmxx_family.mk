define Device/TEMPLATE_teltonika_atrm50
	$(Device/tlt-mt7621-hw-common)
	$(Device/teltonika_atrm50)

	DEVICE_WLAN_BSSID_LIMIT := wlan0 8, wlan1 8

	DEVICE_USB_JACK_PATH := /usb1/1-2/

	DEVICE_NET_CONF :=       \
		vlans          4094, \
		max_mtu        2030, \
		readonly_vlans 1

	DEVICE_LAN_OPTION := "lan1 lan2 lan3"

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.1

	DEVICE_CHECK_PATH := pcie_check /sys/class/pci_bus/0000:00 reboot

	DEVICE_FEATURES := usb ethernet power_ios gps mobile wifi dual_band_ssid \
		dual_sim at_sim dsa hw_nat nat_offloading multi_tag \
		port_link soft_port_mirror gigabit_port sd_card xfrm-offload tpm reset_button

	DEVICE_WAN_OPTION := wan

	DEVICE_DOT1X_SERVER_CAPABILITIES := false false dsa_isolate

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/Mobile/Module := 5G Sub-6 GHz SA, NSA 2.4, 3.4Gbps DL (4x4 MIMO) 900, 550 Mbps UL (2x2 MIMO); 4G LTE: DL Cat 19 1.6Gbps (4x4 MIMO), UL Cat 18 200 Mbps
	HARDWARE/Mobile/3GPP_Release := Release 16
	HARDWARE/Mobile/eSIM := $(HW_MOBILE_ESIM_CONSTANT)
	HARDWARE/SD_card/Physical_Size := $(HW_SD_PHYSICAL_SIZE)
	HARDWARE/SD_card/Applications := $(HW_SD_APLICATIONS)
	HARDWARE/SD_card/Capacity := $(HW_SD_CAPACITY);
	HARDWARE/SD_card/Storage_Formats := $(HW_SD_STORAGE_FORMATS)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_5)
	TECHNICAL/Power/Connector := A-coded M12 power connector
	TECHNICAL/Power/Input_Voltage_Range := 9 - 50 VDC, overvoltage protection (70V), reverse polarity protection, surge protection >69 VDC 10us max
	TECHNICAL/Physical_Interfaces/Power := 1 x A-coded M12 power connector
	TECHNICAL/Physical_Interfaces/Ethernet := 4 x X-coded M12 connectors, $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/Power_Control := 1 x Battery input, 1 x Ignition input on A-coded M12 power connector
	TECHNICAL/Physical_Interfaces/Status_Leds := 3 x connection status LEDs, 3 x connection strength LEDs, 10 x Ethernet port status LEDs, 4 x WAN status LEDs, 1 x Power LED, 2 x 2.4G and 5G Wi-Fi LEDs
	TECHNICAL/Physical_Interfaces/Antennas := 4 x SMA for LTE, 2 x RP-SMA for WiFi, 1 x SMA for GNNS
	TECHNICAL/Physical_Interfaces/SIM := 2 $(HW_INTERFACE_SIM_HOLDERS)
	TECHNICAL/Physical_Interfaces/Ethernet := 5 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Power/Power_Consumption := Idle: <5 W, Max: <18 W
	TECHNICAL/Physical_Interfaces/Antennas := 2 x SMA for Mobile, 1 x SMA for GNSS
	TECHNICAL/Physical_Specification/Dimensions := 132 x 44.2 x 95.1 mm
	TECHNICAL/Physical_Specification/Weight := 519 g

endef
