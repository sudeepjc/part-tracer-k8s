  echo
	echo "Enroll the CA admin"
  echo

  set -x
  fabric-ca-client enroll -u https://$ROOT_USERNAME:$ROOT_PASSWORD@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/airbus-ca-root-7054-airbus-ca-root.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/airbus-ca-root-7054-airbus-ca-root.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/airbus-ca-root-7054-airbus-ca-root.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/airbus-ca-root-7054-airbus-ca-root.pem
    OrganizationalUnitIdentifier: orderer' > $FABRIC_CA_CLIENT_HOME/msp/config.yaml

  echo
	echo "Register peer0"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
  echo "Register user"
  echo
  set -x
  fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name User1 --id.secret User1pw --id.type client --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
  echo "Register the org admin"
  echo
  set -x
  fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name Admin --id.secret Adminpw --id.type admin --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  echo
  echo "Create a new affiliations"
  echo
  set -x
  fabric-ca-client affiliation add airbus --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  fabric-ca-client affiliation add airbus.sales --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  mkdir -p $FABRIC_CA_CLIENT_HOME/peers
  mkdir -p $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com

  echo
  echo "## Generate the peer0 msp"
  echo
  set -x
	fabric-ca-client enroll -u https://peer0:peer0pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/msp --csr.hosts "peer0-airbus-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the peer0-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls --enrollment.profile tls --csr.hosts "peer0-airbus-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x


  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/msp/tlscacerts/ca.crt

  mkdir $FABRIC_CA_CLIENT_HOME/tlsca
  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/tlsca/tlsca.airbus.parttracer.com-cert.pem

  mkdir $FABRIC_CA_CLIENT_HOME/ca
  cp $FABRIC_CA_CLIENT_HOME/peers/peer0.airbus.parttracer.com/msp/cacerts/* $FABRIC_CA_CLIENT_HOME/ca/ca.airbus.parttracer.com-cert.pem

  mkdir -p $FABRIC_CA_CLIENT_HOME/users
  mkdir -p $FABRIC_CA_CLIENT_HOME/users/User1@airbus.parttracer.com

  echo
  echo "## Generate the user msp"
  echo
  set -x
	fabric-ca-client enroll -u https://User1:User1pw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/users/User1@airbus.parttracer.com/msp --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  mkdir -p $FABRIC_CA_CLIENT_HOME/users/Admin@airbus.parttracer.com

  echo
  echo "## Generate the org admin msp"
  echo
  set -x
	fabric-ca-client enroll -u https://Admin:Adminpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/users/Admin@airbus.parttracer.com/msp --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/users/Admin@airbus.parttracer.com/msp/config.yaml

  # Orderer config starts here

  echo
	echo "Register orderer"
  echo
  set -x
	fabric-ca-client register --caname $FABRIC_CA_SERVER_CA_NAME --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers
  mkdir -p $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com

  echo
  echo "## Generate the orderer msp"
  echo
  set -x
	fabric-ca-client enroll -u https://orderer:ordererpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/msp --csr.hosts "orderer-airbus-service,orderer-general-service,orderer-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/msp/config.yaml $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/msp/config.yaml

  echo
  echo "## Generate the orderer-tls certificates"
  echo
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@$FABRIC_CA_SERVER_NAME:$FABRIC_CA_SERVER_PORT --caname $FABRIC_CA_SERVER_CA_NAME -M $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls --enrollment.profile tls --csr.hosts "orderer-airbus-service,orderer-general-service,orderer-regulator-service" --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
  set +x

  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/ca.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/signcerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/server.crt
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/keystore/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/server.key

  mkdir $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/msp/tlscacerts
  cp $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/tlscacerts/* $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/msp/tlscacerts/tlsca.parttracer.com-cert.pem

  # Orderer config ends here

  cp -rf $FABRIC_CA_CLIENT_HOME/msp /orgCertificates/airbus/.

  mkdir -p /orgCertificates/airbus/orderers/orderer.airbus.parttracer.com/tls
  cp -rf $FABRIC_CA_CLIENT_HOME/orderers/orderer.airbus.parttracer.com/tls/server.crt /orgCertificates/airbus/orderers/orderer.airbus.parttracer.com/tls/server.crt