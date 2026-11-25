import { type ClientSchema, a, defineData } from '@aws-amplify/backend';
import { postConfirmation } from '../auth/post-confirmation/resource';

const schema = a.schema({
  User: a.model({
    name: a.string().required(),
    email: a.string().required(),
    phoneNumber: a.string(),
    additionalEmails: a.string().array(),
    firstName: a.string(),
    middleName: a.string(),
    lastName: a.string(),
    birthDate: a.date(),
    gender: a.string(),
    country: a.string(),
    timeZone: a.string(),
    accountStatus: a.string(),
    scheduledDeletionAt: a.datetime(),
    payId: a.string(),
    payIdType: a.string(),
    role: a.string(),
    walletBalance: a.float().required(),
    teams: a.hasMany('TeamMember', 'userId'),
    payments: a.hasMany('Payment', 'userId'),
    rsvps: a.hasMany('RSVP', 'userId'),
  }).authorization((allow) => [allow.authenticated()]),

  Team: a.model({
    name: a.string().required(),
    inviteCode: a.string(),
    squadType: a.string(), // e.g., 'SOCIAL', 'CLUB'
    organizerId: a.id(),
    members: a.hasMany('TeamMember', 'teamId'),
    games: a.hasMany('Game', 'teamId'),
  }).authorization((allow) => [allow.authenticated()]),

  TeamMember: a.model({
    userId: a.id().required(),
    teamId: a.id().required(),
    user: a.belongsTo('User', 'userId'),
    team: a.belongsTo('Team', 'teamId'),
  }).authorization((allow) => [allow.authenticated()]),

  Game: a.model({
    date: a.date().required(),
    time: a.time().required(),
    location: a.string().required(),
    organizerId: a.id().required(),
    maxPlayers: a.integer().required(),
    userFeeInput: a.float(), // Organizer's base input fee for Social Squads
    appFee: a.float(), // Backend-computed platform fee ($1.99 or $2.99)
    minimumBalanceRequired: a.float(), // Backend-computed total fee per player
    teamId: a.id(),
    team: a.belongsTo('Team', 'teamId'),
    rsvps: a.hasMany('RSVP', 'gameId'),
  }).authorization((allow) => [allow.authenticated()]),

  // Root-level custom mutation using AppSync JS resolver (no Lambda circular loop)
  createGameWithFee: a.mutation()
    .arguments({
      date: a.date().required(),
      time: a.time().required(),
      location: a.string().required(),
      organizerId: a.id().required(),
      maxPlayers: a.integer().required(),
      squadType: a.string(),
      userFeeInput: a.float(),
      teamId: a.id(),
    })
    .returns(a.ref('Game'))
    .authorization((allow) => [allow.authenticated()])
    .handler(
      a.handler.custom({
        dataSource: a.ref('Game'),
        entry: './resolvers/calculateFee.js',
      })
    ),

  Venue: a.model({
    name: a.string().required(),
    address: a.string().required(),
  }).authorization((allow) => [allow.authenticated()]),

  RSVP: a.model({
    status: a.string().required(),
    paymentStatus: a.string(),
    paidAmount: a.float(),
    gameId: a.id().required(),
    userId: a.id().required(),
    game: a.belongsTo('Game', 'gameId'),
    user: a.belongsTo('User', 'userId'),
  }).authorization((allow) => [allow.authenticated()]),

  Payment: a.model({
    amount: a.float().required(),
    type: a.string().required(),
    status: a.string().required(),
    gameId: a.id(),
    userId: a.id().required(),
    user: a.belongsTo('User', 'userId'),
  }).authorization((allow) => [allow.authenticated()]),
}).authorization((allow) => [
  allow.resource(postConfirmation),
]);

export type Schema = ClientSchema<typeof schema>;

export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'userPool',
  },
});