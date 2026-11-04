// amplify/data/resolvers/calculateFee.js
import { util } from '@aws-appsync/utils';

export function request(ctx) {
    // 1. Intercept the incoming maxPlayers argument[cite: 1]
    const maxPlayers = ctx.args.input.maxPlayers;

    // 2. Secure backend fee calculation[cite: 1]
    const calculatedFee = maxPlayers <= 10 ? 1.99 : 2.99;

    // 3. Inject the secure fee into the incoming mutation payload[cite: 1]
    ctx.args.input.appFee = calculatedFee;
    ctx.args.input.minimumBalanceRequired = calculatedFee;

    // 4. Pass the modified payload through to AppSync's native DynamoDB PutItem resolver
    return {
        operation: 'PutItem',
        key: util.dynamodb.toMapValues({ id: util.autoId() }),
        attributeValues: util.dynamodb.toMapValues(ctx.args.input),
        condition: {
            expression: 'attribute_not_exists(#id)',
            expressionNames: { '#id': 'id' },
        },
    };
}

export function response(ctx) {
    if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type);
    }
    return ctx.result;
}