obj-$(CONFIG_ARCH_IPQSOC) += ipqsoc/

ifeq ($(CONFIG_SYS_SOC),"mt7621")
	obj-y += mt7621/
endif
ifeq ($(CONFIG_SYS_SOC),"mt7628")
	obj-y += mt7628/
endif

obj-y += mnf_cmd.o
obj-$(CONFIG_TLT_FAILSAFEBOOT) += fsupdate.o
