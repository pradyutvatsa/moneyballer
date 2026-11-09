import 'package:flutter/material.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class EventDetailsScreen extends StatelessWidget {
  final Game game;

  const EventDetailsScreen({super.key, required this.game});

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crispWhite,
      appBar: AppBar(
        backgroundColor: _crispWhite,
        elevation: 0,
        foregroundColor: _deepBlack,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: _deepBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Event Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        children: [
          Text(
            'Game Session'.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _champagneGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${game.maxPlayers} Max Players',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: _deepBlack,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 48),

          _buildInfoRow(Icons.calendar_today_outlined, game.date.format()),
          _buildInfoRow(Icons.access_time, game.time.format().substring(0, 5)),
          _buildInfoRow(Icons.location_on_outlined, game.location),

          const SizedBox(height: 24),
          const Divider(color: Colors.grey, thickness: 0.5, height: 60),

          Text(
            'RSVP STATUS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _champagneGold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // RSVP Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () async {
                    // 1. Calculate player's equal share of the upfront fee
                    final double playerShare = game.maxPlayers > 0
                        ? (game.appFee) / game.maxPlayers
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
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GOING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: _deepBlack,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: _champagneGold, width: 1.5),
                    ),
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
                    padding: EdgeInsets.symmetric(vertical: 22),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'NOT GOING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                        maxLines: 1,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: _champagneGold),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: _deepBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
