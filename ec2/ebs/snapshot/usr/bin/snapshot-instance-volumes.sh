#!/bin/bash

INSTANCE_ID=$(wget http://169.254.169.254/latest/meta-data/instance-id -q -O -)
AZ=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone -q -O -)
REGION=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone -q -O - | sed 's/.$//')

AWS='/usr/local/bin/aws'

JQ='/usr/bin/jq'

if [ ! -x "$JQ" ]
then
	echo "$JQ is not installed. (apt-get|yum) install jq"
	exit 1
fi

if [ ! -x "$AWS" ]
then
	echo "AWS cli is not installed. visit: http://aws.amazon.com/cli/"
	exit 1
fi

if [ -z "$INSTANCE_ID" ]
then
	echo "cannot retrieve instance-id"
	exit 1
fi

if [ ! -z "$1" ]
then
	EXPIRE=$(date --date="$1" 2>/dev/null)
fi


for VOLUME_PAIR in $($AWS --region $REGION ec2 describe-instances --filters Name=instance-id,Values=${INSTANCE_ID} --output=text | grep -A1 BLOCKDEVICEMAPPINGS  | sed 'N;s/\n/ /' | awk '{printf("%s:%s\n",$2,$7);}')
do
	DEVICE=$(echo $VOLUME_PAIR | awk -F ':' '{print $1}')
	VOLUME=$(echo $VOLUME_PAIR | awk -F ':' '{print $2}')
	DATE=$(date)

	SNAPSHOT=$($AWS --output json --region $REGION ec2 create-snapshot --volume-id "$VOLUME" --description "backup of $DEVICE on $DATE" | grep SnapshotId | sed -e 's/[\"\:\,]//g' | awk '{print $2}')

	if [ -z "$SNAPSHOT" ]
	then
		echo "failed to get snapshot-id for $VOLUME attached to $INSTANCE_ID"
		continue
	fi

	$AWS --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
		"Key=Name,Value=backup@$INSTANCE_ID" \
		"Key=Device,Value=$DEVICE" \
		"Key=Volume,Value=$VOLUME" \
		"Key=Instance,Value=$INSTANCE_ID" \
		"Key=Date,Value=$DATE" \
		"Key=AvailabilityZone,Value=$AZ" >/dev/null

	if [ ! -z "$EXPIRE" ]
	then
		$AWS --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
			"Key=Expire,Value=$EXPIRE" >/dev/null
	fi
done
