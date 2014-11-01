#!/bin/sh

DIR=$(echo $0 | sed 's,[^/]*$,,; s,/$,,;')
[ -z "$DIR" ] && DIR="."

for x in usr/bin/purge-expired-amis.sh usr/bin/image-instance.sh
do
	cp ${DIR}/${x} /usr/bin/
	chown root:root /${x}
	chmod 0755 /${x}
done

if [ ! -e "/etc/cron.d/amicron" ]
then
	cp ${DIR}/etc/cron.d/amicron /etc/cron.d/
	chown root:root /etc/cron.d/amicron
	chmod 0600 /etc/cron.d/amicron
fi

echo "Installation has finished, you need to edit /etc/cron.d/amicron"
echo "and set your desired scheduling policy"
