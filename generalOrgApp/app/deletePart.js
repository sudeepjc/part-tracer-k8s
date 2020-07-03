const fs = require('fs');
const yaml = require('js-yaml');
const path = require('path');
const { FileSystemWallet, Gateway } = require('fabric-network');

async function deletePart(userName,partID) {

    // Create a new file system based wallet for managing identities.
    const walletPath = path.join(__dirname, `../identity/user/${userName}/wallet`);
    console.log(`walletPath: ${walletPath}`);
    const wallet = new FileSystemWallet(walletPath);

    // A gateway defines the peers used to access Fabric networks
    const gateway = new Gateway();

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
        console.log('Use network channel: mychannel.');

        const network = await gateway.getNetwork('mychannel');

        console.log('Use org.partTracer.partTrade smart contract.');

        const contract = await network.getContract('partTracer');

        // deletePart
        console.log('Submit partTrade deletePart transaction.');

        const deleteResponse = await contract.submitTransaction('deletePart', partID);

        console.log(`Part ${partID} was deleted successfully`);
        console.log('Transaction complete.');

    } catch (error) {

        if(error.endorsements && error.endorsements.length > 0){
            console.log(`Error processing transaction. ${error.endorsements[0]}`);
        }

        console.log(`Error processing transaction. ${error}`);
        console.log(error.stack);

    } finally {

        // Disconnect from the gateway
        console.log('Disconnect from Fabric gateway.');
        gateway.disconnect();

    }
}

deletePart('user1',process.argv[2]);