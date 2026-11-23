import 'package:material_ui/material_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/teams/team_details_screen.dart';

class MySquadsScreen extends StatefulWidget {
  const MySquadsScreen({super.key});

  @override
  State<MySquadsScreen> createState() => _MySquadsScreenState();
}

class _MySquadsScreenState extends State<MySquadsScreen> {
  List<Team> _mySquads = [];
  bool _isLoading = true;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchUserSquads();
  }

  Future<void> _fetchUserSquads() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // 1. Get the currently authenticated user
      final authUser = await Amplify.Auth.getCurrentUser();

      // 2. Query TeamMember records matching this user[cite: 1]
      final request = ModelQueries.list(
        TeamMember.classType,
        where: TeamMember.USER.eq(authUser.userId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('Squads Query errors: ${response.errors}');
      }

      // 3. Extract the Team objects from the join records[cite: 1]
      final items = response.data?.items ?? [];
      final fetchedTeams = items
          .whereType<TeamMember>()
          .map((member) => member.team)
          .whereType<Team>()
          .toList();

      if (mounted) {
        setState(() {
          _mySquads = fetchedTeams;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      safePrint('Failed to fetch user squads: $e');
      if (mounted) setState(() => _isLoading = false);
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: _deepBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MY SQUADS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _champagneGold),
            )
          : RefreshIndicator(
              onRefresh: _fetchUserSquads,
              color: _champagneGold,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                children: [
                  if (_mySquads.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Text(
                          'You are not part of any squads yet.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final team in _mySquads) _buildSquadCard(team),
                ],
              ),
            ),
    );
  }

  Widget _buildSquadCard(Team team) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailsScreen(team: team),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SQUAD',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: _champagneGold,
            ),
          ],
        ),
      ),
    );
  }
}
