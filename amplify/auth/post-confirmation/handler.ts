import type { PostConfirmationTriggerHandler } from 'aws-lambda';
import { type Schema } from '../../data/resource';
import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/data';
import { getAmplifyDataClientConfig } from '@aws-amplify/backend/function/runtime';
import { env } from '$amplify/env/post-confirmation';

// Initialize the Amplify Data client using the auto-injected AppSync environment variables
const { resourceConfig, libraryOptions } = await getAmplifyDataClientConfig(env);
Amplify.configure(resourceConfig, libraryOptions);

const client = generateClient<Schema>();

export const handler: PostConfirmationTriggerHandler = async (event) => {
    if (event.request.userAttributes) {
        const { sub, email, name } = event.request.userAttributes;

        try {
            // Create the user securely through the AppSync GraphQL API
            const { errors, data: newUser } = await client.models.User.create({
                id: sub,
                name: name || 'New Player',
                email: email,
                walletBalance: 0.0,
            });

            if (errors) {
                console.error('Errors creating User in AppSync:', errors);
            } else {
                console.log(`Successfully synced user ${sub} via AppSync`);
            }
        } catch (error) {
            console.error('Error executing User create mutation:', error);
        }
    }

    return event;
};