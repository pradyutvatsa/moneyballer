// amplify/auth/post-confirmation/handler.ts
import type { PostConfirmationTriggerHandler } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient();
const docClient = DynamoDBDocumentClient.from(client);

export const handler: PostConfirmationTriggerHandler = async (event) => {
    if (event.request.userAttributes) {
        const { sub, email, name } = event.request.userAttributes;

        // Create the new User record based on your Gen 2 schema[cite: 1]
        const command = new PutCommand({
            TableName: process.env.USER_TABLE_NAME, // Injected via backend.ts
            Item: {
                id: sub,
                __typename: 'User',
                email: email,
                name: name || 'New Player',
                walletBalance: 0.0, // Initialize empty wallet for RSVPs[cite: 1]
                createdAt: new Date().toISOString(),
                updatedAt: new Date().toISOString(),
            },
        });

        try {
            await docClient.send(command);
            console.log(`Successfully created DynamoDB User record for ${sub}`);
        } catch (error) {
            console.error(`Error syncing user to DynamoDB: ${error}`);
        }
    }

    return event;
};