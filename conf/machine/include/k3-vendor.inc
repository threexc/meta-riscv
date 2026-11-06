#@TYPE: SOC
#@NAME: Spacemit K3
#@SOC: Spacemit K3
#@DESCRIPTION: SoC configuration for the Spacemit K3 - vendor repo version

require conf/machine/include/k3-common.inc

PREFERRED_PROVIDER_opensbi ?= "opensbi-k3"
PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-k3"
PREFERRED_PROVIDER_virtual/kernel ?= "linux-k3"

UBOOT_MACHINE = "k3_defconfig"

EXTRA_IMAGEDEPENDS += "esos-k3"

WKS_FILE ?= "spacemit-k3.wks"
