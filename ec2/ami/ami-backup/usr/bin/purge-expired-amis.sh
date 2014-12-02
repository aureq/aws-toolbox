#!/bin/bash

TODAY="$(date +%s)"

# as installed manually
AWS='/usr/local/bin/aws'
# as installed via a package manager
AWS2='/usr/bin/aws'

JQ='/usr/bin/jq'

function usage() {
	echo -e "$0 [-p profile_name] [-r region]"
	echo -e "\t-p profile_name: the aws profile name, default is 'default'. if specified, this should be specified first."
	echo -e "\t-r region-1,region-2: the region/regions you only wish to check and clean."
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

while getopts "hp:r:" opt
do
	case $opt in
		h)
			usage
		;;
		p)
			PROFILE="--profile $OPTARG"
		;;
		r)
			REGIONS="$OPTARG"
		;;
		*)
			echo "this option '-$OPTARG' is not supported"
			usage
		;;
	esac
done

if [ ! -z "$REGIONS" ]
then
	LOCAL_REGION=$(echo $REGIONS | awk -F ',' '{print $1}')
else
	# trying to guess the local region if possible
	LOCAL_REGION=$(wget http://169.254.169.254/latest/meta-data/placement/availability-zone -q -O - | sed 's/.$//')
	if [ -z "$LOCAL_REGION" ]
	then
		echo "cannot determine the local region, please use '-r region' with this script."
		exit 1
	fi
fi

if [ -z "$REGIONS" ]
then
	REGIONS=$($AWS $PROFILE --output json --region $LOCAL_REGION ec2 describe-regions | $JQ '.Regions[].RegionName' | sed 's/"//g')
else
	REGIONS=$(echo $REGIONS | sed 's/,/ /g')
fi

for REGION in $REGIONS
do

	for IMAGEID in $($AWS $PROFILE --region $REGION --output json ec2 describe-images --filters "Name=tag:Creator,Values=image-instance" --filters "Name=tag:Expire,Values=*" | $JQ '.Images[].ImageId' | sed 's/"//g' )
	do
		EXPIRE=$($AWS $PROFILE --region $REGION --output json ec2 describe-images --image-ids "$IMAGEID" | $JQ '.Images[].Tags[]' | grep -A1 -B2 'Expire' | $JQ '.Value' | sed 's/"//g')
		if [ -z "$EXPIRE" ]
		then
			# some ami may not have expiry date. skipping them silently
			continue
		fi
		EXPIRE=$(date --date="$EXPIRE" +%s)

		if [ "$EXPIRE" -le "$TODAY" ]
		then
			SNAPSHOTS=$($AWS $PROFILE --region $REGION --output json ec2 describe-images --image-ids "$IMAGEID" | jq '.Images[].BlockDeviceMappings[].Ebs.SnapshotId' 2>/dev/null | grep -v null | sed 's/"//g')
			RETURN=$($AWS $PROFILE --region $REGION --output json ec2 deregister-image --image-id "$IMAGEID" | $JQ '.return' | sed 's/"//g')
			if [ "$RETURN" != "true" ]
			then
				echo "cannot deregister ami ${IMAGEID}."
				continue
			fi
			for SNAPSHOTID in $SNAPSHOTS
			do
				EXPIRE=$($AWS $PROFILE --output json --region $REGION ec2 describe-snapshots --filters "Name=snapshot-id,Values=$SNAPSHOTID" | $JQ '.Snapshots[].Tags[]' | grep -A1 -B2 'Expire' | $JQ '.Value' | sed 's/"//g')
				if [ -z "$EXPIRE" ]
				then
					echo "failed to get snapshot expiry date for ${IMAGEID}."
					continue
				fi
				EXPIRE=$(date --date="$EXPIRE" +%s)
				if [ "$EXPIRE" -le "$TODAY" ]
				then
					RETURN=$($AWS $PROFILE --output json --region $REGION ec2 delete-snapshot --snapshot-id "$SNAPSHOTID" | $JQ '.return' | sed 's/"//g')
					if [ "$RETURN" != "true" ]
					then
						echo "cannot delete snapshot $SNAPSHOTID"
					fi
				fi
			done
		fi
	done

	# remove orphan snapshots

	# list of snapshots associated to AMIs
	ASSOCIATEDSNAPSHOTSID=$($AWS  $PROFILE --output json --region $REGION ec2 describe-images --filters "Name=tag:Creator,Values=image-instance" --filters "Name=tag:Expire,Values=*" | $JQ '.Images[].BlockDeviceMappings[].Ebs.SnapshotId' | grep -v null | sed 's/"//g')

	# all snapshots, including orphans
	for SNAPSHOTID in $($AWS  $PROFILE --output json --region $REGION ec2 describe-snapshots --filter "Name=tag:Creator,Values=image-instance" --filters "Name=tag:Expire,Values=*" | $JQ '.Snapshots[].SnapshotId' | sed 's/"//g')
	do
		if [[ "$ASSOCIATEDSNAPSHOTSID" =~ "$SNAPSHOTID" ]]
		then
			# this snapshot was found in the list of associated snapshots.
			# trying to delete this snapshot will fail, so we skip it.
			continue;
		fi

		EXPIRE=$($AWS $PROFILE --output json --region $REGION ec2 describe-snapshots --filters "Name=snapshot-id,Values=$SNAPSHOTID" | $JQ '.Snapshots[].Tags[]' | grep -A1 -B2 'Expire' | $JQ '.Value' | sed 's/"//g')
		if [ -z "$EXPIRE" ]
		then
			echo "failed to get snapshot expiry date for ${SNAPSHOTID}."
			continue
		fi
		EXPIRE=$(date --date="$EXPIRE" +%s)
		if [ "$EXPIRE" -le "$TODAY" ]
		then
			RETURN=$($AWS $PROFILE --output json --region $REGION ec2 delete-snapshot --snapshot-id "$SNAPSHOTID" | $JQ '.return' | sed 's/"//g')
			if [ "$RETURN" != "true" ]
			then
				echo "cannot delete snapshot $SNAPSHOTID"
			fi
		fi
	done
done
