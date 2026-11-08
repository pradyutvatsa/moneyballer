import 'package:flutter/material.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class EventDetailsScreen extends StatelessWidget {
  final Game game;

  const EventDetailsScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Event Details',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Game (${game.maxPlayers} Max)',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoRow(Icons.calendar_today, game.date.format()),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.access_time, game.time.format().substring(0, 5)),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.location_on, game.location),
          const SizedBox(height: 40),

          const Text(
            'RSVP Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // RSVP Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // 1. Calculate player's equal share of the upfront fee
                    final double playerShare = game.maxPlayers > 0
                        ? game.appFee / game.maxPlayers
                        : 0.0;

                    try {
                      // 2. Fetch authenticated Cognito User
                      final authUser = await Amplify.Auth.getCurrentUser();
                      final userId = authUser.userId;

                      // 3. Fetch joining Player's profile directly
                      final playerRequest = ModelQueries.get(
                        User.classType,
                        UserModelIdentifier(id: userId),
                      );
                      final playerResponse = await Amplify.API
                          .query(request: playerRequest)
                          .response;
                      final player = playerResponse.data;

                      if (player == null) {
                        safePrint('Player profile not found.');
                        return;
                      }

                      // 4. Verify player has sufficient funds
                      if (player.walletBalance < playerShare) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Insufficient funds. Please top up \$$playerShare to RSVP.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      // 5. Deduct fee from Player's wallet
                      final updatedPlayer = player.copyWith(
                        walletBalance: player.walletBalance - playerShare,
                      );
                      await Amplify.API
                          .mutate(request: ModelMutations.update(updatedPlayer))
                          .response;

                      // 6. Fetch and Reimburse Organizer's wallet
                      final orgRequest = ModelQueries.get(
                        User.classType,
                        UserModelIdentifier(id: game.organizerId),
                      );
                      final orgResponse = await Amplify.API
                          .query(request: orgRequest)
                          .response;
                      final organizer = orgResponse.data;

                      if (organizer != null) {
                        final updatedOrganizer = organizer.copyWith(
                          walletBalance: organizer.walletBalance + playerShare,
                        );
                        await Amplify.API
                            .mutate(
                              request: ModelMutations.update(updatedOrganizer),
                            )
                            .response;

                        // Generate Organizer Reimbursement Payment Record
                        final orgPayment = Payment(
                          amount: playerShare,
                          type: 'Organizer Reimbursement',
                          status: 'Completed',
                          user: updatedOrganizer,
                        );
                        await Amplify.API
                            .mutate(request: ModelMutations.create(orgPayment))
                            .response;
                      }

                      // 7. Generate Player Payment record for audit trails
                      final playerPayment = Payment(
                        amount: playerShare,
                        type: 'RSVP Fee Debit',
                        status: 'Completed',
                        user: updatedPlayer,
                      );
                      await Amplify.API
                          .mutate(request: ModelMutations.create(playerPayment))
                          .response;

                      // 8. Create RSVP record
                      final newRsvp = RSVP(
                        status: 'Going',
                        game: game,
                        user: updatedPlayer,
                      );

                      final rsvpResponse = await Amplify.API
                          .mutate(request: ModelMutations.create(newRsvp))
                          .response;

                      if (rsvpResponse.hasErrors) {
                        safePrint('RSVP errors: ${rsvpResponse.errors}');
                      } else {
                        safePrint(
                          'Successfully RSVPd and \$$playerShare deducted!',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are marked as GOING!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    } on ApiException catch (e) {
                      safePrint('RSVP Transaction failed: $e');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'GOING',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                  onPressed: () async {
                    try {
                      // 1. Fetch currently authenticated Cognito user
                      final authUser = await Amplify.Auth.getCurrentUser();
                      final userId = authUser.userId;

                      // 2. Fetch joining Player's profile directly
                      final userRequest = ModelQueries.get(
                        User.classType,
                        UserModelIdentifier(id: userId),
                      );
                      final userResponse = await Amplify.API
                          .query(request: userRequest)
                          .response;
                      final player = userResponse.data;

                      if (player == null) {
                        safePrint('Error: Player profile not found.');
                        return;
                      }

                      // 3. Create RSVP record for declining
                      final newRsvp = RSVP(
                        status: 'Not Going',
                        game: game,
                        user: player,
                      );

                      // 4. Save to DynamoDB
                      final request = ModelMutations.create(newRsvp);
                      final response = await Amplify.API
                          .mutate(request: request)
                          .response;

                      if (response.hasErrors) {
                        safePrint('RSVP Errors: ${response.errors}');
                      } else {
                        safePrint(
                          'RSVP NOT GOING recorded for ${player.name}!',
                        );

                        // 5. Display orange warning Snackbar
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You are marked as NOT GOING.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } on ApiException catch (e) {
                      safePrint('RSVP Mutation failed: $e');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'NOT GOING',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 32, color: Colors.black87),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
