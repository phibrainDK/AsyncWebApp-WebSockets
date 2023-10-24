const AWS = require('aws-sdk');
AWS.config.update({
    region: process.env.DEPLOY_REGION,
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const DYNAMODB_TABLE_NAME	 = process.env.DYNAMODB_TABLE_NAME;


exports.handler = async (event) => {
    console.log(":: we invoke the handler... ::")
    if (event.requestContext.eventType == 'CUSTOM_MODE') {
        try {
            const connectionData = await dynamoDB.scan({ TableName: DYNAMODB_TABLE_NAME }).promise();
            const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
                endpoint: event.requestContext.domainName + '/' + event.requestContext.stage
            });
            const message = event.requestContext.customMessage;
            const postPromises = connectionData.Items.map(async (connection) => {
                try {
                    await apiGatewayManagementApi.postToConnection({
                        ConnectionId: connection.connectionId,
                        Data: JSON.stringify({ message })
                    }).promise();
                } catch (e) {
                    if (e.statusCode === 410) {
                        // If the client has disconnected, remove the connection ID from DynamoDB
                        await deleteConnectionId(connection.connectionId);
                    } else {
                        console.error('Failed to send message:', e);
                    }
                }
            });
        
            // Wait for all messages to be sent before returning a response
            await Promise.all(postPromises);
        
            return { statusCode: 200, body: 'Message sent to all clients.' };
        } catch(error) {
            console.error(error);
            throw error;
        }
    }
    else {
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
