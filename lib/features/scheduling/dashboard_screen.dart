import 'package:flutter/material.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/scheduling/create_game_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Game> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final request = ModelQueries.list(Game.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('GraphQL Query errors: ${response.errors}');
      }

      final items = response.data?.items;
      safePrint('Raw items received: ${items?.length}');

      if (items != null) {
        final fetchedGames = items.whereType<Game>().toList();
        safePrint('Parsed ${fetchedGames.length} valid games!');

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'MoneyBaller',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: const [SignOutButton()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _fetchGames,
              color: Colors.black,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Upcoming Games',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_games.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Text(
                          'No games scheduled yet.',
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  for (final game in _games) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildEventCard(
                        title: 'Game (${game.maxPlayers} Max)',
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
        onPressed: () async {
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const CreateGameScreen()),
          );
          await _fetchGames();
        },
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Create Game',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String location,
  }) {
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 24,
                  color: Colors.black87,
                ),
                const SizedBox(width: 12),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 24, color: Colors.black87),
                const SizedBox(width: 12),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
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
