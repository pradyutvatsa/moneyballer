import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  List<TeamMember> _roster = [];
  bool _isLoading = true;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchRoster();
  }

  Future<void> _fetchRoster() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Query using the relational .TEAM getter instead of the hidden .TEAMID
      final request = ModelQueries.list(
        TeamMember.classType,
        where: TeamMember.TEAM.eq(widget.team.id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('Roster Query errors: ${response.errors}');
      }

      final items = response.data?.items;
      if (items != null) {
        final fetchedMembers = items.whereType<TeamMember>().toList();
        if (mounted) {
          setState(() {
            _roster = fetchedMembers;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _roster = [];
            _isLoading = false;
          });
        }
      }
    } on ApiException catch (e) {
      safePrint('Fetch Roster failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareInviteCode() {
    final code = widget.team.inviteCode ?? 'No code available';
    final shareText =
        'Join my squad "${widget.team.name}" on MoneyBaller! Use invite code: $code \n\nDownload the app to get started.';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: 'You are invited to join ${widget.team.name}!',
      ),
    );
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
        title: Text(
          widget.team.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRoster,
        color: _champagneGold,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          children: [
            // Invite Code Display Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _champagneGold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 32.0,
                horizontal: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'SQUAD INVITE CODE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.team.inviteCode ?? 'PENDING',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: _deepBlack,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _deepBlack,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 32.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: _shareInviteCode,
                    icon: const Icon(Icons.ios_share, size: 20),
                    label: const Text(
                      'SHARE LINK',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            const Text(
              'Active Roster',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: _deepBlack,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Roster Rendering
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Center(
                  child: CircularProgressIndicator(color: _champagneGold),
                ),
              )
            else if (_roster.isEmpty)
              const Text(
                'No players have joined yet. Share your code above to build your squad.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey,
                  height: 1.5,
                ),
              )
            else
              for (final member in _roster) _buildPlayerCard(member),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(TeamMember member) {
    // Gracefully handle nested User parsing
    final playerName = member.user?.name ?? 'Player (Syncing)';
    final initial = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _deepBlack,
            foregroundColor: Colors.white,
            radius: 20,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              playerName,
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
