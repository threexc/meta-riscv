fdt_file=k1-x_MUSE-Pi-Pro.dtb

if test "${boot_device}" = "mmc" && test "${boot_devnum}" = "0"; then
    rootdev=/dev/mmcblk0p7
    bootpart=6
else
    rootdev=/dev/mmcblk2p6
    bootpart=5
fi

setenv bootargs "console=ttyS0,115200n8 loglevel=8 swiotlb=65536 rdinit=/init driver_async_probe=spacemit-hdmi-drv,i2c-spacemit-k1x,ri2c-spacemit-k1x,k1xccic,sdhci-spacemit,k1x-dwc-pcie,pxa2xx-uart root=${rootdev} rw rootwait rootfstype=ext4 clk_ignore_unused earlycon=sbi"

load mmc ${boot_devnum}:${bootpart} ${kernel_addr_r} Image
load mmc ${boot_devnum}:${bootpart} ${ramdisk_addr} initramfs.img
load mmc ${boot_devnum}:${bootpart} 0x31000000 ${fdt_file}

booti ${kernel_addr_r} ${ramdisk_addr} 0x31000000
