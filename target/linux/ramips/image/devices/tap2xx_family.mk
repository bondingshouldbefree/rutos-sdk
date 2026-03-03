define Device/TEMPLATE_teltonika_tap200
	$(Device/tlt-mt7621-hw-common)
	$(Device/teltonika_tap200)

	DEVICE_NET_CONF :=       \
		ula           false, \
		disable_vlan  true,  \
		ip6assign     false, \
		vlans         16,    \
		no_metric     true,  \
		max_mtu       2030

	DEVICE_WLAN_BSSID_LIMIT := wlan0 8, wlan1 8

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.3 device eth1 ipv6 0 fallback 1 proto dhcp, \
		dhcp6 device br-lan proto dhcpv6

	DEVICE_CHECK_PATH := pcie_check /sys/class/pci_bus/0000:00 reboot

	DEVICE_FEATURES := access_point wifi ethernet sw_rst_on_init dual_band_ssid single_port small_flash reset_button dot1x-client

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=

	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M) $(HW_FLASH_TYPE_NOR_SERIAL), $(HW_FLASH_SIZE_128M) $(HW_FLASH_TYPE_NAND_SERIAL)
	HARDWARE/Ethernet/Port :=1 $(HW_ETH_RJ45_PORT)
	HARDWARE/Ethernet/Speed := $(HW_ETH_SPEED_1000)
	HARDWARE/Ethernet/Standard := $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/Wireless/Wi\-Fi_Users := $(HW_WIFI_100_USERS)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_RJ45)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_POE_2)
	TECHNICAL/Power/PoE_Standards := $(HW_POE_STD_80203AF)
	TECHNICAL/Power/Power_Consumption := Idle < 4 W / Max < 5.5 W
	TECHNICAL/Physical_Interfaces/Power :=
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/Ethernet := 1 $(HW_ETH_RJ45_PORT), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x Power LED (can be turned off from web-UI)
	TECHNICAL/Physical_Interfaces/Antennas := 2 x Internal for 2.4 GHz Wi-Fi, 2 x Internal for 5 GHz Wi-Fi
	TECHNICAL/Physical_Interfaces/Antennas_Specifications := 2 x 2400 - 2500 MHz, 50 Ω, VSWR <2.7, gain < 4.9 dBi, omnidirectional \
	2 x 5150 - 5850 MHz, 50 Ω, VSWR <2, gain < 5.02 dBi, omnidirectional
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_UV_PLASTIC)
	TECHNICAL/Physical_Specification/Dimensions := 158 mm x 30 mm
	TECHNICAL/Physical_Specification/Weight := 190 g
	TECHNICAL/Physical_Specification/Mounting_Options := AP Mounting Bracket (for ceiling mount)
	TECHNICAL/Operating_Environment/Operating_Temperature := $(HW_OPERATING_TEMP)
	TECHNICAL/Operating_Environment/Operating_Humidity := $(HW_OPERATING_HUMIDITY)
	TECHNICAL/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP30)
endef
