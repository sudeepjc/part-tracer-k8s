const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');
const { FileSystemWallet, Gateway } = require('fabric-network');

async function queryPart(userName, netwrk, chaincode, func, args) {

    // Create a new file system based wallet for managing identities.
    const walletPath = path.join(__dirname, `../identity/user/${userName}/wallet`);
    console.log(`walletPath: ${walletPath}`);
    const wallet = new FileSystemWallet(walletPath);

    // A gateway defines the peers used to access Fabric networks
    const gateway = new Gateway();

    let response;

    try {

        // Load connection profile; will be used to locate a gateway
        const userOrg = 'general';
        
        
        let connectionProfilePath = `/files/config/general/partTracer-${userOrg}.yaml`;

        console.log(`connectionProfilePath: ${connectionProfilePath}`);
        let connectionProfile = yaml.safeLoad(fs.readFileSync(connectionProfilePath, 'utf8'));
        console.log(`connectionProfile: ${connectionProfile}`);

        // Set connection options; identity and wallet
        let connectionOptions = {
            identity: userName,
            wallet: wallet,
            discovery: { enabled:true, asLocalhost: false }
        };

        // Connect to gateway using application specified parameters
        console.log('Connect to Fabric gateway.');

        await gateway.connect(connectionProfile, connectionOptions);

        // Access myChannel network
        console.log(`Use network channel: ${netwrk}`);

        const network = await gateway.getNetwork(netwrk);

        console.log('Use org.partTracer.partTrade smart contract.');

        const contract = await network.getContract(chaincode);

        // queryPart
        console.log('evaluate partTrade queryPart query.');

        let queryResponse;

        switch(args.length){
            case 1:
                queryResponse = await contract.evaluateTransaction(func, args[0]);
                break;
            case 2:
                queryResponse = await contract.evaluateTransaction(func, args[0],args[1]);
                break;
            case 4:
                queryResponse = await contract.evaluateTransaction(func, args[0],args[1],args[2],args[3]);
                break;
            default:
                console.log(`Error with query ${args}`);
        }

        // process response
        console.log('Process queryPart query response.'+queryResponse);

        let qResponse = JSON.parse(queryResponse.toString());

        console.log(`Part ${qResponse} was queried successfully`);
        console.log('Query complete.');
        response = { success: true, queryResult: qResponse };

    } catch (error) {
        
        console.log(`Error processing query. ${error}`);
        console.log(error.stack);

        response = { success: false, status:500, message: `Error processing query. ${error}`};
        
        if(error.endorsements && error.endorsements.length > 0){
            console.log(`Error processing query. ${error.endorsements[0]}`);
            response = { success: false, status:500, message: `Error processing query. ${error.endorsements[0]}`};
        }
        
    } finally {

        // Disconnect from the gateway
        console.log('Disconnect from Fabric gateway.');
        gateway.disconnect();

        return response;

    }
}

module.exports = queryPart;

// let queryArgs = ['queryPart','engine_1'];

// queryArgs = ['queryPart','engine_2'];

// queryArgs = ['queryParts','engine_2','engine_5'];

// queryArgs = ["queryPartsWithPagination","","","5","engine_2"];

// queryArgs = ['getPartHistory','engine_1'];

// queryArgs = ["getRichQueryResult","{\"selector\":{\"docType\":\"Part\",\"owner\":\"GeneralMSP\"}}"];

// queryPart('user1',queryArgs);
