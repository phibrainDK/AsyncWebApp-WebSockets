const AWS = require('aws-sdk');
AWS.config.update({
    region: process.env.DEPLOY_REGION,
});

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const DYNAMODB_TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;


exports.handler = async (event) => {
    console.log(":: we invoke the handler... ::");
    console.log(event);
    if (event.requestContext.eventType == 'NOTIFY_ALL') {
        try {
            const connectionData = await dynamoDB.scan({ TableName: DYNAMODB_TABLE_NAME }).promise();
            const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
                endpoint: event.requestContext.endpoint
            });
            const message = event.requestContext.customMessage;
            console.log("message = ", message);
            const postPromises = connectionData.Items.map(async (connection) => {
                try {
                    await apiGatewayManagementApi.postToConnection({
                        ConnectionId: connection.connectionId,
                        Data: JSON.stringify({ message })
                    }).promise();
                } catch (e) {
                    if (e.statusCode === 410) {
                        console.log(":: We gonna delete the connetion ID ::");
                        // If the client has disconnected, remove the connection ID from DynamoDB
                        await deleteConnectionId(connection.connectionId);
                    } else {
                        console.log(":: An error ocurred ::");
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
    } else if (event.requestContext.eventType == 'NOTIFY_ONLY') {
        try {
            const userId = event.requestContext.userId;
            const message = event.requestContext.customMessage;
            console.log("user_id = ", userId, "message = ", message);
            const result = await dynamoDB.query({
                TableName: DYNAMODB_TABLE_NAME,
                KeyConditionExpression: 'userId = :userId',
                ExpressionAttributeValues: {
                    ':userId': userId
                }
            }).promise();
            console.log(":: result :: ", result);
            // Obtener todas las connectionId asociadas al usuario
            const connectionIds = result.Items.map(item => item.connectionId);
            console.log("connections list IDs -> ", connectionIds);
            const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
                endpoint: event.requestContext.endpoint
            });
            const postPromises = connectionIds.map(async (connectionId) => {
                try {
                    await apiGatewayManagementApi.postToConnection({
                        ConnectionId: connectionId,
                        Data: JSON.stringify({ message })
                    }).promise();
                } catch (e) {
                    if (e.statusCode === 410) {
                        console.log(":: We gonna delete the connetion ID ::");
                        // If the client has disconnected, remove the connection ID from DynamoDB
                        await deleteConnectionId(connectionId);
                    } else {
                        console.log(":: An error ocurred ::");
                        console.error('Failed to send message:', e);
                    }
                }
            });
            // Wait for all messages to be sent before returning a response
            await Promise.all(postPromises);
        
            return { statusCode: 200, body: `Message sent to client = ${userId}` };
        } catch (error) {
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
                const userId =  event.requestContext.authorizer.principalId
                console.log("ip is : ", ip);
                await storeConnectionId(userId, connectionId, ip);
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

async function storeConnectionId(userId, connectionId, data) {
    const ttl = Math.floor(Date.now() / 1000) + 60 * 60 * 24;
    const params = {
        TableName: DYNAMODB_TABLE_NAME	,
        Item: {
            userId: userId,
            connectionId: connectionId,
            data: data,
            ttl: ttl
        }
    };
    await dynamoDB.put(params).promise();
}

async function deleteConnectionId(connectionId) {
    const result = await dynamoDB.query({
        TableName: DYNAMODB_TABLE_NAME,
        IndexName: 'ConnectionIdIndex',
        KeyConditionExpression: 'connectionId = :connectionId',
        ExpressionAttributeValues: {
            ':connectionId': connectionId
        }
    }).promise();
    console.log(result);
    if (result.Items.length > 0) {
        const userId = result.Items[0].userId;
        await dynamoDB.delete({
            TableName: DYNAMODB_TABLE_NAME,
            Key: {
                userId: userId,
                connectionId: connectionId
            }
        }).promise();
    }
}
