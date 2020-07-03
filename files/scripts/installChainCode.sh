CHANNEL_NAME="$1"
# CC_SRC_LANGUAGE="$2"
VERSION="$3"
DELAY="$4"
MAX_RETRY="$5"
# VERBOSE="$6"
: ${CHANNEL_NAME:="mychannel"}
# : ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
# : ${VERBOSE:="false"}
# CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

# if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
# 	CC_RUNTIME_LANGUAGE=golang
# 	CC_SRC_PATH="/files/chaincode/partTracer_$VERSION"

# 	echo Vendoring Go dependencies ...
# 	pushd $CC_SRC_PATH
# 	GO111MODULE=on go mod vendor
# 	popd
# 	echo Finished vendoring Go dependencies

# else
# 	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
# 	echo Supported chaincode languages are: go, java, javascript, and typescript
# 	exit 1
# fi

ORDERER_CA=$ORDERER_CA_PATH/tlscacerts/tlsca.parttracer.com-cert.pem

# installChaincode PEER ORG
installChaincode() {
  set -x
  peer lifecycle chaincode install $ARTIFACTS_MOUNT_POINT/partTracer.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode installation on peer0 ORG has failed"
  echo "===================== Chaincode is installed on peer0. ORG ===================== "
  echo
}

# queryInstalled PEER ORG
queryInstalled() {
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  
	PACKAGE_ID=$(sed -n "/partTracer_${VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0 ORG has failed"
  echo PackageID is ${PACKAGE_ID}
  echo "===================== Query installed successful on peer0 ORG on channel ===================== "
  echo
}

# approveForMyOrg VERSION PEER ORG
approveForMyOrg() {

  set -x
  peer lifecycle chaincode approveformyorg -o $ORDERER_SERVER:7050 --ordererTLSHostnameOverride $ORDERER_SERVER --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name partTracer --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} >&log.txt
  set +x
  cat log.txt
  
  verifyResult $res "Chaincode definition approved on peer0 ORG on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer0 ORG on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  echo "===================== Checking the commit readiness of the chaincode definition on peer0 ORG on channel '$CHANNEL_NAME'... ===================== "
	local rc=1
	local COUNTER=1
	# continue to poll
  # we either get a successful response, or reach MAX RETRY
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer0 ORG secs"
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name partTracer --version ${VERSION} --sequence ${VERSION} --output json --init-required >&log.txt
    res=$?
    set +x
    let rc=0
    for var in "$@"
    do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
		COUNTER=$(expr $COUNTER + 1)
	done
  cat log.txt

  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer0 ORG on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! After $MAX_RETRY attempts, Check commit readiness result on peer0 ORG is INVALID !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

## Install chaincode on peer0.general and peer0.airbus
# echo "Installing chaincode on peer0.general..."
installChaincode

## query whether the chaincode is installed
queryInstalled

## approve the definition for general
approveForMyOrg

## check whether the chaincode definition is ready to be committed
## expect general to have approved and airbus not to
checkCommitReadiness "\"${CORE_PEER_LOCALMSPID}\": true"

