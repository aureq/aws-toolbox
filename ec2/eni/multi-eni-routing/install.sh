#!/bin/sh

DIR=$(echo $0 | sed 's,[^/]*$,,; s,/$,,;')
[ -z "$DIR" ] && DIR="."

for x in usr/bin/multi-eni-routing.sh
do
	cp ${DIR}/${x} /usr/bin/
	chown root:root /${x}
	chmod 0755 /${x}
done

if [ -x /usr/bin/lsb_release ]; then
	DIST=$(lsb_release -i -s)
else
	[ -f /etc/centos-release ] && DIST=Centos
	[ -f /etc/redhat-release ] && DIST=Redhat
	[ -f /etc/system-release ] && DIST=Amazon
fi

case $DIST in
	Debian|Ubuntu)
		cp ${DIR}/etc/init.d/multi-eni-routing.Debian /etc/init.d/multi-eni-routing
		update-rc.d multi-eni-routing defaults
	;;
	Amazon|Centos|Redhat)
		cp ${DIR}/etc/init.d/multi-eni-routing.Redhat /etc/init.d/multi-eni-routing
		chkconfig --add multi-eni-routing
	;;
esac

echo "Installation finished."
