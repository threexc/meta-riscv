# K3 Image Common Functions
# This file contains shared functions for K3 image recipes

# Create bootfs partition with kernel, env, Initramfs and dtbs
# Layout matches the reference titan image (Bianbu-GNOME-K3)
# Triggered before ext4 rootfs generation and WIC image generation
do_image_wic[depends] += " \
    virtual/kernel:do_packagedata \
    core-image-minimal-initramfs:do_image_complete \
    e2fsprogs-native:do_populate_sysroot \
    bmaptool-native:do_populate_sysroot \
    util-linux-native:do_populate_sysroot \
"
do_image_wic[prefuncs] += "do_create_bootfs"

python do_create_bootfs() {
    import subprocess, os, shutil, gzip, math

    deploydir = d.getVar('DEPLOY_DIR_IMAGE')
    bootfs_dir = os.path.join(deploydir, 'bootfs')
    bootfs_img = os.path.join(deploydir, 'bootfs.ext4')
    machine = d.getVar('MACHINE')

    # Read kernel release (e.g. "6.18.3-k3") from the kernel's pkgdata.
    # Unlike work-shared (do_shared_workdir), pkgdata is restored from
    # sstate, so this works when the kernel itself isn't rebuilt.
    kpn = d.getVar('KERNEL_PACKAGE_NAME') or 'kernel'
    kabi_path = os.path.join(d.getVar('PKGDATA_DIR'), f'{kpn}-depmod',
                             f'{kpn}-abiversion')
    with open(kabi_path) as f:
        kver_k3 = f.read().strip()

    # 1. Reset and prepare bootfs directory
    bb.utils.remove(bootfs_dir, recurse=True)
    bb.utils.mkdirhier(bootfs_dir)

    # DTB subdirectory: spacemit/<version>/
    dtb_subdir = os.path.join(bootfs_dir, 'spacemit', kver_k3)
    bb.utils.mkdirhier(dtb_subdir)

    # Define helper function for copy logic
    def copy_file(src_name, dst_path):
        src = os.path.join(deploydir, src_name)
        if os.path.exists(src):
            shutil.copy2(src, dst_path)
            bb.note(f"Copied {src_name} to bootfs")
            return True
        else:
            bb.warn(f"File not found: {src_name}")
            return False

    # 2. Copy kernel (compressed vmlinuz)
    vmlinuz_name = f"vmlinuz-{kver_k3}"
    image_path = os.path.join(deploydir, 'Image')
    if not os.path.exists(image_path):
        bb.fatal("Image not found in DEPLOYDIR")
    with open(image_path, 'rb') as f_in:
        with gzip.open(os.path.join(bootfs_dir, vmlinuz_name), 'wb',
    compresslevel=9) as f_out:
            shutil.copyfileobj(f_in, f_out)

    # 3. Initramfs (rename to initrd.img-<version>)
    initrd_name = f"initrd.img-{kver_k3}"
    initramfs = next((f for f in os.listdir(deploydir)
                      if f.startswith('core-image-minimal-initramfs-') and f.endswith('.cpio.gz')), None)
    if initramfs:
        copy_file(initramfs, os.path.join(bootfs_dir, initrd_name))
    else:
        bb.fatal("initramfs not found")

    # 4. DTBs -> spacemit/<version>/
    dtbs = [f for f in os.listdir(deploydir)
            if f.endswith('.dtb') and not os.path.islink(os.path.join(deploydir, f))]
    if not dtbs:
        bb.warn("No DTB files found")
    for dtb in dtbs:
        copy_file(dtb, os.path.join(dtb_subdir, dtb))

    # 5. Calculate size and generate image (add 15% margin)
    total_size_kb = sum(os.path.getsize(os.path.join(root, f))
                        for root, dirs, files in os.walk(bootfs_dir)
                        for f in files) / 1024
    calc_mb = math.ceil((total_size_kb * 1.15) / 1024) + 1
    final_mb = max(int(d.getVar('SDIMG_BOOTFS_SIZE') or 256), calc_mb)

    # 6. env_k3.txt (generate to match reference image format)
    env_content = f"""knl_name={vmlinuz_name}
ramdisk_name={initrd_name}
dtb_dir=spacemit/{kver_k3}
ramdisk_addr=0x130000000
loglevel=8
commonargs=setenv bootargs earlycon=sbi console=ttyS0,115200 clk_ignore_unused plymouth.prefer-fbcon plymouth.ignore-serial-consoles
"""
    # Fallback DTB for when the board EEPROM has no product_name (which
    # otherwise selects ${dtb_dir}/${product_name}.dtb), e.g. under QEMU
    kdt = (d.getVar('KERNEL_DEVICETREE') or '').split()
    if kdt:
        env_content += f"dtb_name=spacemit/{kver_k3}/{os.path.basename(kdt[0])}\n"
    env_path = os.path.join(bootfs_dir, 'env_k3.txt')
    with open(env_path, 'w') as f:
        f.write(env_content)

    # 7. Call mke2fs to create ext4 image
    # Disable orphan_file and metadata_csum_seed: U-Boot 2022.10 ext4 driver
    # does not recognize these features and fails to mount the filesystem.
    cmd = ['mke2fs', '-F', '-L', 'bootfs', '-t', 'ext4',
           '-b', '4096',
           '-O', '^orphan_file,^metadata_csum_seed',
           '-d', bootfs_dir, bootfs_img, f'{final_mb}M']
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        bb.fatal(f"mke2fs failed: {r.stderr}")
    bb.note(f"bootfs.ext4 ({final_mb}MB) created successfully")
}

# Inject bootinfo into WIC image after WIC generation
do_image_wic[postfuncs] += "write_bootinfo_to_wic"

# runqemu finds the image through the timestamped IMAGE_NAME in the qemuboot
# conf, but do_write_qemuboot_conf only follows do_image. Firmware or bootfs
# changes only re-run do_image_wic, which would leave the conf pointing at
# the previous .wic, so make the conf follow do_image_wic too.
python () {
    if d.getVarFlag('do_write_qemuboot_conf', 'task'):
        bb.build.addtask('do_write_qemuboot_conf', None, 'do_image_wic', d)
}

python write_bootinfo_to_wic() {
    import subprocess, os, gzip, shutil

    imgdeploydir = d.getVar('IMGDEPLOYDIR')
    image_name = d.getVar('IMAGE_NAME')
    deploy_dir = d.getVar('DEPLOY_DIR_IMAGE')

    bootinfo_path = os.path.join(deploy_dir, 'bootinfo_block.bin')
    wic_gz_path = os.path.join(imgdeploydir, image_name + '.wic.gz')
    wic_bmap_path = os.path.join(imgdeploydir, image_name + '.wic.bmap')

    if not os.path.exists(bootinfo_path):
        bb.warn(f"[Post-WIC] bootinfo not found: {bootinfo_path} - skipping")
        return

    # A raw .wic is only present when "wic" is in IMAGE_FSTYPES (used by
    # runqemu); patch it in place and keep it.
    tmp_wic = wic_gz_path[:-3]  # strip .gz
    keep_raw = os.path.exists(tmp_wic)
    has_gz = os.path.exists(wic_gz_path)

    if not keep_raw and not has_gz:
        bb.error(f"[Post-WIC] WIC file not found: {wic_gz_path}")
        return

    try:
        if not keep_raw:
            with gzip.open(wic_gz_path, 'rb') as f_in, open(tmp_wic, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)

        r = subprocess.run(
            ['dd', f'if={bootinfo_path}', f'of={tmp_wic}',
             'bs=1K', 'seek=1024', 'count=128', 'conv=notrunc'],
            capture_output=True)
        if r.returncode != 0:
            bb.error(f"[Post-WIC] dd failed: {r.stderr.decode()}")
            return
        bb.note("[Post-WIC] Injected bootinfo (128K @ 1M)")

        if has_gz:
            with open(tmp_wic, 'rb') as f_in, gzip.open(wic_gz_path, 'wb', compresslevel=9) as f_out:
                shutil.copyfileobj(f_in, f_out)

        if os.path.exists(wic_bmap_path):
            r = subprocess.run(
                ['bmaptool', 'create', tmp_wic, '-o', wic_bmap_path],
                capture_output=True)
            if r.returncode == 0:
                bb.note("[Post-WIC] Regenerated bmap")
            else:
                bb.warn(f"[Post-WIC] bmaptool failed: {r.stderr.decode()}")

        # The raw .wic only exists for runqemu, so adapt it to the QEMU boot
        # media now that .wic.gz and .wic.bmap were made from the original.
        if keep_raw:
            media = d.getVar('K3_QEMU_BOOT_MEDIA')
            if media == 'sd':
                k3_qemu_pad_sd(tmp_wic)
            elif media == 'nor-ufs':
                k3_qemu_wic_to_4k(tmp_wic)
                nor = os.path.join(imgdeploydir, image_name + '.nor.bin')
                k3_qemu_make_nor(deploy_dir, nor)
                link = os.path.join(imgdeploydir, d.getVar('IMAGE_LINK_NAME') + '.nor.bin')
                if link != nor:
                    if os.path.lexists(link):
                        os.unlink(link)
                    os.symlink(os.path.basename(nor), link)
            else:
                bb.fatal(f"[Post-WIC] Unknown K3_QEMU_BOOT_MEDIA '{media}' (expected 'nor-ufs' or 'sd')")
    finally:
        if not keep_raw and os.path.exists(tmp_wic):
            os.unlink(tmp_wic)
}

def k3_qemu_pad_sd(wic):
    """QEMU's SD card model only accepts power-of-2 sizes: pad the image and
    move the backup GPT to the new end of the disk."""
    import os, subprocess

    size = os.path.getsize(wic)
    pow2 = 1 << (size - 1).bit_length()
    if pow2 == size:
        return
    os.truncate(wic, pow2)
    r = subprocess.run(['sfdisk', '--relocate', 'gpt-bak-std', wic],
                       capture_output=True, text=True)
    if r.returncode != 0:
        bb.fatal(f"[Post-WIC] sfdisk --relocate failed: {r.stderr}")
    bb.note(f"[Post-WIC] Padded raw wic to {pow2 >> 20} MiB for the QEMU SD card")

def k3_qemu_wic_to_4k(wic):
    """QEMU's UFS logical units use 4096-byte blocks, but wic writes a GPT
    for 512-byte sectors. Rewrite the partition table for 4096-byte sectors,
    keeping every partition at the same byte offset (the K3 layout is 4K
    aligned) so the bootinfo/FSBL/... offsets stay valid."""
    import os, json, subprocess

    r = subprocess.run(['sfdisk', '--json', wic], capture_output=True, text=True)
    if r.returncode != 0:
        bb.fatal(f"[Post-WIC] sfdisk --json failed: {r.stderr}")
    table = json.loads(r.stdout)['partitiontable']
    if table.get('sectorsize', 512) != 512:
        bb.fatal(f"[Post-WIC] Unexpected sector size in {wic}")
    parts = table['partitions']

    # first-lba 6 = protective MBR + GPT header + 16 KiB of entries
    lines = ['label: gpt', 'first-lba: 6', f"label-id: {table['id']}"]
    for p in parts:
        if p['start'] % 8:
            bb.fatal(f"[Post-WIC] {p['node']} is not 4K aligned, can't convert to 4K sectors")
        line = f"start={p['start'] // 8}, size={p['size'] // 8}, type={p['type']}, uuid={p['uuid']}"
        if p.get('name'):
            line += f", name=\"{p['name']}\""
        lines.append(line)

    old_size = os.path.getsize(wic)
    first = min(p['start'] for p in parts) * 512
    with open(wic, 'r+b') as f:
        # Drop the old 512-byte-sector GPT (primary after the MBR, backup in
        # the last 33 sectors) so nothing finds a stale table
        f.seek(512)
        f.write(bytes(first - 512))
        f.seek(old_size - 33 * 512)
        f.write(bytes(33 * 512))
    # Room for the 4K backup GPT, rounded to whole MiB
    os.truncate(wic, ((old_size >> 20) + 2) << 20)

    r = subprocess.run(['sfdisk', '--sector-size', '4096', '--wipe', 'never',
                        '--no-reread', '--no-tell-kernel', wic],
                       input='\n'.join(lines) + '\n', capture_output=True, text=True)
    if r.returncode != 0:
        bb.fatal(f"[Post-WIC] sfdisk (4K sectors) failed: {r.stderr}")
    bb.note("[Post-WIC] Rewrote raw wic partition table for 4096-byte sectors (QEMU UFS)")

def k3_qemu_make_nor(deploy_dir, out):
    """Assemble the SPI NOR boot firmware image for QEMU, using the NOR layout
    from docs/k3-pico-itx.md. QEMU models a w25q64 (8 MiB) and requires the
    image to be exactly that size."""
    import os

    size = 8 * 1024 * 1024
    K = 1024
    layout = [
        ('bootinfo_spinor.bin',    0,          128 * K),
        ('FSBL.bin',               128 * K,    512 * K),
        ('u-boot-env-default.bin', 640 * K,    64 * K),
        ('esos.itb',               704 * K,    1024 * K),
        ('fw_dynamic.itb',         1728 * K,   384 * K),
        ('u-boot.itb',             2112 * K,   size - 2112 * K),
    ]
    img = bytearray(b'\xff' * size)
    for name, offset, maxlen in layout:
        with open(os.path.join(deploy_dir, name), 'rb') as f:
            data = f.read()
        if len(data) > maxlen:
            bb.fatal(f"[Post-WIC] {name} ({len(data)} bytes) doesn't fit its {maxlen}-byte NOR partition")
        img[offset:offset + len(data)] = data
    with open(out, 'wb') as f:
        f.write(img)
    bb.note(f"[Post-WIC] Created QEMU NOR image {os.path.basename(out)}")
