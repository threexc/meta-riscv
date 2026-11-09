#@TYPE: SOC
#@NAME: Spacemit K3
#@SOC: Spacemit K3
#@DESCRIPTION: SoC configuration for the Spacemit K3 - mainline kernel version

require conf/machine/include/k3-common.inc

# Boot chain, following "Guide to build reduced SpacemiT K3 vendor BSP":
# https://lore.kernel.org/u-boot/20261029003327.1890979-1-e@freeshell.de/
#
# SPL/FSBL: u-boot-spl-spacemit (vendor, k3-br-v1.0.10)
# OpenSBI + U-Boot: u-boot.itb from mainline U-Boot, with mainline OpenSBI
#
# The vendor SPL loads u-boot.itb from the "opensbi" partition. No esos or
# vendor U-Boot is used.
#
# u-boot-spl-spacemit-reduced additionally deploys the guide's reduced SPLs
# (u-boot-spl-mkimage-uart-{spi,nospi}.bin), for staging over BootROM USB
# download mode and loading u-boot.itb over serial YMODEM.
MACHINEOVERRIDES =. "k3-mainline:"

PREFERRED_PROVIDER_opensbi ?= "opensbi"
PREFERRED_PROVIDER_virtual/bootloader ?= "u-boot"
PREFERRED_PROVIDER_virtual/kernel ?= "linux-mainline"

# u-boot.itb carries OpenSBI as fw_dynamic, so OpenSBI needs no payload. The
# riscv-common.inc default (u-boot.bin) would make OpenSBI depend on U-Boot,
# which itself depends on OpenSBI.
unset RISCV_SBI_PAYLOAD

EXTRA_IMAGEDEPENDS += "u-boot-spl-spacemit-reduced"

UBOOT_MACHINE = "spacemit_k3_defconfig"

# No boot script: the riscv-common.inc default (boot.scr.uimg from boot.cmd)
# does not exist for K3, which boots via standard boot or a FIT from the
# U-Boot prompt.
UBOOT_ENV = ""

WKS_FILE ?= "spacemit-k3-mainline.wks"
