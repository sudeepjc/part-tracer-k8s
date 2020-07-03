const getClientContext =  require('./getClientContext');

async function joinChannel(channelName, peers, user, org) {
	console.log('\n\n============ Join Channel start ============\n')
	var error_message = null;
	var all_eventhubs = [];
	try {
		console.log(`Calling peers in organization ${org} to join the channel`);

    let client = await getClientContext(user,org);
    
		console.log(`Successfully got the fabric client for the organization ${org}`);
		var channel = client.getChannel(channelName);
		if(!channel) {
			let message = `Channel ${channelName} was not defined in the connection profile`;
			console.log(message);
			throw new Error(message);
		}

		let request = {
			txId : 	client.newTransactionID(true)
		};
		let genesis_block = await channel.getGenesisBlock(request);

		// tell each peer to join and wait 10 seconds
		// for the channel to be created on each peer
		var promises = [];
		promises.push(new Promise(resolve => setTimeout(resolve, 10000)));

		let join_request = {
			targets: peers, 
			txId: client.newTransactionID(true), 
			block: genesis_block
		};
		let join_promise = channel.joinChannel(join_request);
		promises.push(join_promise);
		let results = await Promise.all(promises);
		console.log(`Join Channel R E S P O N S E : ${results}`);

		let peers_results = results.pop();
		// then each peer results
		for(let i in peers_results) {
			let peer_result = peers_results[i];
			if (peer_result instanceof Error) {
				error_message = `Failed to join peer to the channel with error :: ${peer_result.toString()}`;
				console.log(error_message);
			} else if(peer_result.response && peer_result.response.status == 200) {
				console.log(`Successfully joined peer to the channel ${channelName}`);
			} else {
				error_message = `Successfully joined peer to the channel ${channelName}`;
				console.log(error_message);
			}
		}
	} catch(error) {
		console.log(`Failed to join channel due to error: ${error.stack ? error.stack : error}`);
		error_message = error.toString();
	}

	// need to shutdown open event streams
	all_eventhubs.forEach((eh) => {
		eh.disconnect();
	});

	if (!error_message) {
		let message = `Successfully joined peers in organization ${org} to the channel: ${channelName}`;
    console.log(message);
    
		const response = {
			success: true,
			message: message
		};
    return response;
    
	} else {
		let message = `Failed to join all peers to channel. cause: ${error_message}`;
		console.log(message);
		const response = {
			success: false,
			message: message
		};
		return response;
	}
};

module.exports = joinChannel;

joinChannel("mychannel", ["peer0-airbus-service"], "Admin", "airbus");
