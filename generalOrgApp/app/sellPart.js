const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');
const { FileSystemWallet, Gateway } = require('fabric-network');

async function sellPart(userName, netwrk, chaincode, args) {

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

        // Get addressability to partTracer contract
        console.log('Use org.partTracer.partTrade smart contract.');

        const contract = await network.getContract(chaincode);

        // sell the Part
        console.log('Submit partTrade sellPart transaction.');

        // create the transaction
        let sellResponse = await contract.submitTransaction('sellPart',args[0],args[1],args[2]);

        // process response
        console.log('Process sellPart transaction response.'+sellResponse);

        let partDetails = JSON.parse(sellResponse.toString());

        console.log(`Part ${partDetails} was sold successfully`);
        console.log('Transaction complete.');
        response = { success: true, message: `Part ${partDetails.partId} was sold to ${partDetails.owner} `};

    } catch (error) {
        console.log(`Error processing transaction. ${error}`);
        console.log(error.stack);
        response = { success: false, status:500, message: `Error processing transaction. ${error}`};
        
        if(error.endorsements && error.endorsements.length > 0){
            console.log(`Error processing transaction. ${error.endorsements[0]}`);
            response = { success: false, status:500, message: `Error processing transaction. ${error.endorsements[0]}`};
        }
    } finally {
        // Disconnect from the gateway
        console.log('Disconnect from Fabric gateway.');
        gateway.disconnect();

        return response;
    }
}

// let partDetails = [process.argv[2],'AirbusMSP','190865']

// sellPart('user1',partDetails);

module.exports = sellPart;