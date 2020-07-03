#!/bin/bash +x

CC_SRC_LANGUAGE="$2"
VERSION="$3"

: ${CC_SRC_LANGUAGE:="golang"}
: ${VERSION:="1"}

CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`

if [ "$CC_SRC_LANGUAGE" = "go" -o "$CC_SRC_LANGUAGE" = "golang" ] ; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="/files/chaincode/partTracer_$VERSION"

	echo Vendoring Go dependencies ...
	pushd $CC_SRC_PATH
	GO111MODULE=on go mod vendor
	popd
	echo Finished vendoring Go dependencies

else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: go, java, javascript, and typescript
	exit 1
fi

packageChaincode() {
  set -x
  peer lifecycle chaincode package partTracer.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label partTracer_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode packaging on peer0 General has failed"
  echo "===================== Chaincode is packaged on peer0 General ===================== "
  echo
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo
    exit 1
  fi
}

## at first we package the chaincode
packageChaincode

cp partTracer.tar.gz $ARTIFACTS_MOUNT_POINT/.


