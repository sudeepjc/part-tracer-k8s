const fs = require('fs');
const path = require('path');

const getClientContext =  require('./getClientContext');

async function createChannel(channelName, channelConfigPath, user, org) {
	console.log('\n====== Creating Channel \'' + channelName + '\' ======\n');
	try {
		let client = await getClientContext(user,org);
		console.log(`Successfully got the fabric client for the organization ${org}`);

		let envelope = fs.readFileSync(path.join(__dirname, channelConfigPath));
		let channelConfig = client.extractChannelConfig(envelope);

		let signature = client.signChannelConfig(channelConfig);

		let request = {
			config: channelConfig,
			signatures: [signature],
			name: channelName,
			txId: client.newTransactionID(true) // get an admin based transactionID
		};

		const result = await client.createChannel(request)
		console.log(` result :: ${result}`);
		if (result) {
			if (result.status === 'SUCCESS') {
				console.log('Successfully created the channel.');
				const response = {
					success: true,
					message: `Channel ${channelName} created Successfully`
				};
				return response;
			} else {
				console.log('Failed to create the channel. status:' + result.status + ' reason:' + result.info);
				const response = {
					success: false,
					message: 'Channel \'' + channelName + '\' failed to create status:' + result.status + ' reason:' + result.info
				};
				return response;
			}
		} else {
			console.log('\n!!!!!!!!! Failed to create the channel \'' + channelName +
				'\' !!!!!!!!!\n\n');
			const response = {
				success: false,
				message: 'Failed to create the channel \'' + channelName + '\'',
			};
			return response;
		}
	} catch (err) {
		console.log('Failed to initialize the channel: ' + err.stack ? err.stack :	err);
		throw new Error('Failed to initialize the channel: ' + err.toString());
	}
};

module.exports = createChannel;
createChannel("mychannel", "/artifacts/channel-artifacts/mychannel.tx", "Admin", "general");
