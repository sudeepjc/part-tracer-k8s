const Client = require('fabric-client');
const getClientContext =  require('./getClientContext');

async function registerEvents(user, org, channelName, peerName){
  
  let client = await getClientContext(user,org);

  let channel = await getChannel(channelName, client);

  await setupBlockListener(channel,peerName);

  await setupChaincodeListener(channel,peerName);
}

async function getChannel(channelName, client) {
  try {
      // Get the Channel class instance from client
      channel = await client.getChannel(channelName, true)
  } catch (error) {
      console.log(error.stack? error.stack : error);
      console.log("Could NOT create channel: ", channelName)
      process.exit(1)
  }
  console.log("Created channel object.")

  return channel
}

async function setupBlockListener(channel,peerName){

  let eventHub = channel.getChannelEventHub(peerName);

  let blockHandler = eventHub.registerBlockEvent(

      (block)=>{
          console.log('\non Block Event: Number:',block.header.number)
      },

      ()=>{
          console.log('on Block Event Error!!!')
      }
  )

  let  connectOptions = {
      full_block: true  
  }

  eventHub.connect(connectOptions, 
      ()=>{
          console.log('block  connectCallback')
      }
  )

  console.log('blockHandler started with handler_id=',blockHandler)
}

async function setupChaincodeListener(channel,peerName){

  let eventHub = channel.getChannelEventHub(peerName);

  let addPartHandler = await eventHub.registerChaincodeEvent("partTracer","addPart",(chaincodeEvent)=>{
    console.log(`\non chaincodeEvent: ${chaincodeEvent.chaincode_id}  ${chaincodeEvent.event_name}  ${new String(chaincodeEvent.payload)}`)
    },()=>{
        console.log('on Chaincode Event Error!!!')
    })

    eventHub.connect(true,()=>{
              console.log('chaincodeEvent  connectCallback')
    })

    console.log('chaincodeEvenrHandler started with handler_id=',addPartHandler)

    let sellPartHandler = await eventHub.registerChaincodeEvent("partTracer","sellPart",(chaincodeEvent)=>{
      console.log(`\non chaincodeEvent: ${chaincodeEvent.chaincode_id}  ${chaincodeEvent.event_name}  ${new String(chaincodeEvent.payload)}`)
    }, ()=>{
      console.log('on Chaincode Event Error!!!')
    })

  eventHub.connect(true,()=>{
    console.log('chaincodeEvent  connectCallback')
  })

  console.log('chaincodeEvenrHandler started with handler_id=',sellPartHandler)
}

registerEvents("User1", "airbus", "mychannel", "peer0-airbus-service");