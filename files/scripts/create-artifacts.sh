#!/bin/bash

CHANNEL_NAME="$1"
: ${CHANNEL_NAME:="mychannel"}

CONFIG_PATH="$2"
: ${CONFIG_PATH:="/files/config"}

if [ ! -d "/hlfbins" ]; then
	mkdir -p /hlfbins
    cp -rf /files/bin/* /hlfbins/.
    chmod -R 755 /hlfbins
fi

if [ ! -d "/artifacts/channel-artifacts" ]; then
	mkdir -p /artifacts/channel-artifacts
fi

if [ ! -d "/artifacts/system-genesis-block" ]; then
	mkdir -p /artifacts/system-genesis-block
fi

createOrdererGenesisBlock() {

    echo "#########  Generating Orderer Genesis block ##############"

    set -x
    /hlfbins/configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock /artifacts/system-genesis-block/genesis.block -configPath $CONFIG_PATH
    res=$?
    set +x
    if [ $res -ne 0 ]; then
        echo "Failed to generate orderer genesis block..."
        exit 1
    fi
}

createChannelTx() {

	set -x
	/hlfbins/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx /artifacts/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME -configPath $CONFIG_PATH
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate channel configuration transaction..."
		exit 1
	fi
	echo

}

createAncorPeerTx() {

	for orgmsp in GeneralMSP AirbusMSP; do

	echo "#######    Generating anchor peer update for ${orgmsp}  ##########"
	set -x
	/hlfbins/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate /artifacts/channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg ${orgmsp} -configPath $CONFIG_PATH
	res=$?
	set +x
	if [ $res -ne 0 ]; then
		echo "Failed to generate anchor peer update for ${orgmsp}..."
		exit 1
	fi
	echo
	done
}


## Create genesis.block
echo "### Generating system-channel genesis block ###"
createOrdererGenesisBlock

## Create channeltx
echo "### Generating channel configuration transaction '${CHANNEL_NAME}.tx' ###"
createChannelTx

## Create anchorpeertx
echo "### Generating channel anchor peer transaction ###"
createAncorPeerTx