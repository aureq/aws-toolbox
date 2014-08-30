#!/bin/bash

TODAY="$(date +%s)"

# as installed manually
AWS='/usr/local/bin/aws'
# as installed via a package manager
AWS2='/usr/bin/aws'

JQ='/usr/bin/jq'

if [ ! -x "$JQ" ]
then
	echo "$JQ is not installed. (apt-get|yum) install jq"
	exit 1
fi

if [ ! -x "$AWS" ]
then
	if [ ! -x "$AWS2" ]
	then
		echo "AWS cli is not installed. visit: http://aws.amazon.com/cli/"
		exit 1
	else
		AWS="$AWS2"
	fi
fi

LOCAL_REGION=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone -q -O - | sed 's/.$//')

for REGION in $($AWS --output json --region $LOCAL_REGION ec2 describe-regions | jq '.Regions[].RegionName' | sed 's/"//g')
do
	for SNAPSHOTID in $($AWS --output json --region $REGION ec2 describe-snapshots --filters "Name=tag-key,Values=Expire" | jq '.Snapshots[].SnapshotId' | sed 's/"//g')
	do
		EXPIRE=$($AWS --output json --region $REGION ec2 describe-snapshots --filters "Name=snapshot-id,Values=$SNAPSHOTID" | jq '.Snapshots[].Tags[]' | grep -A1 -B2 'Expire' | jq '.Value' | sed 's/"//g')
		EXPIRE=$(date --date="$EXPIRE" +%s)

		if [ "$EXPIRE" -le "$TODAY" ]
		then
			RETURN=$($AWS --output json --region $REGION ec2 delete-snapshot --snapshot-id "$SNAPSHOTID" | jq '.return' | sed 's/"//g')
			if [ "$RETURN" != "true" ]
			then
				echo "Cannot delete snapshot $SNAPSHOTID"
			fi
		fi
	done
done
