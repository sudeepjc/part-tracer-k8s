#!/bin/bash
  echo
	echo "Enroll the CA admin"
  echo

  set -x
  fabric-ca-client enroll -u https://$ROOT_USERNAME:$ROOT_PASSWORD@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/regulator-ca-root-7054-regulator-ca-root.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/regulator-ca-root-7054-regulator-ca-root.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/regulator-ca-root-7054-regulator-ca-root.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/regulator-ca-root-7054-regulator-ca-root.pem
    OrganizationalUnitIdentifier: orderer' > $FABRIC_CA_CLIENT_HOME/msp/config.yaml

  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
  echo "Register the regulator admin"
  echo
  set -x
  fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name Admin --id.secret Adminpw --id.type admin --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

	mkdir -p $FABRIC_CA_CLIENT_HOME/orderers
  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/msp --csr.hosts "orderer-airbus-service,orderer-general-service,orderer-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls --enrollment.profile tls --csr.hosts "orderer-airbus-service,orderer-general-service,orderer-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  mkdir $FABRIC_CA_CLIENT_HOME/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  mkdir -p $FABRIC_CA_CLIENT_HOME/users
  mkdir -p $FABRIC_CA_CLIENT_HOME/users/Admin@parttracer.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://Admin:Adminpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/users/Admin@regulator.parttracer.com/msp --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Admin@regulator.parttracer.com/msp/config.yaml

  mkdir -p /orgCertificates/regulator
  cp -rf $FABRIC_CA_CLIENT_HOME/msp /orgCertificates/regulator/.