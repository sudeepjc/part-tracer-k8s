const fs = require('fs');
const path = require('path');

const getClientContext =  require('./getClientContext');

async function updateAnchorPeers(channelName, configUpdatePath, user, org) {
	console.log('\n====== Updating Anchor Peers on \'' + channelName + '\' ======\n');
	var error_message = null;
	try {
		let client = await getClientContext(user,org);
		console.log('Successfully got the fabric client for the organization "%s"', org);
		let channel = client.getChannel(channelName);
		if(!channel) {
			let message = `Channel ${channelName} was not defined in the connection profile`;
			console.log(message);
			throw new Error(message);
		}

		let envelope = fs.readFileSync(path.join(__dirname, configUpdatePath));
		let channelConfig = client.extractChannelConfig(envelope);

		let signature = client.signChannelConfig(channelConfig);

		let request = {
			config: channelConfig,
			signatures: [signature],
			name: channelName,
			txId: client.newTransactionID(true) // get an admin based transactionID
		};

		var promises = [];
		let event_hubs = channel.getChannelEventHubsForOrg();
		console.log('found %s eventhubs for this organization %s',event_hubs.length, org);
		event_hubs.forEach((eh) => {
			let anchorUpdateEventPromise = new Promise((resolve, reject) => {
				console.log('anchorUpdateEventPromise - setting up event');
				const event_timeout = setTimeout(() => {
					let message = 'REQUEST_TIMEOUT:' + eh.getPeerAddr();
					console.log(message);
					eh.disconnect();
				}, 60000);
				eh.registerBlockEvent((block) => {
					console.log('The config update has been committed on peer %s',eh.getPeerAddr());
					clearTimeout(event_timeout);
					resolve();
				}, (err) => {
					clearTimeout(event_timeout);
					console.log(err);
					reject(err);
				},
					{unregister: true, disconnect: true}
				);
				eh.connect();
			});
			promises.push(anchorUpdateEventPromise);
		});

		var sendPromise = client.updateChannel(request);
		promises.push(sendPromise);
		let results = await Promise.all(promises);
		console.log(`------->>> R E S P O N S E : ${results}`);
		let response = results.pop(); //  orderer results are last in the results

		if (response) {
			if (response.status === 'SUCCESS') {
				console.log('Successfully update anchor peers to the channel %s', channelName);
			} else {
				error_message = `Failed to update anchor peers to the channel ${channelName} with status: ${response.status} reason: ${response.info}`;
				console.log(error_message);
			}
		} else {
			error_message = `Failed to update anchor peers to the channel ${channelName}`;
			console.log(error_message);
		}
	} catch (error) {
		console.log('Failed to update anchor peers due to error: ' + error.stack ? error.stack :	error);
		error_message = error.toString();
	}

	if (!error_message) {
		let message = `Successfully update anchor peers in organization ${org} to the channel ${channelName}`;
		console.log(message);
		const response = {
			success: true,
			message: message
		};
		return response;
	} else {
		let message = `Failed to update anchor peers. cause:${error_message}`;
		console.log(message);
		const response = {
			success: false,
			message: message
		};
		return response;
	}
};

module.exports = updateAnchorPeers;
updateAnchorPeers("mychannel", "/artifacts/channel-artifacts/AirbusMSPanchors.tx", "Admin", "airbus")
