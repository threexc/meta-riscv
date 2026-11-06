#@TYPE: SOC
#@NAME: Spacemit K3
#@SOC: Spacemit K3
#@DESCRIPTION: SoC configuration for the Spacemit K3 - vendor repo version

require conf/machine/include/riscv-common.inc
require conf/machine/include/soc-family.inc

SOC_FAMILY = "k3"

SERIAL_CONSOLES = "115200;ttyS0"

# Both BSPs use the vendor SPL (FSBL.bin); the vendor BSP adds esos-k3
EXTRA_IMAGEDEPENDS += "virtual/bootloader u-boot-spl-spacemit"

# match the UFS storage block size
EXTRA_IMAGECMD:ext4 ?= "-i 4096 -b 4096"

KERNEL_IMAGETYPE = "Image"

IMAGE_FSTYPES = "ext4 wic.bmap wic.gz"
IMAGE_CLASSES += " k3-image"
INITRAMFS_FSTYPES = "cpio.gz"
WKS_FILE_DEPENDS:append = " virtual/bootloader u-boot-spl-spacemit"

MACHINE_FEATURES:append = " usbhost usbgadget"

MACHINE_EXTRA_RRECOMMENDS += "\
        linux-firmware-rtl8851 \
        linux-firmware-rtl8852 \
        linux-firmware-rtl8922 \
        "

# FIT kernel load address for linux-yocto-fitimage: where the vendor U-Boot's
# booti relocates an Image to, i.e. its ram_base (DRAM at 0x100000000 plus
# a 32 MiB secure region) plus the Image's 2 MiB text_offset. DRAM is above
# 4 GiB, so FIT addresses need two cells.
FIT_ADDRESS_CELLS = "2"
UBOOT_ENTRYPOINT ?= "0x00000001 0x02200000"
