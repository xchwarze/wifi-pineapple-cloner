# -- Set up Networking configuration
uci set network.lan.type='bridge'
uci set network.lan.proto='static'
uci set network.lan.ipaddr='172.16.42.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='172.16.42.42'
uci set network.lan.dns='8.8.8.8, 8.8.4.4'

uci set network.usb=interface
uci set network.usb.ifname='usb0'
uci set network.usb.proto='dhcp'
uci set network.usb.dns='8.8.8.8, 8.8.4.4'

uci set network.wwan=interface
uci set network.wwan.proto='dhcp'
uci set network.wwan.dns='8.8.8.8, 8.8.4.4'

uci set network.wan.proto='dhcp'
uci set network.wan.dns='8.8.8.8, 8.8.4.4'

uci set network.wan6.proto='dhcpv6'
uci commit network

exit 0