const AWS = require('aws-sdk');
AWS.config.update({
    region: process.env.DEPLOY_REGION,
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const DYNAMODB_TABLE_NAME	 = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    console.log(":: we invoke the handler... ::")
    try {
        const connectionId = event.requestContext.connectionId;
        console.log("connectionId : ", connectionId);
        console.log("event is : ", event);
        const action_event = event.requestContext.routeKey;
        if (action_event === '$connect') {
            const ip = event.headers["X-Forwarded-For"];
            console.log("ip is : ", ip);
            await storeConnectionId(connectionId, ip);
            return {
                statusCode: 200,
                body: ip,
            };
        } else if (action_event === '$disconnect') {
            await deleteConnectionId(connectionId);
            return {
                statusCode: 200,
                body: 'Disconnected.',
            };
        } else {
            console.log("action_event : ", action_event);
            const message = event.body.message;
            console.log("message : ", message);
            return {
                statusCode: 200,
                body: 'Message sent.',
                message: message
            };
        }
    } catch(error) {
        console.error(error);
        throw error;
    }
};

async function storeConnectionId(connectionId, message) {
    const ttl = Math.floor(Date.now() / 1000) + 60 * 60 * 24;
    const params = {
        TableName: DYNAMODB_TABLE_NAME	,
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
        TableName: DYNAMODB_TABLE_NAME	,
        Key: {
            connectionId: connectionId
        }
    };
    await dynamoDB.delete(params).promise();
}
