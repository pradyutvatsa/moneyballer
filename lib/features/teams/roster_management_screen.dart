import 'package:flutter/material.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/teams/team_details_screen.dart';

import 'dart:math';

class RosterManagementScreen extends StatefulWidget {
  const RosterManagementScreen({super.key});

  @override
  State<RosterManagementScreen> createState() => _RosterManagementScreenState();
}

class _RosterManagementScreenState extends State<RosterManagementScreen> {
  List<Team> _teams = [];
  bool _isLoading = true;

  // Premium Color Palette[cite: 15]
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final request = ModelQueries.list(Team.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('GraphQL Query errors: ${response.errors}');
      }

      final items = response.data?.items;

      if (items != null) {
        final fetchedTeams = items.whereType<Team>().toList();
        if (mounted) {
          setState(() {
            _teams = List<Team>.from(fetchedTeams);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _teams = [];
            _isLoading = false;
          });
        }
      }
    } on ApiException catch (e) {
      safePrint('Query failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateTeamDialog() async {
    final TextEditingController teamNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _crispWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ), // Clean geometric edges[cite: 15]
        title: const Text(
          'NEW TEAM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _champagneGold,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: teamNameController,
          cursorColor: _champagneGold,
          style: const TextStyle(
            fontSize: 18,
            color: _deepBlack,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'Enter team name',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w300,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _champagneGold, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () async {
              if (teamNameController.text.trim().isNotEmpty) {
                Navigator.pop(context); // Close dialog immediately
                await _createNewTeam(teamNameController.text.trim());
              }
            },
            child: const Text(
              'CREATE',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    final randomString = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    return 'SQUAD-$randomString';
  }

  Future<void> _createNewTeam(String name) async {
    setState(() => _isLoading = true);
    try {
      final uniqueCode = _generateInviteCode();

      // Pass the newly generated invite code to the updated Team model
      final newTeam = Team(name: name, inviteCode: uniqueCode);

      final request = ModelMutations.create(newTeam);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Create Team errors: ${response.errors}');
      } else {
        safePrint('Team successfully created with code: $uniqueCode');
        await _fetchTeams(); // Refresh the list
      }
    } on ApiException catch (e) {
      safePrint('Create Team failed: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showJoinSquadDialog() async {
    final TextEditingController codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'JOIN SQUAD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _champagneGold,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: codeController,
          cursorColor: _champagneGold,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 18,
            color: _deepBlack,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. SQUAD-X7B9',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w300,
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey, width: 0.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _champagneGold, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepBlack,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                await _joinSquad(code);
              }
            },
            child: const Text(
              'JOIN',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinSquad(String code) async {
    setState(() => _isLoading = true);
    try {
      // 1. Validate the invite code and find the Team
      final teamRequest = ModelQueries.list(
        Team.classType,
        where: Team.INVITECODE.eq(code),
      );
      final teamResponse = await Amplify.API
          .query(request: teamRequest)
          .response;
      final teams = teamResponse.data?.items.whereType<Team>().toList() ?? [];

      if (teams.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid invite code.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      final targetTeam = teams.first;

      // 2. Fetch authenticated Cognito User and DynamoDB User record
      final authUser = await Amplify.Auth.getCurrentUser();
      final userRequest = ModelQueries.get(
        User.classType,
        UserModelIdentifier(id: authUser.userId),
      );
      final userResponse = await Amplify.API
          .query(request: userRequest)
          .response;
      final currentUser = userResponse.data;

      if (currentUser == null) {
        safePrint('User profile not found.');
        setState(() => _isLoading = false);
        return;
      }

      // 3. Create the TeamMember relationship
      final newMember = TeamMember(user: currentUser, team: targetTeam);

      final joinRequest = ModelMutations.create(newMember);
      final joinResponse = await Amplify.API
          .mutate(request: joinRequest)
          .response;

      if (joinResponse.hasErrors) {
        safePrint('Join Team errors: ${joinResponse.errors}');
        setState(() => _isLoading = false);
      } else {
        safePrint('Successfully joined ${targetTeam.name}!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${targetTeam.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchTeams(); // Refresh the UI to display the newly joined team
      }
    } on ApiException catch (e) {
      safePrint('Join Squad failed: $e');
      setState(() => _isLoading = false);
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
          'ROSTER MANAGEMENT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: _deepBlack),
            onPressed: _showJoinSquadDialog,
            tooltip: 'Join Squad',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _champagneGold),
            )
          : RefreshIndicator(
              onRefresh: _fetchTeams,
              color: _champagneGold,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                children: [
                  const Text(
                    'Your Teams',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_teams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(
                        child: Text(
                          'No teams created yet.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  for (final team in _teams) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildTeamCard(team),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateTeamDialog,
        backgroundColor: _champagneGold,
        elevation: 0,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'New Team',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(Team team) {
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.grey.shade200,
          ), // Subtle stroke instead of shadow[cite: 15]
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
                    'TEAM ROSTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: _champagneGold,
            ),
          ],
        ),
      ),
    );
  }
}
