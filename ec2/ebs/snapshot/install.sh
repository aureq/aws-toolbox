#!/bin/sh

DIR=$(echo $0 | sed 's,[^/]*$,,; s,/$,,;')
[ -z "$DIR" ] && DIR="."

for x in usr/bin/purge-expired-snapshots.sh usr/bin/snapshot-instance-volumes.sh
do
	cp ${DIR}/${x} /usr/bin/
	chown root:root /${x}
	chmod 0755 /${x}
done

if [ ! -f "/etc/cron.d/snapshotcron" ]
then
	cp ${DIR}/etc/cron.d/snapshotcron /etc/cron.d/
	chown root:root /etc/cron.d/snapshotcron
	chmod 0600 /etc/cron.d/snapshotcron
fi

echo "Installation has finished, you need to edit /etc/cron.d/snapshotcron"
echo "and set your desired scheduling policy"
