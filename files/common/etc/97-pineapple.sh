# Make SSH banner have the correct version and device
version=$(cat /pineapple/pineapple_version | head -c 5)
eval "sed -i s/VERSION/$version/g /etc/banner"

# Configure PATH with SD card directories
echo "export PATH=/usr/bin/pineapple:/bin:/sbin:/usr/bin:/usr/sbin:/sd/bin:/sd/sbin:/sd/usr/sbin:/sd/usr/bin" >> /etc/profile
echo "export LD_LIBRARY_PATH=/lib:/usr/lib:/sd/lib:/sd/usr/lib" >> /etc/profile 

# Touch known hosts
mkdir -p /root/.ssh/
touch /root/.ssh/known_hosts

# "Temporarily" soft-link libpcap.so.1 to libpcap.so.1.3
ln -s /usr/lib/libpcap.so.1 /usr/lib/libpcap.so.1.3

# Disable AutoSSH
/etc/init.d/autossh stop
/etc/init.d/autossh disable

# Correct opkg sources
sed -i "s/src\/gz openwrt_freifunk/#src\/gz openwrt_freifunk/" /etc/opkg/distfeeds.conf
sed -i "s/src\/gz openwrt_luci/#src\/gz openwrt_luci/" /etc/opkg/distfeeds.conf
sed -i "s/src\/gz openwrt_telephony/#src\/gz openwrt_telephon/" /etc/opkg/distfeeds.conf

# Get valid led value
PINE_LED=""
LED_TYPES="wps status system wan"
LED_LIST=$(ls "/sys/class/leds/")
for LED_TYPE in $LED_TYPES; do
    for LED_NAME in $LED_LIST; do
        if expr match "$LED_NAME" "\(.*:$LED_TYPE\)"; then
            PINE_LED="$LED_NAME"
            break
        fi
    done

    if [[ $PINE_LED != "" ]]; then
        break
    fi
done

if [[ $PINE_LED == "" && $LED_LIST != "" ]]; then
    PINE_LED=$(ls "/sys/class/leds/" | tail -1)
fi

if [[ $PINE_LED != "" ]]; then
    sed -i "s/wifi-pineapple-nano:blue:system/$PINE_LED/" /sbin/led
    echo 255 > "/sys/class/leds/$PINE_LED/brightness"
fi

exit 0
