#@TYPE: SOC
#@NAME: Spacemit K3
#@SOC: Spacemit K3
#@DESCRIPTION: SoC configuration for the Spacemit K3 - mainline kernel version

require conf/machine/include/k3-common.inc

# Only the kernel is mainline-based for now; everything else comes from vendor
# variants:
#
# SPL/FSBL: u-boot-spl-spacemit
# esos: esos-k3
# OpenSBI: opensbi-k3
# U-Boot: u-boot-k3
#
MACHINEOVERRIDES =. "k3-mainline:"

PREFERRED_PROVIDER_opensbi ?= "opensbi-k3"
PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot-k3"
PREFERRED_PROVIDER_virtual/kernel ?= "linux-mainline"

UBOOT_MACHINE = "k3_defconfig"

EXTRA_IMAGEDEPENDS += "esos-k3"

WKS_FILE ?= "spacemit-k3.wks"
