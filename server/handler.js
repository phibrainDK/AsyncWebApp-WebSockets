const AWS = require('aws-sdk');
AWS.config.update({
    region: process.env.AWS_REGION,
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
    const connectionId = event.requestContext.connectionId;
    const body = JSON.parse(event.body);
    const action = body.action;
    const message = body.message;

    if (action === 'connect') {
        await storeConnectionId(connectionId, message);
        return {
            statusCode: 200,
            body: 'Connected.',
            message: message
        };
    } else if (action === 'disconnect') {
        await deleteConnectionId(connectionId);
        return {
            statusCode: 200,
            body: 'Disconnected.',
            message: message
        };
    } else {
        return {
            statusCode: 200,
            body: 'Message sent.',
            message: message
        };
    }
};

async function storeConnectionId(connectionId, message) {
    const ttl = Math.floor(Date.now() / 1000) + 60 * 60 * 24;
    const params = {
        TableName: TABLE_NAME,
        Item: {
            connectionId: connectionId,
            message: message,
            ttl: ttl
        }
    };
    await dynamoDB.put(params).promise();
}

async function deleteConnectionId(connectionId) {
    const params = {
        TableName: TABLE_NAME,
        Key: {
            connectionId: connectionId
        }
    };
    await dynamoDB.delete(params).promise();
}
