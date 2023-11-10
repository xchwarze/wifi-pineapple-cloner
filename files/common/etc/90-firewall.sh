# -- Setup firewall configuration
uci set firewall.@defaults[0].syn_flood=1
uci set firewall.@defaults[0].input=ACCEPT
uci set firewall.@defaults[0].output=ACCEPT
uci set firewall.@defaults[0].forward=ACCEPT

uci add firewall zone
uci set firewall.@zone[-1]=zone
uci set firewall.@zone[-1].name=usb
uci add_list firewall.@zone[-1].network='usb'
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci set firewall.@zone[-1].masq=1
uci set firewall.@zone[-1].mtu_fix=1

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=lan
uci set firewall.@forwarding[-1].dest=usb

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=usb
uci set firewall.@forwarding[-1].dest=lan

uci add firewall zone
uci set firewall.@zone[-1]=zone
uci set firewall.@zone[-1].name=wwan
uci add_list firewall.@zone[-1].network=wwan
uci add_list firewall.@zone[-1].network=wwan6
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci set firewall.@zone[-1].masq=1
uci set firewall.@zone[-1].mtu_fix=1

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=lan
uci set firewall.@forwarding[-1].dest=wwan

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=wwan
uci set firewall.@forwarding[-1].dest=lan

uci add firewall zone
uci set firewall.@zone[-1].name=wan
uci add_list firewall.@zone[-1].network='wan'
uci add_list firewall.@zone[-1].network='wan6'
uci set firewall.@zone[-1].input=ACCEPT
uci set firewall.@zone[-1].output=ACCEPT
uci set firewall.@zone[-1].forward=ACCEPT
uci set firewall.@zone[-1].masq=1
uci set firewall.@zone[-1].mtu_fix=1

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=lan
uci set firewall.@forwarding[-1].dest=wan

uci add firewall forwarding
uci set firewall.@forwarding[-1].src=wan
uci set firewall.@forwarding[-1].dest=lan

uci add firewall allowssh
uci set firewall.allowssh=rule
uci set firewall.allowssh.name='Allow-SSH'
uci set firewall.allowssh.src='wan'
uci set firewall.allowssh.proto='tcp'
uci set firewall.allowssh.dest_port='22'
uci set firewall.allowssh.target='ACCEPT'
uci set firewall.allowssh.family='ipv4'
uci set firewall.allowssh.enabled='0'

uci add firewall allowui
uci set firewall.allowui=rule
uci set firewall.allowui.name='Allow-WEB'
uci set firewall.allowui.src='wan'
uci set firewall.allowui.proto='tcp'
uci set firewall.allowui.dest_port='1471'
uci set firewall.allowui.target='ACCEPT'
uci set firewall.allowui.family='ipv4'
uci set firewall.allowui.enabled='0'

uci add firewall allowws
uci set firewall.allowws=rule
uci set firewall.allowws.name='Allow-WEB-WS'
uci set firewall.allowws.src='wan'
uci set firewall.allowws.proto='tcp'
uci set firewall.allowws.dest_port='1337'
uci set firewall.allowws.target='ACCEPT'
uci set firewall.allowws.family='ipv4'
uci set firewall.allowws.enabled='1'

uci commit firewall

exit 0
