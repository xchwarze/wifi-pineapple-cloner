#!/bin/bash
# by DSR! from https://github.com/xchwarze/wifi-pineapple-cloner

ARCHITECTURE="$1"
FLAVOR="$2"
ROOT_FS="$3"
declare -a ARCHITECTURE_TYPES=("mips" "mipsel")
declare -a FLAVOR_TYPES=("nano" "tetra" "universal")
if [[ ! -d "$ROOT_FS" ]] || ! grep -q "$ARCHITECTURE" <<< "${ARCHITECTURE_TYPES[*]}" || ! grep -q "$FLAVOR" <<< "${FLAVOR_TYPES[*]}"; then
    echo "Run with \"fs-patcher.sh [ARCHITECTURE] [FLAVOR] [FS_FOLDER]\""
    echo "    ARCHITECTURE  -> must be one of these values: mips, mipsel"
    echo "    FLAVOR        -> must be one of these values: nano, tetra, universal"
    echo "    FS_FOLDER     -> folder containing the fs to use"

    exit 1
fi

ROOT_FS="$(realpath $ROOT_FS)"
FILES_FOLDER="$(realpath $(dirname $0)/../files)"



common_patch () {
    echo "[*] Device detection fix"

    # fix "unknown operand" error
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/hotplug.d/block/20-sd"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/hotplug.d/usb/30-sd"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/init.d/pineapple"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/rc.button/BTN_1"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/rc.button/reset"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/rc.local"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/uci-defaults/90-firewall.sh"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/uci-defaults/91-fstab.sh"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/uci-defaults/92-system.sh"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/uci-defaults/95-network.sh"
    sed -i 's/print $6/print $1/' "$ROOT_FS/etc/uci-defaults/97-pineapple.sh"
    sed -i 's/print $6/print $1/' "$ROOT_FS/sbin/led"

    # force setup
    sed -i 's/..Get Device/device="NANO"/' "$ROOT_FS/etc/rc.button/BTN_1"
    sed -i 's/..Get Device/device="NANO"/' "$ROOT_FS/etc/rc.button/reset"
    sed -i 's/..Get Device/device="NANO"/' "$ROOT_FS/etc/rc.local"
    sed -i 's/..Get Version and Device/device="TETRA"/' "$ROOT_FS/etc/uci-defaults/90-firewall.sh"
    sed -i 's/..Get Version and Device/device="NANO"/' "$ROOT_FS/etc/uci-defaults/91-fstab.sh"
    sed -i 's/..Get Version and Device/device="NANO"/' "$ROOT_FS/etc/uci-defaults/95-network.sh"
    sed -i 's/..Get Version and Device/device="NANO"/' "$ROOT_FS/etc/uci-defaults/97-pineapple.sh"
    sed -i 's/..Get device type/device="NANO"/' "$ROOT_FS/etc/uci-defaults/92-system.sh"
    #sed -i 's/..led (C) Hak5 2018/device="NANO"/' "$ROOT_FS/sbin/led"


    echo "[*] Correct OPKG feed url"

    cp "$FILES_FOLDER/$ARCHITECTURE/customfeeds.conf" "$ROOT_FS/etc/opkg/customfeeds.conf"


    echo "[*] Install panel fixes and improvements"

    # update panel code
    rm -rf "$ROOT_FS/pineapple"
    wget -q https://github.com/xchwarze/wifi-pineapple-panel/archive/refs/heads/wpc.zip -O updated-panel.zip
    unzip -q updated-panel.zip

    cp -r wifi-pineapple-panel-wpc/src/* "$ROOT_FS/"
    rm -rf wifi-pineapple-panel-wpc updated-panel.zip

    chmod +x "$ROOT_FS/etc/init.d/pineapd"
    chmod +x "$ROOT_FS/etc/uci-defaults/93-pineap.sh"
    chmod +x "$ROOT_FS/pineapple/modules/Advanced/formatSD/format_sd"
    chmod +x "$ROOT_FS/pineapple/modules/Help/files/debug"
    chmod +x "$ROOT_FS/pineapple/modules/PineAP/executable/executable"
    chmod +x "$ROOT_FS/pineapple/modules/Reporting/files/reporting"

    cp "$FILES_FOLDER/common/pineapple/favicon.ico" "$ROOT_FS/pineapple/img/favicon.ico"
    cp "$FILES_FOLDER/common/pineapple/favicon-16x16.png" "$ROOT_FS/pineapple/img/favicon-16x16.png"
    cp "$FILES_FOLDER/common/pineapple/favicon-32x32.png" "$ROOT_FS/pineapple/img/favicon-32x32.png"

    # fix docs size
    truncate -s 0 "$ROOT_FS/pineapple/modules/Setup/eula.txt"
    truncate -s 0 "$ROOT_FS/pineapple/modules/Setup/license.txt"


    echo "[*] Enable ssh by default"

    sed -i 's/\/etc\/init.d\/sshd/#\/etc\/init.d\/sshd/' "$ROOT_FS/etc/rc.local"


    echo "[*] Change root password to: root"

    cp "$FILES_FOLDER/common/etc/shadow" "$ROOT_FS/etc/shadow"


    echo "[*] Fix uci-defaults"

    cp "$FILES_FOLDER/common/etc/92-system.sh" "$ROOT_FS/etc/uci-defaults/92-system.sh"
    cp "$FILES_FOLDER/common/etc/95-network.sh" "$ROOT_FS/etc/uci-defaults/95-network.sh"
    cp "$FILES_FOLDER/common/etc/97-pineapple.sh" "$ROOT_FS/etc/uci-defaults/97-pineapple.sh"


    echo "[*] Fix pendrive hotplug"

    cp "$FILES_FOLDER/common/etc/20-sd-universal" "$ROOT_FS/etc/hotplug.d/block/20-sd-universal"
    rm "$ROOT_FS/etc/hotplug.d/block/20-sd"
    rm "$ROOT_FS/etc/hotplug.d/usb/30-sd"


    echo "[*] Add support for reflash"

    mkdir -p "$ROOT_FS/lib/upgrade/keep.d"
    cp "$FILES_FOLDER/common/lib/pineapple.keep" "$ROOT_FS/lib/upgrade/keep.d/pineapple"


    echo "[*] Fix airmon-ng listInterfaces()"

    mkdir -p "$ROOT_FS/usr/sbin"
    cp "$FILES_FOLDER/common/usr/airmon-ng" "$ROOT_FS/usr/sbin/airmon-ng"
    chmod +x "$ROOT_FS/usr/sbin/airmon-ng"


    echo "[*] Add wpc-tools and service"

    cp "$FILES_FOLDER/common/etc/wpc-tools" "$ROOT_FS/etc/init.d/wpc-tools"
    cp "$FILES_FOLDER/common/usr/wpc-tools" "$ROOT_FS/usr/bin/wpc-tools"
    chmod +x "$ROOT_FS/etc/init.d/wpc-tools"
    chmod +x "$ROOT_FS/usr/bin/wpc-tools"


    echo "[*] Other fixs"

    # clean files
    rm -f "$ROOT_FS/etc/pineapple/changes"
    rm -f "$ROOT_FS/etc/pineapple/pineapple_version"

    # default wifi config
    cp "$FILES_FOLDER/common/lib/mac80211.sh" "$ROOT_FS/lib/wifi/mac80211.sh"

    # fix wifi detection
    cp "$FILES_FOLDER/common/etc/30-fix_wifi" "$ROOT_FS/etc/hotplug.d/usb/30-fix_wifi"

    # copy clean version of led script
    cp "$FILES_FOLDER/common/sbin/led" "$ROOT_FS/sbin/led"
    chmod +x "$ROOT_FS/sbin/led"

    # add setup support for routers that do not have a reset button but do have wps
    # this modified the package "hostapd-common" wps button script
    mkdir -p "$ROOT_FS/etc/rc.button"
    cp "$FILES_FOLDER/common/etc/wps" "$ROOT_FS/etc/rc.button/wps"
    chmod +x "$ROOT_FS/etc/rc.button/wps"

    # add new banner
    cp "$FILES_FOLDER/common/etc/banner" "$ROOT_FS/etc/banner"

    # patch elf files
    if [[ "$ARCHITECTURE" == "mips" ]]; then
        xxd "$ROOT_FS/usr/bin/pineap" "$ROOT_FS/usr/bin/pineap.hex"
        rm "$ROOT_FS/usr/bin/pineap"
        sed -i 's/6361 7420 2f70 726f 632f 636d 646c 696e/6563 686f 2027 5049 4e45 4150 504c 452d/' "$ROOT_FS/usr/bin/pineap.hex"
        sed -i 's/6520 7c20 6177 6b20 277b 2073 706c 6974/5445 5452 4127 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/bin/pineap.hex"
        sed -i 's/2824 312c 782c 223d 2229 3b20 7072 696e/2020 2020 2020 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/bin/pineap.hex"
        sed -i 's/7420 785b 325d 207d 2700 0000 5749 4649/2020 2020 2020 2020 2000 0000 5749 4649/' "$ROOT_FS/usr/bin/pineap.hex"
        sed -i 's/6420 7379 6e74 6178 2065 6e61 626c 6564/6420 5B57 5043 2056 4552 5349 4F4E 5D20/' "$ROOT_FS/usr/bin/pineap.hex"
        xxd -r "$ROOT_FS/usr/bin/pineap.hex" "$ROOT_FS/usr/bin/pineap"
        rm "$ROOT_FS/usr/bin/pineap.hex"

        xxd "$ROOT_FS/usr/sbin/pineapd" "$ROOT_FS/usr/sbin/pineapd.hex"
        rm "$ROOT_FS/usr/bin/pineap"
        sed -i 's/6361 7420 2f70 726f 632f 636d 646c 696e/6563 686f 2027 5049 4e45 4150 504c 452d/' "$ROOT_FS/usr/sbin/pineapd.hex"
        sed -i 's/6520 7c20 6177 6b20 277b 2073 706c 6974/5445 5452 4127 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
        sed -i 's/2824 312c 782c 223d 2229 3b20 7072 696e/2020 2020 2020 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
        sed -i 's/7420 785b 325d 207d 2700 0000 5749 4649/2020 2020 2020 2020 2000 0000 5749 4649/' "$ROOT_FS/usr/sbin/pineapd.hex"
        xxd -r "$ROOT_FS/usr/sbin/pineapd.hex" "$ROOT_FS/usr/sbin/pineapd"
        rm "$ROOT_FS/usr/sbin/pineapd.hex"
    fi
}

mipsel_patch () {
    echo "[*] Add mipsel support"
    
    if [ ! -f "$ROOT_FS/usr/sbin/sniffer" ]; then
        echo "[!] Attention!"
        echo ""
        echo "File '/usr/sbin/sniffer' was not found."
        echo "If you want to generate a mipsel-compatible build you must first perform the following steps:"
        echo "  1. Download the firmware v1.1.1 of the Mark VII"
        echo "  2. Execute the mass copy script with the mipsel-support.filelist list"
        echo "     tools/copier.sh lists/mipsel-support.filelist rootfs-mk7 rootfs true"
        echo ""

        exit 1
    fi

    # use old name for sniffer
    rm "$ROOT_FS/usr/sbin/http_sniffer"
    mv "$ROOT_FS/usr/sbin/sniffer" "$ROOT_FS/usr/sbin/http_sniffer"

    # patch elf files
    xxd "$ROOT_FS/usr/bin/pineap" "$ROOT_FS/usr/bin/pineap.hex"
    rm "$ROOT_FS/usr/bin/pineap"
    sed -i 's/6420 7379 6e74 6178 2065 6e61 626c 6564/6420 5B57 5043 2056 4552 5349 4F4E 5D20/' "$ROOT_FS/usr/bin/pineap.hex"
    xxd -r "$ROOT_FS/usr/bin/pineap.hex" "$ROOT_FS/usr/bin/pineap"
    rm "$ROOT_FS/usr/bin/pineap.hex"

    xxd "$ROOT_FS/usr/sbin/pineapd" "$ROOT_FS/usr/sbin/pineapd.hex"
    rm "$ROOT_FS/usr/sbin/pineapd"
    sed -i 's/3030 3a30 3000 0000 202d 2000 6865 6164/3030 3a30 3000 0000 202d 2000 6563 686f/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/202d 6e32 202f 7072 6f63 2f63 7075 696e/2027 4861 6b35 2057 6946 6920 5069 6e65/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/666f 207c 2074 6169 6c20 2d6e 2031 207c/6170 706c 6520 4d61 726b 2037 2720 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/2061 776b 2027 7b70 7269 6e74 2824 332c/2020 2020 2020 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/2434 2c24 352c 2436 2c24 3729 7d27 0000/2020 2020 2020 2020 2020 2020 2020 0000/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/6865 6164 202d 6e31 3020 2f70 726f 632f/6563 686f 2027 5b30 7830 6666 632c 2030/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/6370 7569 6e66 6f20 7c20 7461 696c 202d/7830 6666 632c 2030 7830 6666 622c 2030/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/6e20 3120 7c20 6177 6b20 277b 2070 7269/7830 6666 625d 2720 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/6e74 2824 392c 2431 302c 2431 312c 2431/2020 2020 2020 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/3229 3b20 7d27 0000 6865 6164 202d 6e35/2020 2020 2020 0000 6563 686f 2027 3338/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/202f 7072 6f63 2f63 7075 696e 666f 207c/352e 3834 2720 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/2074 6169 6c20 2d6e 2031 207c 2061 776b/2020 2020 2020 2020 2020 2020 2020 2020/' "$ROOT_FS/usr/sbin/pineapd.hex"
    sed -i 's/2027 7b70 7269 6e74 2824 3329 7d27 0000/2020 2020 2020 2020 2020 2020 2020 0000/' "$ROOT_FS/usr/sbin/pineapd.hex"
    xxd -r "$ROOT_FS/usr/sbin/pineapd.hex" "$ROOT_FS/usr/sbin/pineapd"
    rm "$ROOT_FS/usr/sbin/pineapd.hex"
}

nano_patch () {
    # correct python-codecs version (from python-codecs_2.7.18-3_mips_24kc.ipk)
    mkdir -p "$ROOT_FS/usr/lib/python2.7/encodings"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/__init__.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/__init__.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/aliases.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/aliases.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/base64_codec.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/base64_codec.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/hex_codec.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/hex_codec.pyc"

    # panel changes
    # sed -i "s/\$data = file_get_contents('\/proc\/cpuinfo')/return 'nano'/" "$ROOT_FS/pineapple/api/pineapple.php"
    cp "$FILES_FOLDER/common/pineapple/config.php.nano" "$ROOT_FS/pineapple/config.php"

    # other changes
    sed -i "s/exec(\"cat \/proc\/cpuinfo | grep 'machine'\")/'nano'/" "$ROOT_FS/usr/bin/pineapple/site_survey"

    # fix banner info
    sed -i 's/DEVICE/NANO/' "$ROOT_FS/etc/banner"
}

tetra_patch () {
    # correct python-codecs version (from python-codecs_2.7.18-3_mips_24kc.ipk)
    mkdir -p "$ROOT_FS/usr/lib/python2.7/encodings"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/__init__.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/__init__.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/aliases.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/aliases.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/base64_codec.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/base64_codec.pyc"
    cp "$FILES_FOLDER/$ARCHITECTURE/python/encodings/hex_codec.pyc" "$ROOT_FS/usr/lib/python2.7/encodings/hex_codec.pyc"

    # panel changes
    # sed -i 's/tetra/nulled/' "$ROOT_FS/pineapple/js/directives.js"
    # sed -i 's/tetra/nulled/' "$ROOT_FS/pineapple/modules/ModuleManager/js/module.js"
    # sed -i 's/tetra/nulled/' "$ROOT_FS/pineapple/modules/Advanced/module.html"
    # sed -i 's/nano/tetra/' "$ROOT_FS/pineapple/html/install-modal.html"
    # sed -i 's/nano/tetra/' "$ROOT_FS/pineapple/modules/Advanced/module.html"
    # sed -i 's/nano/tetra/' "$ROOT_FS/pineapple/modules/ModuleManager/js/module.js"
    # sed -i 's/nano/tetra/' "$ROOT_FS/pineapple/modules/Reporting/js/module.js"
    # sed -i 's/nano/tetra/' "$ROOT_FS/pineapple/modules/Reporting/api/module.php"
    # sed -i "s/\$data = file_get_contents('\/proc\/cpuinfo')/return 'tetra'/" "$ROOT_FS/pineapple/api/pineapple.php"
    cp "$FILES_FOLDER/common/pineapple/config.php.tetra" "$ROOT_FS/pineapple/config.php"

    # other changes
    sed -i "s/exec(\"cat \/proc\/cpuinfo | grep 'machine'\")/'tetra'/" "$ROOT_FS/usr/bin/pineapple/site_survey"

    # fix banner info
    sed -i 's/DEVICE/TETRA/' "$ROOT_FS/etc/banner"
}

universal_patch () {
    # panel changes
    cp "$FILES_FOLDER/common/pineapple/config.php.tetra" "$ROOT_FS/pineapple/config.php"

    # other changes
    sed -i "s/exec(\"cat \/proc\/cpuinfo | grep 'machine'\")/'tetra'/" "$ROOT_FS/usr/bin/pineapple/site_survey"

    # fix banner info
    sed -i 's/DEVICE/OMEGA/' "$ROOT_FS/etc/banner"
}



# implement....
echo "Wifi Pineapple Cloner v4"
echo "by DSR!"
echo "******************************"
echo ""

# apply patches in order
if [[ "$ARCHITECTURE" == "mipsel" ]]; then
    mipsel_patch
fi
common_patch

echo "[*] Setting target as: $FLAVOR"
if [[ $FLAVOR = 'nano' ]]
then
    nano_patch
elif [[ $FLAVOR = 'tetra' ]]
then
    tetra_patch
elif [[ $FLAVOR = 'universal' ]]
then
    universal_patch
fi

echo "[*] Done!"
echo ""
