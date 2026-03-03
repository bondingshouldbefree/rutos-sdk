include $(INCLUDE_DIR)/hardware.mk

define Device/tlt-mt7621-hw-common
	HARDWARE/System_Characteristics/CPU := MediaTek, Dual-Core, 880 MHz, MIPS1004Kc
	HARDWARE/System_Characteristics/RAM := $(HW_RAM_SIZE_256M), $(HW_RAM_TYPE_DDR3)
	HARDWARE/System_Characteristics/Flash_Storage := $(HW_FLASH_SIZE_16M) $(HW_FLASH_TYPE_NOR_SERIAL), $(HW_FLASH_SIZE_256M) $(HW_FLASH_TYPE_NAND_SERIAL)
	HARDWARE/Wireless/Wireless_Mode := 802.11b/g/n/ac Wave 2 (Wi-Fi 5)
	HARDWARE/Wireless/Wi\-Fi_Users := $(HW_WIFI_150_USERS)
	TECHNICAL/Power/Connector := $(HW_POWER_CONNECTOR_4PIN)
	TECHNICAL/Power/Input_Voltage_Range := $(HW_POWER_VOLTAGE_4PIN_50V)
	TECHNICAL/Power/PoE_Standards  := $(HW_POWER_POE_PASSIVE_50V)
	TECHNICAL/Physical_Interfaces/Power := $(HW_INTERFACE_POWER_4PIN)
	TECHNICAL/Physical_Interfaces/Ethernet := 4 $(HW_ETH_RJ45_PORTS), $(HW_ETH_SPEED_1000)
	TECHNICAL/Physical_Interfaces/Button := $(HW_INTERFACE_RESET_BTN)
	TECHNICAL/Physical_Interfaces/IO := $(HW_INTERFACE_IO_4PIN_IN_OUT)
	TECHNICAL/Operating_Environment/Operating_Temperature := $(HW_OPERATING_TEMP)
	TECHNICAL/Operating_Environment/Operating_Humidity := $(HW_OPERATING_HUMIDITY)
	TECHNICAL/Operating_Environment/Ingress_Protection_Rating := $(HW_OPERATING_PROTECTION_IP30)
endef
