import 'package:flutter/material.dart';
//import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/scheduling/create_game_screen.dart';
import 'package:moneyballer/features/scheduling/event_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Game> _games = [];
  bool _isLoading = true;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      final request = ModelQueries.list(Game.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('GraphQL Query errors: ${response.errors}');
      }

      final items = response.data?.items;

      if (items != null) {
        final fetchedGames = items.whereType<Game>().toList();

        if (mounted) {
          setState(() {
            _games = List<Game>.from(fetchedGames);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _games = [];
            _isLoading = false;
          });
        }
      }
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crispWhite,
      appBar: AppBar(
        backgroundColor: _crispWhite,
        elevation: 0,
        foregroundColor: _deepBlack,
        title: const Text(
          'MoneyBaller',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22, color: _champagneGold),
            onPressed: () async {
              try {
                await Amplify.Auth.signOut();
              } catch (e) {
                safePrint('Error signing out: $e');
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _champagneGold),
            )
          : RefreshIndicator(
              onRefresh: _fetchGames,
              color: _champagneGold,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                children: [
                  const Text(
                    'Upcoming Games',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_games.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Text(
                          'No games scheduled yet.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  for (final game in _games) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 24.0,
                      ), // Generous whitespace
                      child: _buildEventCard(
                        game: game,
                        title: 'Game Session (${game.maxPlayers} Max)',
                        date:
                            '${game.date.format()} at ${game.time.format().substring(0, 5)}',
                        location: game.location,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const CreateGameScreen()),
          );
          await _fetchGames();
        },
        backgroundColor: _champagneGold,
        elevation: 0, // Flat styling
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Create Game',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required Game game,
    required String title,
    required String date,
    required String location,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(game: game),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4), // Clean geometric edges
          border: Border.all(
            color: Colors.grey.shade200,
          ), // Subtle stroke instead of shadow
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _champagneGold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: _deepBlack,
                ),
                const SizedBox(width: 16),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _deepBlack,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: _deepBlack,
                ),
                const SizedBox(width: 16),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 18,
                    color: _deepBlack,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
