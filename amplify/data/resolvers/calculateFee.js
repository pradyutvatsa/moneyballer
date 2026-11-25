// amplify/data/resolvers/calculateFee.js
import { util } from '@aws-appsync/utils';

export function request(ctx) {
    const {
        date,
        time,
        location,
        organizerId,
        maxPlayers,
        squadType,
        userFeeInput,
        teamId,
    } = ctx.args;

    if (!maxPlayers || maxPlayers <= 0) {
        util.error('maxPlayers must be greater than 0', 'ValidationException');
    }

    // 1. Determine platform tier fee ($1.99 for <= 10 players, $2.99 for > 10 players)
    const appTierFee = maxPlayers <= 10 ? 1.99 : 2.99;

    // 2. Sanitize organizer's base fee input (only applicable for SOCIAL squads)
    const baseUserFee =
        squadType === 'SOCIAL' && typeof userFeeInput === 'number' && userFeeInput > 0
            ? userFeeInput
            : 0.0;

    // 3. Compute authoritative per-player total fee:
    //    userInput + (1.99 or 2.99) / maxPlayers
    const rawTotalPerPlayer = baseUserFee + appTierFee / maxPlayers;
    const computedTotalPerPlayer = Math.round(rawTotalPerPlayer * 100) / 100;

    const now = util.time.nowISO8601();

    const item = {
        __typename: 'Game',
        date,
        time,
        location,
        organizerId,
        maxPlayers,
        userFeeInput: baseUserFee,
        appFee: appTierFee,
        minimumBalanceRequired: computedTotalPerPlayer,
        createdAt: now,
        updatedAt: now,
    };

    if (teamId) {
        item.teamId = teamId;
    }

    return {
        operation: 'PutItem',
        key: util.dynamodb.toMapValues({ id: util.autoId() }),
        attributeValues: util.dynamodb.toMapValues(item),
    };
}

export function response(ctx) {
    if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type);
    }
    return ctx.result;
}