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


    echo "[*] Pineap"

    cp "$FILES_FOLDER/$ARCHITECTURE/pineap/pineapd" "$ROOT_FS/usr/sbin/pineapd"
    cp "$FILES_FOLDER/$ARCHITECTURE/pineap/pineap" "$ROOT_FS/usr/bin/pineap"
    cp "$FILES_FOLDER/$ARCHITECTURE/pineap/resetssids" "$ROOT_FS/usr/sbin/resetssids"
    cp "$FILES_FOLDER/$ARCHITECTURE/pineap/libwifi.so" "$ROOT_FS/usr/lib/libwifi.so"
    chmod +x "$ROOT_FS/usr/sbin/pineapd"
    chmod +x "$ROOT_FS/usr/bin/pineap"
    chmod +x "$ROOT_FS/usr/sbin/resetssids"
    chmod +x "$ROOT_FS/usr/lib/libwifi.so"


    echo "[*] Add Karma support"

    mkdir -p "$ROOT_FS/lib/netifd/wireless"
    cp "$FILES_FOLDER/common/karma/mac80211.sh" "$ROOT_FS/lib/netifd/wireless/mac80211.sh"
    cp "$FILES_FOLDER/common/karma/hostapd.sh" "$ROOT_FS/lib/netifd/hostapd.sh"
    cp "$FILES_FOLDER/$ARCHITECTURE/karma/hostapd_cli" "$ROOT_FS/usr/sbin/hostapd_cli"
    cp "$FILES_FOLDER/$ARCHITECTURE/karma/wpad" "$ROOT_FS/usr/sbin/wpad"
    chmod +x "$ROOT_FS/lib/netifd/wireless/mac80211.sh"
    chmod +x "$ROOT_FS/lib/netifd/hostapd.sh"
    chmod +x "$ROOT_FS/usr/sbin/hostapd_cli"
    chmod +x "$ROOT_FS/usr/sbin/wpad"


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
}

mipsel_patch () {
    echo "[*] Add mipsel support"
    
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/aircrack-ng" "$ROOT_FS/usr/bin/aircrack-ng"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/aireplay-ng" "$ROOT_FS/usr/sbin/aireplay-ng"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/airodump-ng" "$ROOT_FS/usr/sbin/airodump-ng"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/airodump-ng-oui-update" "$ROOT_FS/usr/sbin/airodump-ng-oui-update"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-osdep-1.5.2.so" "$ROOT_FS/usr/lib/libaircrack-osdep-1.5.2.so"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-ce-wpa-1.5.2.so" "$ROOT_FS/usr/lib/libaircrack-ce-wpa-1.5.2.so"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-osdep.so" "$ROOT_FS/usr/lib/libaircrack-osdep.so"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-ce-wpa.la" "$ROOT_FS/usr/lib/libaircrack-ce-wpa.la"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-ce-wpa.so" "$ROOT_FS/usr/lib/libaircrack-ce-wpa.so"
    cp "$FILES_FOLDER/$ARCHITECTURE/aircrack/libaircrack-osdep.la" "$ROOT_FS/usr/lib/libaircrack-osdep.la"
    chmod +x "$ROOT_FS/usr/bin/aircrack-ng"
    chmod +x "$ROOT_FS/usr/sbin/aireplay-ng"
    chmod +x "$ROOT_FS/usr/sbin/airodump-ng"
    chmod +x "$ROOT_FS/usr/sbin/airodump-ng-oui-update"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-osdep-1.5.2.so"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-ce-wpa-1.5.2.so"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-osdep.so"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-ce-wpa.la"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-ce-wpa.so"
    chmod +x "$ROOT_FS/usr/lib/libaircrack-osdep.la"

    cp "$FILES_FOLDER/$ARCHITECTURE/others/http_sniffer" "$ROOT_FS/usr/sbin/http_sniffer"
    chmod +x "$ROOT_FS/usr/sbin/http_sniffer"
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
common_patch
if [[ "$ARCHITECTURE" == "mipsel" ]]; then
    mipsel_patch
fi

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
