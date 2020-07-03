CHANNEL_NAME="$1"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}

ORDERER_CA=$ORDERER_CA_PATH/tlscacerts/tlsca.parttracer.com-cert.pem
AIRBUS_PEER_CA=/orgCertificates/airbus/msp/tlscacerts/ca.crt
GENERAL_PEER_CA=/orgCertificates/general/msp/tlscacerts/ca.crt

AIRBUS_PEER_PARAM="--peerAddresses peer0-airbus-service:7051 --tlsRootCertFiles $AIRBUS_PEER_CA"
GENERAL_PEER_PARAM="--peerAddresses peer0-general-service:7051 --tlsRootCertFiles $GENERAL_PEER_CA"

# echo $AIRBUS_PEER_PARAM

# echo $GENERAL_PEER_PARAM

PEER_CONN_PARMS="$AIRBUS_PEER_PARAM $GENERAL_PEER_PARAM"

# echo $PEER_CONN_PARMS

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o $ORDERER_SERVER:7050 --ordererTLSHostnameOverride $ORDERER_SERVER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name partTracer $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0 ORG on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# queryCommitted ORG
queryCommitted() {

  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer0 ORG on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query committed status on peer0 ORG, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name partTracer >&log.txt
    res=$?
    set +x
		test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer0 ORG on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query chaincode definition result on peer0 ORG is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

chaincodeInvokeInit() {

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o $ORDERER_SERVER:7050 --ordererTLSHostnameOverride $ORDERER_SERVER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS --isInit -c '{"function":"initLedger","Args":[]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on peer0 failed "
  echo "===================== Invoke transaction successful on peer0 on channel '$CHANNEL_NAME' ===================== "
  echo
}

invokeAddPart(){

  echo "===================== Invoking on peer0 ORG on channel '$CHANNEL_NAME'... ===================== "


  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o $ORDERER_SERVER:7050 --ordererTLSHostnameOverride $ORDERER_SERVER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS -c '{"function":"addPart","Args":["engine_1","engine", "Two seater plane engine","100000","General Org"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on peer0 failed "
  echo "===================== Invoke transaction successful on peer0 on channel '$CHANNEL_NAME' ===================== "
  echo

}

chaincodeQuery() {
  
  echo "===================== Querying on peer0 ORG on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to Query peer0 ORG ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n partTracer -c '{"Args":["queryPart","engine_1"]}' >&log.txt
    res=$?
    set +x
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer0 ORG on channel '$CHANNEL_NAME' ===================== "
		echo
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Query result on peer0 ORG is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

invokeSellPart(){

  echo "===================== Invoking on peer0 ORG on channel '$CHANNEL_NAME'... ===================== "


  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer chaincode invoke -o $ORDERER_SERVER:7050 --ordererTLSHostnameOverride $ORDERER_SERVER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n partTracer $PEER_CONN_PARMS -c '{"function":"sellPart","Args":["engine_1","AirbusMSP","9999"]}' >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Invoke execution on peer0 failed "
  echo "===================== Invoke transaction successful on peer0 on channel '$CHANNEL_NAME' ===================== "
  echo

}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

## now that we know for sure both orgs have approved, commit the definition
commitChaincodeDefinition

## query on both orgs to see that the definition committed successfully
queryCommitted

sleep 5

## Invoke the chaincode
chaincodeInvokeInit

# sleep 10
