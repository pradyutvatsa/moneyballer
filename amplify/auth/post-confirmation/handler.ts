import type { PostConfirmationTriggerHandler } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient();
const docClient = DynamoDBDocumentClient.from(client);

export const handler: PostConfirmationTriggerHandler = async (event) => {
    if (event.request.userAttributes) {
        const { sub, email, name } = event.request.userAttributes;
        const tableName = process.env.USER_TABLE_NAME;

        if (!tableName) {
            console.error('CRITICAL: USER_TABLE_NAME environment variable is undefined.');
            return event;
        }

        const now = new Date().toISOString();

        const command = new PutCommand({
            TableName: tableName,
            Item: {
                id: sub,
                __typename: 'User',
                email: email,
                name: name || 'New Player',
                walletBalance: 0.0,
                createdAt: now,
                updatedAt: now,
            },
        });

        try {
            await docClient.send(command);
            console.log(`Successfully synced user ${sub} to DynamoDB table ${tableName}`);
        } catch (error) {
            console.error(`Error syncing user to DynamoDB: ${error}`);
        }
    }

    return event;
};