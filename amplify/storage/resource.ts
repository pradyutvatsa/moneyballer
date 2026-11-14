// amplify/storage/resource.ts
import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
    name: 'moneyballerProfilePhotos',
    access: (allow) => ({
        'profile-pictures/{entity_id}/*': [
            allow.guest.to(['read']),
            allow.authenticated.to(['read', 'write', 'delete']),
        ],
    })
});