#!/bin/bash
# by DSR! from https://github.com/xchwarze/wifi-pineapple-cloner

OPENWRT_VERSION="19.07.7"
OPENWRT_BASE_URL="https://downloads.openwrt.org/releases/$OPENWRT_VERSION/targets"
declare -a OPENWRT_MIPS_TARGET_LIST=(
    "ar71xx-generic" "ar71xx-nand" "ath79-generic" "lantiq-xrx200"
)
declare -a OPENWRT_MIPSEL_TARGET_LIST=(
    "ramips-mt7620" "ramips-mt7621" "ramips-mt76x8"
)

install_openwrt_deps () {
    TARGET="$1"

    FOLDER_NAME="imagebuilder-$OPENWRT_VERSION-$TARGET"
    ORIGINAL_FOLDER_NAME="openwrt-imagebuilder-$OPENWRT_VERSION-$TARGET.Linux-x86_64"
    FILE="$FOLDER_NAME.tar.xz"

    # download imagebuilder
    if [ ! -d "$FOLDER_NAME" ]; then
        if [ ! -f "$FILE" ]; then
            echo "    [+] Downloading imagebuilder..."
            TYPE=$(echo $TARGET | sed "s/-/\//g")
            wget -q "$OPENWRT_BASE_URL/$TYPE/$ORIGINAL_FOLDER_NAME.tar.xz" -O "$FILE"
        fi

        # install...
        echo "    [+] Install imagebuilder..."
        rm -rf "$FOLDER_NAME"
        tar xJf "$FILE"
        mv "$ORIGINAL_FOLDER_NAME" "$FOLDER_NAME"

        # correct opkg feeds
        echo "    [+] Correct opkg feeds"
        sed -i "s/src\/gz openwrt_freifunk/#/" "$FOLDER_NAME/repositories.conf"
        sed -i "s/src\/gz openwrt_luci/#/" "$FOLDER_NAME/repositories.conf"
        sed -i "s/src\/gz openwrt_telephony/#/" "$FOLDER_NAME/repositories.conf"
    fi
}

install_ubuntu_deps () {
    echo "Install ubuntu deps..."
    echo "******************************"

    # install deps openwrt make and others
    apt-get install build-essential python2 wget gawk libncurses5-dev libncursesw5-dev zip rename -y

    # install binwalk
    git clone https://github.com/ReFirmLabs/binwalk
    cd binwalk && sudo python3 setup.py install && sudo ./deps.sh

    echo ""
    echo "[*] Install script end!"
}

install_openwrt_deps_mips () {
    echo "Install OpenWrt MIPS deps..."
    echo "******************************"

    for TARGET in ${OPENWRT_MIPS_TARGET_LIST[@]}; do
        echo "[*] Install: $TARGET"
        install_openwrt_deps $TARGET
    done

    echo ""
    echo "[*] Install script end!"
}

install_openwrt_deps_mipsel () {
    echo "Install OpenWrt MIPSEL deps..."
    echo "******************************"

    for TARGET in ${OPENWRT_MIPSEL_TARGET_LIST[@]}; do
        echo "[*] Install: $TARGET"
        install_openwrt_deps $TARGET
    done

    echo ""
    echo "[*] Install script end!"
}



echo "Wifi Pineapple Cloner - dependencies"
echo "************************************** by DSR!"
echo ""

if [ "$1" == "openwrt-deps-mips" ]
then
    install_openwrt_deps_mips
elif [ "$1" == "openwrt-deps-mipsel" ]
then
    install_openwrt_deps_mipsel
elif [ "$1" == "ubuntu-deps" ]
then
    install_ubuntu_deps
else
    echo "Valid command:"
    echo "openwrt-deps-mips    -> install imagebuilders for mips and configure it"
    echo "openwrt-deps-mipsel  -> install imagebuilders for mipsel and configure it"
    echo "ubuntu-deps          -> install ubuntu dependencies"
fi
