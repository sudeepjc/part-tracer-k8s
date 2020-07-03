#!/bin/bash

# export SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# fabric-ca-client enroll -u https://$ROOT_USERNAME:$ROOT_PASSWORD@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

# bash $SCRIPTDIR/crypto.sh orderer:default.svc.cluster.local:default.svc.cluster.local:3

bash /files/scripts/crypto.sh orderer:regulator:default.svc.cluster.local:3
# bash $SCRIPTDIR/crypto.sh peer:airbus:default.svc.cluster.local:1