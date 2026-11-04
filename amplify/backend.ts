import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data } from './data/resource';
import { postConfirmation } from './auth/post-confirmation/resource'; // 1. Import it directly

const backend = defineBackend({
  auth,
  data,
  postConfirmation, // 2. Register it as a top-level function
});

// 3. Extract the guaranteed physical Lambda reference
const postConfirmationLambda = backend.postConfirmation.resources.lambda as any;
const userTable = backend.data.resources.tables['User'];

if (postConfirmationLambda && userTable) {
  // 4. Grant permissions and inject the environment variable securely
  userTable.grantWriteData(postConfirmationLambda);
  postConfirmationLambda.addEnvironment('USER_TABLE_NAME', userTable.tableName);
}