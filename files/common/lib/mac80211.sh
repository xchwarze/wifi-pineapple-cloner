#!/bin/sh
append DRIVERS "mac80211"

lookup_phy() {
	[ -n "$phy" ] && {
		[ -d /sys/class/ieee80211/$phy ] && return
	}

	local devpath
	config_get devpath "$device" path
	[ -n "$devpath" ] && {
		for _phy in /sys/devices/$devpath/ieee80211/phy*; do
			[ -e "$_phy" ] && {
				phy="${_phy##*/}"
				return
			}
		done
	}

	local macaddr="$(config_get "$device" macaddr | tr 'A-Z' 'a-z')"
	[ -n "$macaddr" ] && {
		for _phy in /sys/class/ieee80211/*; do
			[ -e "$_phy" ] || continue

			[ "$macaddr" = "$(cat ${_phy}/macaddress)" ] || continue
			phy="${_phy##*/}"
			return
		done
	}
	phy=
	return
}

find_mac80211_phy() {
	local device="$1"

	config_get phy "$device" phy
	lookup_phy
	[ -n "$phy" -a -d "/sys/class/ieee80211/$phy" ] || {
		echo "PHY for wifi device $1 not found"
		return 1
	}
	config_set "$device" phy "$phy"

	config_get macaddr "$device" macaddr
	[ -z "$macaddr" ] && {
		config_set "$device" macaddr "$(cat /sys/class/ieee80211/${phy}/macaddress)"
	}

	return 0
}

check_mac80211_device() {
	config_get phy "$1" phy
	[ -z "$phy" ] && {
		find_mac80211_phy "$1" >/dev/null || return 0
		config_get phy "$1" phy
	}
	[ "$phy" = "$dev" ] && found=1
}

detect_mac80211() {
	devidx=0
	config_load wireless
	while :; do
		config_get type "radio$devidx" type
		[ -n "$type" ] || break
		devidx=$(($devidx + 1))
	done

	for _dev in /sys/class/ieee80211/*; do
		[ -e "$_dev" ] || continue

		dev="${_dev##*/}"

		found=0
		config_foreach check_mac80211_device wifi-device
		[ "$found" -gt 0 ] && continue

		mode_band="g"
		channel="11"
		htmode=""
		ht_capab=""

		iw phy "$dev" info | grep -q 'Capabilities:' && htmode=HT20
		iw phy "$dev" info | grep -q '2412 MHz' || { mode_band="a"; channel="36"; }

		vht_cap=$(iw phy "$dev" info | grep -c 'VHT Capabilities')
		cap_5ghz=$(iw phy "$dev" info | grep -c "Band 2")
		[ "$vht_cap" -gt 0 -a "$cap_5ghz" -gt 0 ] && {
			mode_band="a";
			channel="36"
			htmode="VHT80"
		}

		[ -n $htmode ] && append ht_capab "	option htmode	$htmode" "$N"

		if [ -x /usr/bin/readlink -a -h /sys/class/ieee80211/${dev} ]; then
			path="$(readlink -f /sys/class/ieee80211/${dev}/device)"
		else
			path=""
		fi
		if [ -n "$path" ]; then
			path="${path##/sys/devices/}"
			dev_id="	option path	'$path'"
		else
			dev_id="	option macaddr	$(cat /sys/class/ieee80211/${dev}/macaddress)"
		fi

		cat <<EOF
config wifi-device  radio$devidx
        option type     mac80211
        option channel  ${channel}
        option hwmode   11${mode_band}
$dev_id
$ht_capab
config wifi-iface
        option device   radio$devidx
$(if [ $devidx -gt 0 ]; then
        echo -e "\toption ifname   wlan$devidx";
fi)
        option network  lan
        option mode     $(if [[ "$devidx" == "0" ]] ; then echo ap ; else echo sta ; fi)
        option ssid     Pineapple_$(cat /sys/class/ieee80211/${dev}/macaddress|awk -F ":" '{print $5""$6 }'| tr a-z A-Z)
$(if [ $devidx -eq 0 ]; then
		echo -e "\toption ifname   wlan0";
        echo -e "\toption maxassoc   100";
fi)
        option encryption none
$(if [[ "$devidx" == "0" ]]; then
        echo config wifi-iface

        echo -e "\toption device   radio$devidx";
        echo -e "\toption ifname   wlan0-1";
        echo -e "\toption network  lan";
        echo -e "\toption mode     ap";
        echo -e "\toption ssid     Management";
        echo -e "\toption encryption psk2+ccmp";
        echo -e "\toption key      'pineapplesareyummy'";
        echo -e "\toption disabled 1";

        echo config wifi-iface
        echo -e "\toption device   radio$devidx";
        echo -e "\toption ifname   wlan0-2";
        echo -e "\toption network  lan";
        echo -e "\toption mode     ap";
        echo -e "\toption ssid     PineAP_Enterprise";
        echo -e "\toption macaddr  00:11:22:33:44:55";
        echo -e "\toption encryption wpa2+ccmp";
        echo -e "\toption key      12345678";
        echo -e "\toption server   127.0.0.1";
        echo -e "\toption disabled 1";
fi)

$(if [[ "$devidx" == "2" ]]; then
        echo config wifi-iface

        echo -e "\toption device   radio$devidx";
        echo -e "\toption ifname   wlan2";
        echo -e "\toption network  lan";
        echo -e "\toption mode     sta";
        echo -e "\toption disabled 0";
fi)
EOF
	devidx=$(($devidx + 1))
	done
}

