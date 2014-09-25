#!/bin/bash

# as installed manually
AWS='/usr/local/bin/aws'
# as installed via a package manager
AWS2='/usr/bin/aws'

JQ='/usr/bin/jq'

function usage() {
	echo -e "$0 [-p profile_name] [-i instance_id] [-r region] [-e expiry_date]"
	echo -e "\t-p profile_name: the aws profile name, default is 'default'. if specified, this should be specified first."
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

while getopts "he:i:p:" opt
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
			echo "this option '-$OPTARG' is not supported"
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


DATE=$(date)
UNIX_TS=$(date +%s)

INSTANCE_NAME=$($AWS $PROFILE --region $REGION --output json ec2 describe-instances --instance-ids "${INSTANCE_ID}" | $JQ '.Reservations[].Instances[].Tags[]' | grep -A1 -B2 'Name' | $JQ '.Value' | sed 's/"//g')
if [ -z "$INSTANCE_NAME" ]
then
	INSTANCE_NAME="$INSTANCE_ID"
fi

AMI_NAME="$(echo "backup-ami@$INSTANCE_NAME-$UNIX_TS" | sed 's/[^A-Za-z0-9()\.\/_\-]//g')"

IMAGE_ID=$($AWS $PROFILE --region $REGION --output json ec2 create-image --instance-id "$INSTANCE_ID" --no-reboot --name "$AMI_NAME" --description "backup-ami for $INSTANCE_NAME" | $JQ '.ImageId' | sed 's/"//g')
if [ -z "$IMAGE_ID" ]
then
	echo "failed to get the ami-id for $INSTANCE_ID"
	exit 1
fi

$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$IMAGE_ID" --tags \
	"Key=Name,Value=backup-ami@$INSTANCE_NAME" \
	"Key=Instance,Value=$INSTANCE_ID" \
	"Key=Date,Value=$DATE" \
	"Key=Creator,Value=image-instance" \
	"Key=AvailabilityZone,Value=$AZ" >/dev/null

if [ ! -z "$EXPIRE" ]
then
	$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$IMAGE_ID" --tags \
		"Key=Expire,Value=$EXPIRE" >/dev/null
fi

# we need to wait up until all snapshots have been created and for a maximum of 60 seconds
# this is need so we can move to the next phase

SLEEP=2
SNAPSHOT_COUNT=0

VOLUME_COUNT=$($AWS $PROFILE --region $REGION --output json ec2 describe-instances --instance-ids "${INSTANCE_ID}" | $JQ '.Reservations[].Instances[].BlockDeviceMappings[].Ebs.VolumeId' | wc -l)
while true
do
	SNAPSHOT_COUNT=$($AWS $PROFILE --region $REGION --output json ec2 describe-images --image-ids "$IMAGE_ID" | $JQ '.Images[].BlockDeviceMappings[].Ebs.SnapshotId' | grep -v null | wc -l )
	if [ "$SNAPSHOT_COUNT" -eq "$VOLUME_COUNT" ]
	then
		break
	fi
	sleep $SLEEP
	SLEEP=$(($SLEEP+$SLEEP))
	if [ "$SLEEP" -gt "120" ]
	then
		break
	fi
done

if [ "$SNAPSHOT_COUNT" -ne "$VOLUME_COUNT" ]
then
	echo "failed to get all snapshot ids for ami $IMAGE_ID"
	exit 1
fi

# Please note that it's important to tag also the associated snapshots
# because when an image is deregistered, the associated snapshots are *not* deleted.
for SNAPSHOT in $($AWS $PROFILE --output json --region $REGION ec2 describe-images --image-ids "$IMAGE_ID" | $JQ '.Images[].BlockDeviceMappings[]' | grep 'SnapshotId' | awk '{print $2}' | sed 's/[",]//g')
do
	$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
		"Key=Name,Value=backup-ami@$INSTANCE_NAME" \
		"Key=Instance,Value=$INSTANCE_ID" \
		"Key=Date,Value=$DATE" \
		"Key=Creator,Value=image-instance" \
		"Key=AvailabilityZone,Value=$AZ" >/dev/null

	if [ ! -z "$EXPIRE" ]
	then
		$AWS $PROFILE --output json --region $REGION ec2 create-tags --resources "$SNAPSHOT" --tags \
			"Key=Expire,Value=$EXPIRE" >/dev/null
	fi
done
