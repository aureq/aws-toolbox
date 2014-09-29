#!/bin/bash

# as installed manually
AWS='/usr/local/bin/aws'
# as installed via a package manager
AWS2='/usr/bin/aws'

JQ='/usr/bin/jq'

function usage() {
	echo -e "$0 [-p profile_name] [-i instance_id] [-r region] [-e expiry_date]"
	echo -e "\t-p profile_name: the aws profile name, default is 'default'. if specified, this should be the first parameter."
	echo -e "\t-i instance_id: the instance-id to create an image for, default is the local instance-id."
	echo -e "\t-r region: the EC2 region your instance is in. If unspecified, the metadata server will be queried."
	echo -e "\t-e expiry_date: when the ami should be deleted. relative time can be provided like '+1 week'. default: never"
	exit 1
}

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

while getopts "he:i:p:r:" opt
do
	case $opt in
		e)
			EXPIRE=$(date --date="$OPTARG" 2>/dev/null)
		;;
		h)
			usage
		;;
		i)
			INSTANCE_ID="$OPTARG"
		;;
		p)
			PROFILE="--profile $OPTARG"
		;;
		r)
			REGION="$OPTARG"
		;;
		*)
			echo "this option '-$opt' is not supported"
			usage
		;;
	esac
done

# we try to guess the local instance-id as we may be running in EC2
if [ -z "$INSTANCE_ID" ]
then
	INSTANCE_ID=$(wget http://169.254.169.254/latest/meta-data/instance-id -q -O -)
	if [ -z "$INSTANCE_ID" ]
	then
		echo "cannot retrieve instance-id"
		exit 1
	fi
fi

# if the region is unspecified, we try to guess it
if [ -z "$REGION" ]
then
	AZ=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone -q -O -)
	if [ -z "$AZ" ]
	then
		echo "cannot determine the region for instance $INSTANCE_ID"
		exit 1
	fi
	REGION=$(echo $AZ | sed 's/.$//')
else
	AZ=$($AWS $PROFILE --region $REGION --output json ec2 describe-instances --instance-ids "${INSTANCE_ID}" | $JQ '.Reservations[].Instances[].Placement.AvailabilityZone' | sed 's/"//g')
	if [ -z "$AZ" ]
	then
		echo "cannot determine the availability zone for instance $INSTANCE in region $REGION"
		exit 1
	fi
fi

for VOLUME_PAIR in $($AWS $PROFILE --region $REGION ec2 describe-instances --filters Name=instance-id,Values=${INSTANCE_ID} --output=text | grep -A1 BLOCKDEVICEMAPPINGS  | sed 'N;s/\n/ /' | awk '{printf("%s:%s\n",$2,$7);}')
do
	DEVICE=$(echo $VOLUME_PAIR | awk -F ':' '{print $1}')
	VOLUME=$(echo $VOLUME_PAIR | awk -F ':' '{print $2}')
	DATE=$(date)

	SNAPSHOT=$($AWS $PROFILE --output json --region $REGION ec2 create-snapshot --volume-id "$VOLUME" --description "backup of $DEVICE on $DATE" | grep SnapshotId | sed -e 's/[\"\:\,]//g' | awk '{print $2}')

	if [ -z "$SNAPSHOT" ]
	then
		echo "failed to get snapshot-id for $VOLUME attached to $INSTANCE_ID"
		continue
	fi

	$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
		"Key=Name,Value=backup@$INSTANCE_ID" \
		"Key=Device,Value=$DEVICE" \
		"Key=Volume,Value=$VOLUME" \
		"Key=Instance,Value=$INSTANCE_ID" \
		"Key=Date,Value=$DATE" \
		"Key=AvailabilityZone,Value=$AZ" >/dev/null

	if [ ! -z "$EXPIRE" ]
	then
		$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
			"Key=Expire,Value=$EXPIRE" >/dev/null
	fi
done
