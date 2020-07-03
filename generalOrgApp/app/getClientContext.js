const fs = require('fs');
const path = require('path');
const Client = require('fabric-client');

// Client section configuration

const CONNECTION_PROFILE_PATH = '/files/config/general/partTracer-general.yaml';
const CRYPTO_CONFIG_PEER_ORGANIZATIONS ='/etc/hyperledger/fabric';
const GENERAL_CLIENT_CONNECTION_PROFILE_PATH = path.join(__dirname,'../generalOrgClient.yaml');

const client = Client.loadFromConfig(CONNECTION_PROFILE_PATH);

async function getClientContext(user,org){

  client.loadFromConfig(GENERAL_CLIENT_CONNECTION_PROFILE_PATH);

  // Initialize the store
  await initCredentialStore()

  // Lets get the specified user from the store
  let userContext = await client.loadUserFromStateStore(user)
  // If user is null then the user does not exist
  if( userContext == null ){
    
    // Create the user context
    userContext = await createUserContext(org, user)
    console.log(`Created ${user} under the credentials store!!`)
  } else {
    console.log(`User ${user} already exist!!`)
  }
  // Setup the context on the client
  await client.setUserContext(userContext, false)

  return client;
}


/**
 * Initialize the file system credentials store
 */
async function initCredentialStore() {

    // Call the function for initializing the credentials store on file system
    await client.initCredentialStores()
        .then((done) => {
            console.log("initCredentialStore(): ", done)
        })
}

/**
 * Setup the user context
 **/
async function createUserContext(org, user) {
    // Get the path  to user private key
    let privateKeyPath = getPrivateKeyPath(org, user)

    // Get the path to the user certificate
    let certPath = getCertPath(org, user)

    // Setup the options for the user context
    // Global Type: UserOpts 
    let opts = {
        username: user,
        mspid: "GeneralMSP",
        cryptoContent: {
            privateKey: privateKeyPath,
            signedCert: certPath
        },
        // Set this to true to skip persistence
        skipPersistence: false
    }
    
    // Setup the user 
    let userContext = await client.createUser(opts)

    return userContext
}

/**
 * Reads content of the certificate
 * @param {string} org 
 * @param {string} user 
 */
function getCertPath(org, user) {
    //budget.com/users/Admin@budget.com/msp/signcerts/Admin@budget.com-cert.pem"
    var certPath = CRYPTO_CONFIG_PEER_ORGANIZATIONS + "/" + org + "/users/" + user + "@" + org + ".parttracer.com/msp/signcerts/cert.pem"
    return certPath
}

/**
 * Reads the content of users private key
 * @param {string} org 
 * @param {string} user 
 */
function getPrivateKeyPath(org, user) {
    // ../crypto/crypto-config/peerOrganizations/budget.com/users/Admin@budget.com/msp/keystore/05beac9849f610ad5cc8997e5f45343ca918de78398988def3f288b60d8ee27c_sk
    var pkFolder = CRYPTO_CONFIG_PEER_ORGANIZATIONS + "/" + org + "/users/" + user + "@" + org + ".parttracer.com/msp/keystore"
    fs.readdirSync(pkFolder).forEach(file => {
        // console.log(file);
        // return the first file
        pkfile = file
        return
    })

    return (pkFolder + "/" + pkfile)
}

// getClientContext("Admin","general");
module.exports = getClientContext;