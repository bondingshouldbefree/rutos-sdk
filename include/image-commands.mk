# Build commands that can be called from Device/* templates

IMAGE_KERNEL = $(word 1,$^)
IMAGE_ROOTFS = $(word 2,$^)

define Build/append-dtb
	cat $(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb >> $@
endef

define Build/append-kernel
	dd if=$(IMAGE_KERNEL) >> $@
endef

compat_version=$(if $(DEVICE_COMPAT_VERSION),$(DEVICE_COMPAT_VERSION),1.0)
json_quote=$(subst ','\'',$(subst ",\",$(1)))
#")')

legacy_supported_message=$(SUPPORTED_DEVICES) - Image version mismatch: image $(compat_version), \
	device 1.0. Please wipe config during upgrade (force required) or reinstall. \
	$(if $(DEVICE_COMPAT_MESSAGE),Reason: $(DEVICE_COMPAT_MESSAGE),Please check documentation ...)

metadata_devices=$(if $(1),$(subst "$(space)","$(comma)",$(strip $(foreach v,$(1),"$(call json_quote,$(v))"))))
# Keep in mind that during fw validation some bootloaders will read up to 512 or 4096 bytes of this metadata .json
metadata_json = \
	'{ $(if $(IMAGE_METADATA),$(IMAGE_METADATA)$(comma)) \
		"metadata_version": "1.1", \
		"compat_version": "$(call json_quote,$(compat_version))", \
		"version":"$(call json_quote,$(TLT_VERSION))", \
		"device_code": [$(DEVICE_COMPAT_CODE)], \
		"hwver": [".*"], \
		"batch": [".*"], \
		"serial": [".*"], \
		$(if $(DEVICE_COMPAT_MESSAGE),"compat_message": "$(call json_quote,$(DEVICE_COMPAT_MESSAGE))"$(comma)) \
		$(if $(filter-out 1.0,$(compat_version)),"new_supported_devices": \
			[$(call metadata_devices,$(SUPPORTED_DEVICES))]$(comma) \
			"supported_devices": ["$(call json_quote,$(legacy_supported_message))"]$(comma)) \
		$(if $(filter 1.0,$(compat_version)),"supported_devices":[$(call metadata_devices,$(SUPPORTED_DEVICES))]$(comma)) \
		"version_wrt": { \
			"dist": "$(call json_quote,$(VERSION_DIST))", \
			"version": "$(call json_quote,$(VERSION_NUMBER))", \
			"revision": "$(call json_quote,$(REVISION))", \
			"target": "$(call json_quote,$(TARGETID))", \
			"board": "$(call json_quote,$(if $(BOARD_NAME),$(BOARD_NAME),$(DEVICE_NAME)))" \
		}, \
		$(subst $(comma)},},"hw_support": { \
			$(foreach data, \
				$(HW_SUPPORT), \
					"$(firstword $(subst %,": ,$(data))) \
					["$(subst :," $(comma)",$(lastword $(subst %,": ,$(data))))"],)},) \
		$(subst $(comma)},},"hw_mods": { \
			$(shell i=1; for t in $(HW_MODS); do if [ $$i -gt 1 ]; then printf ", "; fi; printf "\"mod%d\": \"%s\"" "$$i" "$$t"; i=$$((i+1)); done)}) \
	}'

version_json = '{"version":"$(call json_quote,$(TLT_VERSION))"}'

define Build/prepend-metadata-nofwtool
	$(if $(SUPPORTED_DEVICES),-echo $(call metadata_json) | dd of=$@ bs=1 conv=notrunc)
endef

define Build/append-metadata
	$(if $(SUPPORTED_DEVICES),-echo $(call metadata_json) | fwtool -I - $@)
	[ -z "$(CONFIG_SIGNED_IMAGES)" -o ! -s "$(BUILD_KEY)" -o ! -s "$(BUILD_KEY).ucert" -o ! -s "$@" ] || { \
		cp "$(BUILD_KEY).ucert" "$@.ucert" ;\
		usign -S -m "$@" -s "$(BUILD_KEY)" -x "$@.sig" ;\
		ucert -A -c "$@.ucert" -x "$@.sig" ;\
		fwtool -S "$@.ucert" "$@" ;\
	}
endef

define Build/append-version
	echo $(call version_json) | fwtool -I - $@
endef

define Build/append-rootfs
	dd if=$(IMAGE_ROOTFS) >> $@
endef

define Build/append-ubi
	sh $(TOPDIR)/scripts/ubinize-image.sh \
		$(if $(UBOOTENV_IN_UBI),--uboot-env) \
		$(if $(KERNEL_IN_UBI),--kernel $(IMAGE_KERNEL)) \
		$(foreach part,$(UBINIZE_PARTS),--part $(part)) \
		$(IMAGE_ROOTFS) \
		$@.tmp \
		-p $(BLOCKSIZE:%k=%KiB) -m $(PAGESIZE) \
		$(if $(SUBPAGESIZE),-s $(SUBPAGESIZE)) \
		$(if $(VID_HDR_OFFSET),-O $(VID_HDR_OFFSET)) \
		$(UBINIZE_OPTS)
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Build/append-uboot
	dd if=$(UBOOT_PATH) >> $@
endef

define Build/check-size
	@imagesize="$$(stat -c%s $@)"; \
	$(if $(filter $(1),999m),echo "INFO: Image file $@ size before padding: $$imagesize" >&2;) \
	limitsize="$$(($(subst k,* 1024,$(subst m, * 1024k,$(if $(1),$(1),$(IMAGE_SIZE))))))"; \
	$(if $(CONFIG_PROD_IMAGE),,limitsize=$$(($$limitsize + 256);)) \
	[ $$limitsize -ge $$imagesize ] || { \
		echo -n "WARNING: Image file $@ is too big: $$imagesize > $$limitsize"; \
		initial_imagesize="$$(grep -oP ' size before padding: \K\d+' '$(BUILD_LOG_DIR)/target/linux/install.txt' 2>/dev/null)"; \
		[ -z "$$initial_imagesize" ] || echo ". Compressed rootFS size before padding exceeded the limit by $$(($(subst k,* 1024,$(if $(BLOCKSIZE),$(BLOCKSIZE),64k)) - $$imagesize + $$initial_imagesize)) bytes"; \
		echo; \
		rm -f $@; \
	} >&2
endef

define Build/initrd_compression
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_BZIP2),.bzip2) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_GZIP),.gzip) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZ4),.lz4) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZMA),.lzma) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_LZO),.lzo) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_XZ),.xz) \
	$(if $(CONFIG_TARGET_INITRAMFS_COMPRESSION_ZSTD),.zstd)
endef

define Build/fit
	$(TOPDIR)/scripts/mkits.sh \
		-D $(DEVICE_NAME) -o $@.its -k $@ \
		-C $(word 1,$(1)) \
		$(if $(word 2,$(1)),\
			$(if $(findstring 11,$(if $(DEVICE_DTS_OVERLAY),1)$(if $(findstring $(KERNEL_BUILD_DIR)/image-,$(word 2,$(1))),,1)), \
				-d $(KERNEL_BUILD_DIR)/image-$$(basename $(word 2,$(1))), \
				-d $(word 2,$(1)))) \
		$(if $(findstring with-rootfs,$(word 3,$(1))),-r $(IMAGE_ROOTFS)) \
		$(if $(findstring with-initrd,$(word 3,$(1))), \
			$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS_SEPARATE), \
				-i $(KERNEL_BUILD_DIR)/initrd.cpio$(strip $(call Build/initrd_compression)))) \
		-a $(KERNEL_LOADADDR) -e $(if $(KERNEL_ENTRY),$(KERNEL_ENTRY),$(KERNEL_LOADADDR)) \
		$(if $(DEVICE_FDT_NUM),-n $(DEVICE_FDT_NUM)) \
		$(if $(DEVICE_DTS_DELIMITER),-l $(DEVICE_DTS_DELIMITER)) \
		$(if $(DEVICE_DTS_LOADADDR),-s $(DEVICE_DTS_LOADADDR)) \
		$(if $(DEVICE_MDTB_NAME),-M $(DEVICE_MDTB_NAME)) \
		$(if $(DEVICE_DTS_OVERLAY),$(foreach dtso,$(DEVICE_DTS_OVERLAY), -O $(dtso):$(KERNEL_BUILD_DIR)/image-$(dtso).dtbo)) \
		-c $(if $(DEVICE_DTS_CONFIG),$(DEVICE_DTS_CONFIG),"config@1") \
		-A $(LINUX_KARCH) -v $(LINUX_VERSION)
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage $(if $(findstring external,$(word 3,$(1))),\
		-E -B 0x1000 $(if $(findstring static,$(word 3,$(1))),-p 0x1000)) -f $@.its $@.new
	@mv $@.new $@
endef

define Build/fit-append
	$(TOPDIR)/scripts/mkits.sh \
		-D $(DEVICE_NAME) -o $@.its -k $(IMAGE_KERNEL) \
		-C $(word 1,$(1)) \
		$(if $(word 2,$(1)),\
			$(if $(findstring 11,$(if $(DEVICE_DTS_OVERLAY),1)$(if $(findstring $(KERNEL_BUILD_DIR)/image-,$(word 2,$(1))),,1)), \
				-d $(KERNEL_BUILD_DIR)/image-$$(basename $(word 2,$(1))), \
				-d $(word 2,$(1)))) \
		$(if $(findstring with-rootfs,$(word 3,$(1))),-r $(IMAGE_ROOTFS)) \
		$(if $(findstring with-initrd,$(word 3,$(1))), \
			$(if $(CONFIG_TARGET_ROOTFS_INITRAMFS_SEPARATE), \
				-i $(KERNEL_BUILD_DIR)/initrd.cpio$(strip $(call Build/initrd_compression)))) \
		-a $(KERNEL_LOADADDR) -e $(if $(KERNEL_ENTRY),$(KERNEL_ENTRY),$(KERNEL_LOADADDR)) \
		$(if $(DEVICE_FDT_NUM),-n $(DEVICE_FDT_NUM)) \
		$(if $(DEVICE_DTS_DELIMITER),-l $(DEVICE_DTS_DELIMITER)) \
		$(if $(DEVICE_DTS_LOADADDR),-s $(DEVICE_DTS_LOADADDR)) \
		$(if $(DEVICE_MDTB_NAME),-M $(DEVICE_MDTB_NAME)) \
		$(if $(DEVICE_DTS_OVERLAY),$(foreach dtso,$(DEVICE_DTS_OVERLAY), -O $(dtso):$(KERNEL_BUILD_DIR)/image-$(dtso).dtbo)) \
		-c $(if $(DEVICE_DTS_CONFIG),$(DEVICE_DTS_CONFIG),"config@1") \
		-A $(LINUX_KARCH) -v $(LINUX_VERSION)
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage $(if $(findstring external,$(word 3,$(1))),\
		-E -B 0x1000 $(if $(findstring static,$(word 3,$(1))),-p 0x1000)) -f $@.its $@.new
	cat $@.new >> $@
	rm $@.new
endef

define Build/gzip
	gzip -f -9n -c $@ $(1) > $@.new
	@mv $@.new $@
endef

define Build/finalize-tlt-custom
	[ -d $(BIN_DIR)/tltFws ] || mkdir -p $(BIN_DIR)/tltFws
	$(CP) $@ $(BIN_DIR)/tltFws/$(TLT_VERSION_FILE)$(if $(1),_$(word 1,$(1)))$(if $(findstring 1,$(FAKE_RELEASE_BUILD)),_FAKE).$(if $(word 2,$(1)),$(word 2,$(1)),bin)
	echo "Copying $@ to tltFws"
	echo  $(BIN_DIR)/tltFws/$(TLT_VERSION_FILE)$(if $(1),_$(word 1,$(1)))$(if $(findstring 1,$(FAKE_RELEASE_BUILD)),_FAKE).$(if $(word 2,$(1)),$(word 2,$(1)),bin) | tee /tmp/last_built.fw >"$(TMP_DIR)/last_built.fw"
	sed -e 's|$(TOPDIR)/||g' "$(TMP_DIR)"/last_built.fw >>"$(TMP_DIR)"/unsigned_fws
endef

define Build/finalize-tlt-webui
	$(call Build/finalize-tlt-custom,WEBUI bin)
endef

define Build/finalize-tlt-master-stendui
	[ -d $(BIN_DIR)/tltFws ] || mkdir -p $(BIN_DIR)/tltFws

	$(eval UBOOT_INSERTION=$(shell cat ${BIN_DIR}/u-boot_version))
	$(if $(UBOOT_INSERTION), $(eval UBOOT_INSERTION=_UBOOT_$(UBOOT_INSERTION)))
	$(if $(2), \
		$(eval TLT_VERSION_PREFIX := $(word 1,$(subst _, ,$(TLT_VERSION_FILE)))) \
		$(eval TLT_VERSION_SUFFIX := $(patsubst $(TLT_VERSION_PREFIX)_%,%,$(TLT_VERSION_FILE))) \
		$(eval FULL_VERSION_FILE := $(TLT_VERSION_PREFIX)_$(2)_$(TLT_VERSION_SUFFIX)) \
	,
		$(eval FULL_VERSION_FILE := $(TLT_VERSION_FILE)) \
	)
	$(CP) $@ $(BIN_DIR)/tltFws/$(FULL_VERSION_FILE)$(UBOOT_INSERTION)_MASTER_STENDUI$(word 1,$(1))$(if $(findstring 1,$(FAKE_RELEASE_BUILD)),_FAKE).bin
endef

define Build/kernel-bin
	rm -f $@
	cp $< $@
endef

define Build/lzma
	$(call Build/lzma-no-dict,-lc1 -lp2 -pb2 $(1))
endef

define Build/zstd
	cat $@ | zstd -o $@.new
	mv $@.new $@
endef

define Build/lzma-no-dict
	$(STAGING_DIR_HOST)/bin/lzma e $@ $(1) $@.new
	@mv $@.new $@
endef

define Build/pad-extra
	dd if=/dev/zero bs=$(1) count=1 >> $@
	echo "padding $@ with $(1) zeros"
endef

define Build/pad-offset
	let \
		size="$$(stat -c%s $@)" \
		pad="$(subst k,* 1024,$(word 1, $(1)))" \
		offset="$(subst k,* 1024,$(word 2, $(1)))" \
		pad="(pad - ((size + offset) % pad)) % pad" \
		newsize='size + pad'; \
		dd if=$@ of=$@.new bs=$$newsize count=1 conv=sync
	mv $@.new $@
endef

define Build/pad-rootfs
	$(STAGING_DIR_HOST)/bin/padjffs2 $@ $(1) \
		$(if $(BLOCKSIZE),$(BLOCKSIZE:%k=%),4 8 16 64 128 256)
endef

define Build/pad-to
	$(call Image/pad-to,$@,$(1))
endef

# Convert a raw image into a $1 type image.
# E.g. | qemu-image vdi
define Build/qemu-image
	if command -v qemu-img; then \
		qemu-img convert -f raw -O $1 $@ $@.new; \
		mv $@.new $@; \
	else \
		echo "WARNING: Install qemu-img to create VDI/VMDK images" >&2; exit 1; \
	fi
endef

define Build/sysupgrade-tar
	sh $(TOPDIR)/scripts/sysupgrade-tar.sh \
		--board $(if $(BOARD_NAME),$(BOARD_NAME),$(DEVICE_NAME)) \
		--kernel $(call param_get_default,kernel,$(1),$(IMAGE_KERNEL)) \
		--rootfs $(call param_get_default,rootfs,$(1),$(IMAGE_ROOTFS)) \
		$@
endef

define Build/uImage
	mkimage \
		-A $(LINUX_KARCH) \
		-O linux \
		-T kernel \
		-C $(word 1,$(1)) \
		-a $(KERNEL_LOADADDR) \
		-e $(if $(KERNEL_ENTRY),$(KERNEL_ENTRY),$(KERNEL_LOADADDR)) \
		-n '$(if $(UIMAGE_NAME),$(UIMAGE_NAME),$(call toupper,$(LINUX_KARCH)) $(VERSION_DIST) Linux-$(LINUX_VERSION))' \
		$(if $(UIMAGE_MAGIC),-M $(UIMAGE_MAGIC)) \
		$(wordlist 2,$(words $(1)),$(1)) \
		-d $@ $@.new
	mv $@.new $@
endef
