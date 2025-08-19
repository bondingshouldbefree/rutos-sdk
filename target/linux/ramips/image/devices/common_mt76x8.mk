include $(INCLUDE_DIR)/hardware.mk

define Device/tlt-mt7628-hw-common
	HARDWARE/System_Characteristics/CPU := Mediatek, 580 MHz, MIPS 24KEc
	HARDWARE/System_Characteristics/RAM := $(HW_RAM_SIZE_128M), $(HW_RAM_TYPE_DDR2)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M), $(HW_FLASH_TYPE_NOR)
	HARDWARE/Wireless/Wireless_Mode := $(HW_WIFI_4), 2x2 MIMO
	HARDWARE/Wireless/Wi\-Fi_Users := $(HW_WIFI_100_USERS)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_4PIN)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_4PIN_30V)
	TECHNICAL/Power/PoE_Standards  := $(HW_POWER_POE_PASSIVE_30V)
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_4PIN)
	TECHNICAL/Physical_Interfaces/Ethernet := 2 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_100)
	TECHNICAL/Physical_Interfaces/Button := $(HW_INTERFACE_RESET)
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_4PIN_IN_OUT)
	TECHNICAL/Operating_Environment/Operating_Temperature := $(HW_OPERATING_TEMP)
	TECHNICAL/Operating_Environment/Operating_Humidity := $(HW_OPERATING_HUMIDITY)
	TECHNICAL/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP30)
endef
