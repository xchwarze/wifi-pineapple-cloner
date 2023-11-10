# -- Setup system configuration

# Change the hostname
uci set system.@system[0].hostname=Pineapple
uci commit system
echo $(uci get system.@system[0].hostname) > /proc/sys/kernel/hostname

exit 0
