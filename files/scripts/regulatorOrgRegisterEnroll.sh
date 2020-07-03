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
	echo "Register orderer0"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name orderer0 --id.secret orderer0pw --id.type orderer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
	echo "Register orderer1"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name orderer1 --id.secret orderer1pw --id.type orderer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
	echo "Register orderer2"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name orderer2 --id.secret orderer2pw --id.type orderer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
  echo "Register the regulator admin"
  echo
  set -x
  fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name Admin --id.secret Adminpw --id.type admin --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

	mkdir -p $FABRIC_CA_CLIENT_HOME/orderers

  # Orderer 0 changes start here
  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer0:orderer0pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/msp --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer0:orderer0pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls --enrollment.profile tls --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  mkdir $FABRIC_CA_CLIENT_HOME/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer0.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # Orderer 0 changes end here

    # Orderer 1 changes start here
  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer1:orderer1pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/msp --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer1:orderer1pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls --enrollment.profile tls --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # mkdir $FABRIC_CA_CLIENT_HOME/msp/tlscacerts
  # cp $FABRIC_CA_CLIENT_HOME/orderers/orderer1.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # Orderer 1 changes end here

    # Orderer 2 changes start here
  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer2:orderer2pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/msp --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer2:orderer2pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls --enrollment.profile tls --csr.hosts "orderer0-regulator-service,orderer1-regulator-service,orderer2-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # mkdir $FABRIC_CA_CLIENT_HOME/msp/tlscacerts
  # cp $FABRIC_CA_CLIENT_HOME/orderers/orderer2.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # Orderer 2 changes end here

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