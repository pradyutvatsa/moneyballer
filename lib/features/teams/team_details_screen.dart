import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:flutter/services.dart'; // Add at top of team_details_screen.dart
import 'package:moneyballer/features/scheduling/create_game_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  List<TeamMember> _roster = [];
  bool _isLoading = true;
  String? _currentUserId; // Tracks logged-in user to verify organizer status

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndRoster();
  }

  Future<void> _loadCurrentUserAndRoster() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = authUser.userId;
        });
      }
    } on AuthException catch (e) {
      safePrint('Auth fetch failed: $e');
    }
    await _fetchRoster();
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
        // Pin the squad organizer to the top of the roster
        fetchedMembers.sort((a, b) {
          final aIsOrg = a.user?.id == widget.team.organizerId;
          final bIsOrg = b.user?.id == widget.team.organizerId;
          if (aIsOrg && !bIsOrg) return -1;
          if (!aIsOrg && bIsOrg) return 1;
          return 0;
        });
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
    final bool isOrganizer =
        _currentUserId != null && _currentUserId == widget.team.organizerId;

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          children: [
            // Compact Invite Code Card — Visible ONLY to the Squad Organizer
            if (isOrganizer) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _champagneGold.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 18.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVITE CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _champagneGold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.team.inviteCode ?? 'PENDING',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: _deepBlack,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _deepBlack,
                        side: const BorderSide(color: _deepBlack, width: 1.0),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 12.0,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: _shareInviteCode,
                      icon: const Icon(Icons.ios_share, size: 14),
                      label: const Text(
                        'SHARE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            const Text(
              'Active Roster',
              style: TextStyle(
                fontSize: 22,
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
                'No players have joined yet.',
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
      floatingActionButton: isOrganizer
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateGameScreen(initialTeam: widget.team),
                  ),
                );
                if (created == true) {
                  _fetchRoster();
                }
              },
              backgroundColor: _deepBlack,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.event_available, size: 20),
              label: const Text(
                'Schedule Game',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPlayerCard(TeamMember member) {
    final playerName = member.user?.name ?? 'Player (Syncing)';
    final initial = playerName.isNotEmpty ? playerName[0].toUpperCase() : '?';
    final payId = member.user?.payId;
    final payIdType = member.user?.payIdType;
    final hasPayId = payId != null && payId.isNotEmpty;
    final isSquadOrganizer =
        member.user?.id != null && member.user!.id == widget.team.organizerId;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        playerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: _deepBlack,
                        ),
                      ),
                    ),
                    if (isSquadOrganizer) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _champagneGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _champagneGold, width: 0.8),
                        ),
                        child: const Text(
                          'ORGANISER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: _champagneGold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasPayId
                      ? 'PayID (${payIdType ?? 'AU'}): $payId'
                      : 'PayID not set',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: hasPayId ? _champagneGold : Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (hasPayId)
            IconButton(
              icon: const Icon(
                Icons.copy_outlined,
                size: 18,
                color: _deepBlack,
              ),
              tooltip: 'Copy PayID',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: payId));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $playerName\'s PayID: $payId'),
                    backgroundColor: _deepBlack,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
