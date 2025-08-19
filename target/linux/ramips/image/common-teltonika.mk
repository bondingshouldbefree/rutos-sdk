DEVICE_VARS += UBOOT_SIZE
DEVICE_VARS += CONFIG_SIZE CONFIG_END
DEVICE_VARS += ART_SIZE NO_ART ART_END
DEVICE_VARS += MASTER_IMAGE_SIZE

define Build/append-tlt-uboot
	dd if="$(BIN_DIR)/u-boot_$(word 1,$(DEVICE_BOOT_NAME))$(word 1,$(1)).bin" >> $@
endef

define Build/append-tlt-config
	dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-config.bin >> $@
endef

define Build/append-tlt-art
	dev_model=$(DEVICE_MODEL); \
	[ -z "$(1)" ] || dev_model=$(1); \
	if [ $(NO_ART) == 1 ]; then \
		dd if=/dev/zero bs=$(ART_SIZE) count=1 >> $@; \
	elif [ "$$dev_model" == "RUT14X" ] || [ "$$dev_model" == "DAP14X" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-RUT14X.bin >> $@; \
	elif [ "$$dev_model" == "RUT361" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-RUT361.bin >> $@; \
	elif [ "$$dev_model" == "TAP100" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-TAP100.bin >> $@; \
	elif [ "$$dev_model" == "RUTM" ] || [ "$$dev_model" == "ATRM50" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-RUTM.bin >> $@; \
	elif [ "$$dev_model" == "TAP200" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-TAP200.bin >> $@; \
	elif [ "$$dev_model" == "RUT2M" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-RUT2M.bin >> $@; \
	elif [ "$$dev_model" == "RUT9M" ] || [ "$$dev_model" == "OTD144" ]; then \
		dd if=$(TOPDIR)/target/linux/ramips/image/bin/tlt-factory-art-RUT95M.bin >> $@; \
	fi
endef

define Build/master_fw_custom
	$(call Build/append-tlt-uboot)
	$(call Build/pad-to,$(UBOOT_SIZE))
	$(call Build/append-tlt-config)
	$(call Build/pad-to,$(CONFIG_END))
	$(call Build/append-tlt-art,$(1))
	$(call Build/pad-to,$(ART_END))
	$(call Build/append-kernel)
	$(call Build/pad-to,$(BLOCKSIZE))
	$(call Build/append-rootfs)
	$(call Build/pad-rootfs)
	$(call Build/append-version)
	$(call Build/check-size,$(MASTER_IMAGE_SIZE))
	$(call Build/finalize-tlt-master-stendui,,$(1))
endef
