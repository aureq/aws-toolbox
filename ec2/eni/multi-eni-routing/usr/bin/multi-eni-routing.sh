#!/bin/bash

TS=$(date +%s)
RT_TABLE_OFFSET=10

# How this works:
#   - sanity checks
#   - (re)creates route table in /etc/iproute2/rt_tables
#   - flushes internal route table
#   - applies new route table
#   - flushes iptables rules (for safety)
#   - applies iptables rules

function usage() {
	echo -e "$0 [-f] [-h]"
	echo -e "\t-f: instead of flushing and applying the routing rules, only flush the rules."
	echo -e "\t-h: display this short help message."
	exit 1
}

# this function removes all custom route tables
# and the associated firewall mark used by iptables
function remove_route_tables() {
	cat /etc/iproute2/rt_tables | sed '/^#/d; /local/d; /main/d; /default/d; /unspec/d; /^$/d;' | while read LINE; do
		RT_ID=$(echo $LINE | awk '{print $1}')
		RT_NAME=$(echo $LINE | awk '{print $2}')

		[ -z "$RT_ID" -o -z "$RT_NAME" ] && continue

		ip route flush table $RT_NAME 2>/dev/null
		ip rule del from all fwmark $RT_ID table $RT_NAME 2>/dev/null
	done
	ip route flush cache
}

# this function create all needed route tables
# each table is named rt_ethX
# you need to understand that in AWS
## the gateway is always the minimum host (HostMin)
## an interface is in a subnet, so there's only one ip range per interface
function create_route_tables() {
	ROUTE_INDEX=$RT_TABLE_OFFSET

	cat /etc/iproute2/rt_tables.orig.$TS | sed  '/^\#.*$/d;' | grep -e local -e main -e default -e unspec > /etc/iproute2/rt_tables

	for PHY in $(ifconfig | sed -n 's/^\(eth[0-9]\).*/\1/p' | uniq); do
		IP_RANGE=$(ip route show dev $PHY | grep -v ^default | awk '{print $1}')
		GW=$(ipcalc -n -b $IP_RANGE | grep HostMin | awk '{print $2}')

		echo -e "${ROUTE_INDEX}\trt_${PHY}" >> /etc/iproute2/rt_tables

		ip route add default via $GW dev $PHY table rt_${PHY}
		ip rule add fwmark $ROUTE_INDEX table rt_${PHY}

		ROUTE_INDEX=$(($ROUTE_INDEX+1))
	done
}

# flush the firewall and ensure we accept everything in and out
# before doing any other work. this means we disable any existing
# firewall rules.
function flush_firewall_rules() {
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT

	iptables -t nat -P PREROUTING ACCEPT
	iptables -t nat -P POSTROUTING ACCEPT
	iptables -t nat -P OUTPUT ACCEPT

	iptables -F
	iptables -t nat -F

	iptables -X
	iptables -t nat -X

	iptables -t mangle -F
	iptables -t mangle -X
}

# create the firewall rules so each connection mark is saved
# and restored appropriately.
# the NAT is applied to ensure the response IP address matches
# the queried address
# the firewall doesn't do any further checks and everything else
# is up to the Security Groups settings applied to your ENI
function create_firewall_rules() {

	ROUTE_INDEX=$RT_TABLE_OFFSET

	iptables -N connrestore -t mangle
	# iptables -A connrestore -t mangle -m conntrack --ctstate ESTABLISHED,RELATED -j LOG --log-prefix 'IPT: RESTORE1: ' --log-level info
	iptables -A connrestore -t mangle -m conntrack --ctstate ESTABLISHED,RELATED -j CONNMARK --restore-mark
	# iptables -A connrestore -t mangle -m conntrack --ctstate ESTABLISHED,RELATED -j LOG --log-prefix 'IPT: RESTORE2: ' --log-level info
	# iptables -A connrestore -t mangle -m state --state ESTABLISHED,RELATED -j LOG --log-prefix 'IPT: RESTORE3: ' --log-level info
	iptables -A connrestore -t mangle -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark
	# iptables -A connrestore -t mangle -m state --state ESTABLISHED,RELATED -j LOG --log-prefix 'IPT: RESTORE4: ' --log-level info

	for PHY in $(ifconfig | sed -n 's/^\(eth[0-9]\).*/\1/p' | uniq); do
		iptables -N rt_${PHY} -t mangle
		# iptables -A rt_${PHY} -t mangle -m -j LOG --log-prefix "IPT: rt_${PHY}_1: " --log-level info
		iptables -A rt_${PHY} -t mangle -j MARK --set-mark $ROUTE_INDEX
		iptables -A rt_${PHY} -t mangle -j CONNMARK --save-mark
		# iptables -A rt_${PHY} -t mangle -j LOG --log-prefix "IPT: rt_${PHY}_2: " --log-level info

		iptables -A PREROUTING -t mangle -i $PHY -j connrestore
		iptables -A PREROUTING -t mangle -i $PHY -j rt_${PHY}

		iptables -A OUTPUT -t mangle -o $PHY -j CONNMARK --restore-mark
		iptables -A OUTPUT -o $PHY -m state --state ESTABLISHED,RELATED -j ACCEPT

		iptables -A POSTROUTING -t nat -o $PHY -j MASQUERADE
		ROUTE_INDEX=$(($ROUTE_INDEX+1))
	done
}

FLUSH_ONLY=0
while getopts "hf" opt; do
	case $opt in
		f)
			FLUSH_ONLY=1
		;;
		h)
			usage
		;;
		*)
			usage
		;;

	esac
done


if [ ! -x /sbin/ip -o ! -e /etc/iproute2/rt_tables ]; then
	echo "iproute2 is not installed"
	exit 1
fi

if [ ! -x /sbin/iptables ]; then
	echo "iptables is not installed"
	exit 1
fi

if [ ! -x /usr/bin/ipcalc ]; then
	echo "ipcalc is not installed"
	exit 1
fi

if [ "$(ifconfig | sed -n 's/^\(eth[0-9]\).*/\1/p' | uniq | wc -l)" -lt 2 ]; then
	echo "only one network interface detected. no actions needed."
	exit 1
fi

# remove any custom route tables
remove_route_tables

if [ "$FLUSH_ONLY" -eq "1" ]; then
	exit
fi

# backup first the route table
if [ ! -f /etc/iproute2/rt_tables.dist ]; then
	cp -p /etc/iproute2/rt_tables /etc/iproute2/rt_tables.dist
fi
cp -p /etc/iproute2/rt_tables /etc/iproute2/rt_tables.orig.$TS

# create new route tables
create_route_tables

# flush all firewall rules
flush_firewall_rules

# create needed firewall rules
create_firewall_rules
