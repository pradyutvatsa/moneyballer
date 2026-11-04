import { type ClientSchema, a, defineData } from '@aws-amplify/backend';

const schema = a.schema({
  User: a.model({
    name: a.string().required(),
    email: a.string().required(),
    role: a.string(),
    walletBalance: a.float().required(), // Stores credits / debits
    teams: a.hasMany('TeamMember', 'userId'),
    payments: a.hasMany('Payment', 'userId'),
    rsvps: a.hasMany('RSVP', 'userId'),
  }).authorization(allow => [allow.publicApiKey()]),

  Team: a.model({
    name: a.string().required(),
    members: a.hasMany('TeamMember', 'teamId'),
    games: a.hasMany('Game', 'teamId'),
  }).authorization(allow => [allow.publicApiKey()]),

  TeamMember: a.model({
    userId: a.id().required(),
    teamId: a.id().required(),
    user: a.belongsTo('User', 'userId'),
    team: a.belongsTo('Team', 'teamId'),
  }).authorization(allow => [allow.publicApiKey()]),

  Game: a.model({
    date: a.date().required(),
    time: a.time().required(),
    location: a.string().required(),
    organizerId: a.id().required(),
    maxPlayers: a.integer().required(),
    appFee: a.float().required(), // Total upfront fee ($1.99 or $2.99)
    minimumBalanceRequired: a.float().required(), // Minimum wallet balance for player to join
    teamId: a.id(),
    team: a.belongsTo('Team', 'teamId'),
    rsvps: a.hasMany('RSVP', 'gameId'),
  }).authorization(allow => [allow.publicApiKey()]),

  Venue: a.model({
    name: a.string().required(),
    address: a.string().required(),
  }).authorization(allow => [allow.publicApiKey()]),

  RSVP: a.model({
    status: a.string().required(), // 'Going', 'Not Going'
    gameId: a.id().required(),
    userId: a.id().required(),
    game: a.belongsTo('Game', 'gameId'),
    user: a.belongsTo('User', 'userId'),
  }).authorization(allow => [allow.publicApiKey()]),

  Payment: a.model({
    amount: a.float().required(),
    type: a.string().required(), // 'Organizer Fee Debit', 'Player Fee Share', 'Organizer Reimbursement'
    status: a.string().required(), // 'Completed', 'Pending'
    userId: a.id().required(),
    user: a.belongsTo('User', 'userId'),
  }).authorization(allow => [allow.publicApiKey()]),
});

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'apiKey',
    apiKeyAuthorizationMode: { expiresInDays: 30 },
  },
});