#!/bin/sh

DIR=$(echo $0 | sed 's,[^/]*$,,; s,/$,,;')
[ -z "$DIR" ] && DIR="."

for x in usr/bin/multi-eni-routing.sh
do
	cp ${DIR}/${x} /usr/bin/
	chown root:root /${x}
	chmod 0755 /${x}
done

DIST=$(lsb_release -i -s)
case $DIST in
	Debian | Ubuntu)
		cp ${DIR}/etc/init.d/multi-eni-routing.Debian /etc/init.d/multi-eni-routing
		update-rc.d multi-eni-routing defaults
	;;
esac

echo "Installation finished."
