const { CognitoJwtVerifier } = require("aws-jwt-verify");
const { JwtExpiredError, JwtInvalidClaimError } = require("aws-jwt-verify/error");



exports.handler = async (event) => {
    console.log(":: LAMBDA BEGIN EVENT ::", event);
    const authorizationHeader = event.headers['Authorization'];
    const verifier = CognitoJwtVerifier.create({
        userPoolId: process.env.COGNITO_USER_POOL,
        tokenUse: "access",
        clientId: process.env.COGNITO_CLIENT_ID,
    });
    if (!authorizationHeader) {
        console.log(":: ERROR BEGIN ::");
        console.log(":: The event :: ", event);
        console.log(":: ERROR END ::");
        return generatePolicy('user', 'Deny', event.methodArn);
    }
    const token = authorizationHeader.replace('Bearer ', '');
    try {
        const payload = await verifier.verify(token);
        console.log("Token is valid. Payload:", payload);
        return generatePolicy(payload.username, 'Allow', event.methodArn);
    } catch (error) {
        if (error instanceof JwtExpiredError) {
            // Expired token error
            console.log(":: ERROR TOKEN EXPIRED ::");
            console.error('Token de Cognito ha expirado:', error);
        } else if (error instanceof JwtInvalidClaimError){
            // Claim token error
            console.log(":: ERROR TOKEN CLAIM ::");
            console.error('Error en claims:', error);
        } else {
            // Any other error
            console.log(":: ERROR ANY ::");
            console.error('Error al verificar el token de Cognito:', error);
        }
        return generatePolicy('user', 'Deny', event.methodArn);
    }
};

const generatePolicy = (principalId, effect, resource) => {
    const authResponse = {
        principalId: principalId,
        policyDocument: {
            Version: '2012-10-17',
            Statement: [
                {
                    Action: 'execute-api:Invoke',
                    Effect: effect,
                    Resource: resource
                }
            ]
        }
    };
    
    return authResponse;
};
