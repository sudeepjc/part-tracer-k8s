const FabricCAServices = require('fabric-ca-client');
const { FileSystemWallet } = require('fabric-network');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

async function enrollUser(userName, userPwd, userOrg ) {
    let response;
    try {
        // load the network configuration
        console.log(`Orgname: ${userOrg}`);
        
        let connectionProfilePath = `/files/config/general/partTracer-${userOrg}.yaml`;  
        console.log(`connectionProfilePath: ${connectionProfilePath}`);
        let connectionProfile = yaml.safeLoad(fs.readFileSync(connectionProfilePath, 'utf8'));
        console.log(`connectionProfile: ${connectionProfile}`);

        let caName = `${userOrg}-ca-root`;

        // Create a new CA client for interacting with the CA.
        const caInfo = connectionProfile.certificateAuthorities[caName];
        console.log(`caInfo: ${caInfo}`);
        let caTLSCACerts_file = fs.readFileSync(caInfo.tlsCACerts.path);
        const caTLSCACerts = Buffer.from(caTLSCACerts_file).toString();
        const ca = new FabricCAServices(caInfo.url, { trustedRoots: caTLSCACerts, verify: false }, caInfo.caName);

        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(__dirname, `../identity/user/${userName}/wallet`);
        console.log(`walletPath: ${walletPath}`);
        const wallet = new FileSystemWallet(walletPath);

        // Check to see if we've already enrolled the admin user.
        const userExists = await wallet.exists(userName);
        if (userExists) {
            console.log(`An identity for the client user ${userName} already exists in the wallet`);
            response = { success: false, message: `An identity for the client user ${userName} already exists in the wallet`};
            return response;
        }

        // Enroll the admin user, and import the new identity into the wallet.
        const enrollment = await ca.enroll({ enrollmentID: userName, enrollmentSecret: userPwd });
        const x509Identity = {
            certificate: enrollment.certificate,
            privateKey: enrollment.key.toBytes(),
            mspId: connectionProfile.organizations.general.mspid,
            type: 'X.509',
        };
        await wallet.import(userName, x509Identity);
        console.log(`Successfully enrolled client user ${userName} and imported it into the wallet`);

        response = {success: true, message: `Successfully enrolled client user ${userName} and imported it into the wallet` };

    } catch (error) {
        response = { success: false, message: error.message};
        console.log(error.stack? error.stack : error);

        console.error(`Failed to enroll client user "${userName}": ${error}`);
    }

    return response;
}

// enrollUser("user1",'user1pw','general');

module.exports = enrollUser;