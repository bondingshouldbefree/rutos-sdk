define Device/teltonika_dap14x_common
	$(Device/tlt-mt7628-hw-common)
	HARDWARE/LAN/Port := 2 $(HW_ETH_LAN_PORT)
	HARDWARE/LAN/Speed := $(HW_ETH_SPEED_100)
	HARDWARE/LAN/Standard := $(HW_ETH_LAN_2_STANDARD)
	HARDWARE/Wireless/Wi\-Fi_Users  := $(HW_WIFI_50_USERS)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_4)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_3PIN)
	TECHNICAL/Power/Power_Consumption := Idle:< 1 W / Max:< 2 W
	TECHNICAL/Physical_Interfaces/IO :=
	TECHNICAL/Physical_Interfaces/Power := 1 x 3-pin power connector
	TECHNICAL/Physical_Interfaces/Status_Leds := 1 x WAN type LED, 1 x LAN type LED, 1 x Power LED
	TECHNICAL/Physical_Interfaces/Antennas := 1 x RP-SMA for Wi-Fi
	TECHNICAL/Physical_Specification/Casing_Material := $(HW_PHYSICAL_HOUSING_AL)
	TECHNICAL/Physical_Specification/Dimensions := 113.10 x 25 x 68.6 mm
	TECHNICAL/Physical_Specification/Mounting_Options := Integrated DIN rail bracket
	REGULATORY/Regulatory_&_Type_Approvals/Regulatory := CE/RED, UKCA, CB, RCM, FCC, IC, EAC, UCRF, WEEE
endef

define Device/template_dap14x
	$(Device/teltonika_dap14x)

	DEVICE_SWITCH_CONF := switch0 1:lan:2 0:lan:1 6@eth0

	DEVICE_WLAN_BSSID_LIMIT := wlan0 4

	DEVICE_NET_CONF :=       \
		vlans          16,   \
		max_mtu        1500, \
		readonly_vlans 1,    \
		vlan0          true

	DEVICE_INTERFACE_CONF := \
		lan default_ip 192.168.1.3, dhcp device br-lan proto dhcp

	DEVICE_FEATURES := industrial_access_point wifi nat_offloading ethernet port_link xfrm-offload small_flash reset_button 128mb_ram

	DEVICE_INITIAL_FIRMWARE_SUPPORT :=
endef

define Device/TEMPLATE_teltonika_dap140
	$(Device/teltonika_dap14x_common)
	$(Device/template_dap14x)
	DEVICE_MODEL := DAP140

	TECHNICAL/Physical_Specification/Weight := 142.3 g
endef

define Device/TEMPLATE_teltonika_dap142
	$(Device/teltonika_dap14x_common)
	$(Device/template_dap14x)
	DEVICE_MODEL := DAP142
	DEVICE_FEATURES += rs232

	DEVICE_SERIAL_CAPABILITIES := \
	"rs232"                                                           \
		"300 600 1200 2400 4800 9600 19200 38400 57600 115200"        \
		"5 6 7 8"                                                     \
		"rts/cts xon/xoff none"                                       \
		"1 2"                                                         \
		"even odd mark space none"                                    \
		"none"                                                        \
		"/usb1/1-1/1-1:1.0/",                                         \

	TECHNICAL/Physical_Interfaces/RS232 := 1 $(HW_INTERFACE_RS232_DB9)
	TECHNICAL/Physical_Specification/Weight := 149.2 g
endef

define Device/TEMPLATE_teltonika_dap145
	$(Device/teltonika_dap14x_common)
	$(Device/template_dap14x)
	DEVICE_MODEL := DAP145
	DEVICE_FEATURES += rs485

	DEVICE_INITIAL_FIRMWARE_SUPPORT := 7.16

	DEVICE_SERIAL_CAPABILITIES := \
	"rs485"                                                           \
		"300 600 1200 2400 4800 9600 19200 38400 57600 115200 230400" \
		"5 6 7 8"                                                     \
		"xon/xoff none"                                               \
		"1 2"                                                         \
		"even odd mark space none"                                    \
		"half full"                                                   \
		"/tty/ttyS1"

	TECHNICAL/Physical_Interfaces/RS485 := 1 $(HW_INTERFACE_RS485_6PIN)
endef
