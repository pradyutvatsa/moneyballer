import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';

const backend = defineBackend({
  auth,
  data,
});

// Access the User DynamoDB table
const userTable = backend.data.resources.tables['User'];

// Access the trigger attached to Cognito Auth
const postConfirmationLambda = (backend.auth.resources as any).triggers?.postConfirmation;

if (postConfirmationLambda && userTable) {
  userTable.grantWriteData(postConfirmationLambda);
  postConfirmationLambda.addEnvironment('USER_TABLE_NAME', userTable.tableName);
}