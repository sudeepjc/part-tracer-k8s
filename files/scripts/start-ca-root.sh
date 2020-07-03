#!/bin/bash

fabric-ca-server start -b $ROOT_USERNAME:$ROOT_PASSWORD --cfg.affiliations.allowremove --cfg.identities.allowremove --csr.hosts $FABRIC_CA_SERVER_CA_NAME --ca.name $FABRIC_CA_SERVER_CA_NAME --csr.cn $FABRIC_CA_SERVER_CA_NAME