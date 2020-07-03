CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

ORDERER_CA=$ORDERER_CA_PATH/tlscacerts/tlsca.parttracer.com-cert.pem

# createChannel() {
# 	# Poll in case the raft leader is not set yet
# 	local rc=1
# 	local COUNTER=1
# 	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
# 		sleep $DELAY
# 		set -x
# 		peer channel create -o $ORDERER_SERVER:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride $ORDERER_SERVER -f $ARTIFACTS_MOUNT_POINT/${CHANNEL_NAME}.tx --outputBlock $ARTIFACTS_MOUNT_POINT/${CHANNEL_NAME}.block --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
# 		res=$?
# 		set +x
# 		let rc=$res
# 		COUNTER=$(expr $COUNTER + 1)
# 	done
# 	cat log.txt
# 	verifyResult $res "Channel creation failed"
# 	echo
# 	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
# 	echo
# }

joinChannel() {
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $ARTIFACTS_MOUNT_POINT/$CHANNEL_NAME.block >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	echo
	verifyResult $res "After $MAX_RETRY attempts, Airbus Org has failed to join channel '$CHANNEL_NAME' "
}

updateAnchorPeers() {
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
		peer channel update -o $ORDERER_SERVER:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride $ORDERER_SERVER -f $ARTIFACTS_MOUNT_POINT/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Anchor peer update failed"
	echo "===================== Anchor peers updated for org 'Airbus' on channel '$CHANNEL_NAME' ===================== "
	sleep $DELAY
	echo
}

verifyResult() {
	if [ $1 -ne 0 ]; then
    	echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    	echo
    	exit 1
	fi
}

# ## Create channel
# echo "Creating channel "$CHANNEL_NAME
# createChannel

## Join all the peers to the channel
echo "Join Airbus Org peers to the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for Airbus Org..."
updateAnchorPeers

echo
echo "========= 'Airbus' Org successfully joined ${CHANNEL_NAME} =========== "
echo
