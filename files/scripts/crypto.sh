#!/bin/bash +x

export FABRIC_CFG_PATH=/files/config

FCAHOME=/src/github.com/hyperledger/fabric-ca
CLIENT=fabric-ca-client
CDIR="./crypto-config"


# Usage - <type>:<orgname>:<network>:<number>
ORG="$1:$2:$3:$4"

function main {
    echo "#### Generating crypto material using Fabric CA ####"
    
    mydir=`pwd`
    cd $mydir

    setupOrg $ORG
}

function setupOrg {
    IFSBU=$IFS
    IFS=: args=($1)

    type=${args[0]}
    orgName=${args[1]}
    network=${args[2]}
    numNodes=${args[3]}

    rootCAScheme=https
    roothost=$FABRIC_CA_SERVER_NAME
    rootport=$FABRIC_CA_SERVER_PORT
    rootCAURL=${roothost}:${rootport}
    rootCAUser=$ROOT_USERNAME
    rootCAPass=$ROOT_PASSWORD
    # http://admin:adminpw@ca-root:7054
    rootCAFullURL=${rootCAScheme}://$rootCAUser:$rootCAPass@$rootCAURL

    IFS=$IFSBU

    if [ "$type" == "orderer" ]; then
        # orgDir=${CDIR}/${type}Organizations/${network}
        orgDir=${CDIR}/${type}Organizations/${orgName}
    fi
    if [ "$type" == "peer" ]; then
        orgDir=${CDIR}/${type}Organizations/${orgName}
    fi

    # enrolling the org root admin
    usersDir=$orgDir/users
    adminHome=$usersDir/rootAdmin
    enroll $adminHome $rootCAFullURL $orgName

    if [ "$orgName" == "general" ]; then
        addGeneralAffiliations
        registerGeneralNewUsers

    elif [ "$orgName" == "airbus" ]; then
        addAirbusAffiliations
        registerAirbusNewUsers
    else
        addRegulatorAffiliations
    fi

    # Register and enroll admin with root ca
    adminUserHome=$usersDir/Admin@${orgName}
    registerAndEnroll $adminHome $adminUserHome $orgName $rootCAScheme $rootCAURL admin ${orgName}NodeAdmin 

    if [ "$type" == "peer" ]; then
    # Register and enroll user1 with root ca
    user1UserHome=$usersDir/User1@${orgName}
    registerAndEnroll $adminHome $user1UserHome $orgName $rootCAScheme $rootCAURL client
    fi

    nodeCount=0
    while [ $nodeCount -lt $numNodes ]; do

        if [ "$type" == "orderer" ]; then
            nodeDir=$orgDir/${type}s/${type}${nodeCount}.${network}
            csrhost="${type}${nodeCount}-${orgName}"
        fi
        if [ "$type" == "peer" ]; then
            nodeDir=$orgDir/${type}s/${orgName}-${type}${nodeCount}.${network}
            csrhost="${type}${nodeCount}-${orgName}"
        fi

        mkdir -p $nodeDir

        # Get TLS crypto
        tlsEnroll $nodeDir $rootCAFullURL $orgName $csrhost

        # Get MSP crypto
        registerAndEnroll $adminHome $nodeDir $orgName $rootCAScheme $rootCAURL $type
        normalizeMSP $nodeDir $orgName $adminUserHome
        nodeCount=$(expr $nodeCount + 1)

    done

    # Get CA Certs from root CA
    getcacerts $orgDir $rootCAFullURL

    # Rename MSP files
    normalizeMSP $orgDir $orgName $adminUserHome
    normalizeMSP $adminHome $orgName
    normalizeMSP $adminUserHome $orgName
    if [ "$type" == "peer" ]; then
        normalizeMSP $user1UserHome $orgName
    fi
}

# getcacerts <dir> <serverURL>
function getcacerts {
    mkdir -p $1

    export FABRIC_CA_CLIENT_HOME=$1
    logFile=$1/getcacerts.log
    $CLIENT getcacert -u $2 --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem > $1/getcacert.log 2>&1

    if [ $? -ne 0 ]; then
        fatal "Failed to get CA certificates $1 with CA at $2; see $logFile"
    fi

    mkdir $1/msp/tlscacerts
    cp $1/msp/cacerts/* $1/msp/tlscacerts
    debug "Loaded CA certificates into $1 from CA at $2"
}

# tlsEnroll <homeDir> <serverPort> <orgName> <csrhost>
function tlsEnroll {
    homeDir=$1
    url=$2
    orgName=$3
    csrhost=$4
    host=$(basename $homeDir),$(basename $homeDir | cut -d'.' -f1),$csrhost,${csrhost}-service,localhost
    tlsDir=$homeDir/tls
    srcMSP=$tlsDir/msp
    dstMSP=$homeDir/msp

    enroll $tlsDir $url $orgName \
        --csr.hosts $host \
        --enrollment.profile tls

    cp $srcMSP/signcerts/* $tlsDir/server.crt
    cp $srcMSP/keystore/* $tlsDir/server.key
    mkdir -p $dstMSP/keystore
    cp $srcMSP/keystore/* $dstMSP/keystore
    mkdir -p $dstMSP/tlscacerts
    cp $srcMSP/tlscacerts/* $dstMSP/tlscacerts/tlsca.${orgName}-cert.pem

    if [ -d $srcMSP/tlsintermediatecerts ]; then
        cp $srcMSP/tlsintermediatecerts/* $tlsDir/ca.crt
        mkdir -p $dstMSP/tlsintermediatecerts
        cp $srcMSP/tlsintermediatecerts/* $dstMSP/tlsintermediatecerts
    else
        cp $srcMSP/tlscacerts/* $tlsDir/ca.crt
    fi
    rm -rf $srcMSP $homeDir/enroll.log $homeDir/fabric-ca-client-config.yaml
}

# normalizeMSP <home> <orgName> <adminHome>
function normalizeMSP {
    userName=$(basename $1)
    mspDir=$1/msp
    orgName=$2
    admincerts=$mspDir/admincerts
    cacerts=$mspDir/cacerts
    intcerts=$mspDir/intermediatecerts
    signcerts=$mspDir/signcerts
    cacertsfname=$cacerts/ca.${orgName}-cert.pem

    if [ ! -f $cacertsfname ]; then
        mv $cacerts/* $cacertsfname
    fi

    intcertsfname=$intcerts/ca.${orgName}-cert.pem

    if [ ! -f $intcertsfname ]; then
        if [ -d $intcerts ]; then
            mv $intcerts/* $intcertsfname
        fi
    fi

    signcertsfname=$signcerts/${userName}-cert.pem
    if [ ! -f $signcertsfname ]; then
        fname=`ls $signcerts 2> /dev/null`
        if [ "$fname" = "" ]; then
            mkdir -p $signcerts
            cp $cacertsfname $signcertsfname
        else
            mv $signcerts/* $signcertsfname
        fi
    fi

    # Copy the admin cert
    mkdir -p $admincerts
    if [ $# -gt 2 ]; then
        src=`ls $3/msp/signcerts/*`
        dst=$admincerts/Admin@${orgName}-cert.pem
    else
        src=`ls $signcerts/*`
        dst=$admincerts
    fi

    if [ ! -f $src ]; then
        fatal "admin certificate file not found at $src"
    fi

    cp $src $dst
}

# enroll <homeDir> <serverURL> <orgName> [<args>]
function enroll {
    homeDir=$1; shift
    url=$1; shift
    orgName=$1; shift

    mkdir -p $homeDir

    export FABRIC_CA_CLIENT_HOME=$homeDir
    logFile=$homeDir/enroll.log

    echo $CLIENT enroll -u $url $* --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem 

    $CLIENT enroll -u $url $* --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem > $logFile 2>&1

    echo "NodeOUs:
    Enable: true
    ClientOUIdentifier:
        Certificate: cacerts/ca.${orgName}-cert.pem
        OrganizationalUnitIdentifier: client
    PeerOUIdentifier:
        Certificate: cacerts/ca.${orgName}-cert.pem
        OrganizationalUnitIdentifier: peer
    AdminOUIdentifier:
        Certificate: cacerts/ca.${orgName}-cert.pem
        OrganizationalUnitIdentifier: admin
    OrdererOUIdentifier:
        Certificate: cacerts/ca.${orgName}-cert.pem
        OrganizationalUnitIdentifier: orderer" > $FABRIC_CA_CLIENT_HOME/msp/config.yaml

    if [ $? -ne 0 ]; then
        fatal "Failed to enroll $homeDir with CA at $url; see $logFile"
    fi

    debug "Enrolled $homeDir with CA at $url"
}

# register <user> <password> <registrarHomeDir> <orgName> <userType>
function register {
    export FABRIC_CA_CLIENT_HOME=$3
    mkdir -p $3
    logFile=$3/register.log
    $CLIENT register --id.name $1 --id.secret $2 --id.type $5 --id.affiliation $4 --caname $FABRIC_CA_SERVER_CA_NAME --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem > $logFile 2>&1

    if [ $? -ne 0 ]; then
        debug "Failed to register $5 $1 with CA as $3; see $logFile"
    fi

    debug "Registered $5 $1 with CA as $3"
}

# registerAndEnroll <registrarHomeDir> <registreeHomeDir> <orgname> <rootcascheme> <rooturl> <userType> <username> <password> 
function registerAndEnroll {
    userName=$7
    if [ "$userName" = "" ]; then
        userName=$(basename $2)
    fi
    password=${8-secret}

    register $userName $password $1 $3 $6
    enroll $2 ${4}://${userName}:${password}@$5 $3
}

function fatal {
    echo "FATAL $*"
    exit 1
}

function debug {
    echo "    $*"
}

function addRegulatorAffiliations {

    $CLIENT affiliation add regulator --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation regulator "
    else
        debug "Added affiliation regulator "
    fi
}

function addGeneralAffiliations {

    echo "Add general affiliations..."

    $CLIENT affiliation add general --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation general "
    else
        debug "Added affiliation general "
    fi

    $CLIENT affiliation add general.manufacturing --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation general.manufacturing "
    else
        debug "Added affiliation general.manufacturing "
    fi

    $CLIENT affiliation add general.sales --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation general.sales "
    else
        debug "Added affiliation general.sales "
    fi

    $CLIENT affiliation add general.sales.sharks --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem
    
    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation general.sales.sharks "
    else
        debug "Added affiliation general.sales.sharks "
    fi
    
    $CLIENT affiliation add general.sales.mgrs --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation general.sales.mgrs "
    else
        debug "Added affiliation general.sales.mgrs "
    fi
}

function addAirbusAffiliations {

    echo "Add airbus affiliations..."

    $CLIENT affiliation add airbus --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation airbus "
    else
        debug "Added affiliation airbus "
    fi

    $CLIENT affiliation add airbus.sales --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add affiliation airbus.sales "
    else
        debug "Added affiliation airbus.sales "
    fi

}

function registerGeneralNewUsers {
    echo "Add general new Users..."

    $CLIENT register --id.name manu --id.secret manupw --id.type client --id.affiliation general.manufacturing --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add user manu "
    else
        debug "Added user manu "
    fi

    $CLIENT register --id.name salu --id.secret salupw --id.type client --id.affiliation general.sales.sharks --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add user salu "
    else
        debug "Added user salu "
    fi

    $CLIENT register --id.name balu --id.secret balupw --id.type client --id.affiliation general.sales.mgrs --tls.certfiles $FABRIC_CA_SERVER_CERT_MOUNT_PATH/tls-cert.pem

    if [ $? -ne 0 ]; then
        debug "Failed to add user balu "
    else
        debug "Added user balu "
    fi
}

function registerAirbusNewUsers {
    echo "Add general new Users..."

}

main