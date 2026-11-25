import 'package:material_ui/material_ui.dart';
//import 'package:flutter/services.dart';
//import 'package:share_plus/share_plus.dart';
//import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/scheduling/create_game_screen.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Team team;

  const TeamDetailsScreen({super.key, required this.team});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  String? _currentUserId;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  bool get _isOrganizer =>
      _currentUserId != null && _currentUserId == widget.team.organizerId;

  Future<void> _loadCurrentUser() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = authUser.userId;
        });
      }
    } catch (e) {
      safePrint('Error fetching auth user: $e');
    }
  }

  // Empty dropdown modal sliding down from the top (40% of screen height)
  void _showSquadDropdownModal() {
    final double modalHeight = MediaQuery.of(context).size.height * 0.40;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss squad dropdown',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: _crispWhite,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.infinity,
              height: modalHeight,
              // Intentionally left empty for now
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(0.0, -1.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _onTopRightPlusTapped() {
    if (_isOrganizer) {
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CreateGameScreen(initialTeam: widget.team),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bannerHeight = MediaQuery.of(context).size.height * 0.25;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: _crispWhite,
        body: Column(
          children: [
            // 1. Full-bleed Top Image Banner (25% of screen height, zero side margins)
            SizedBox(
              width: double.infinity,
              height: bannerHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Squad Banner Background (Replace with Image.network when S3 squad images are added)
                  Container(
                    decoration: const BoxDecoration(
                      color: _deepBlack,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1C1C1C), Color(0xFF0F0F0F)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 56,
                        color: _champagneGold.withValues(alpha: 0.25),
                      ),
                    ),
                  ),

                  // Top Controls Overlay (Back button, Centered Squad Name, Bold + Button)
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Back navigation button
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 20,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),

                            // 2. Top-Center Squad Name (Tappable for empty dropdown modal)
                            Expanded(
                              child: GestureDetector(
                                onTap: _showSquadDropdownModal,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.team.name.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                      color: _champagneGold,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 3. Top-Right Action Button denoted by bold '+' icon
                            IconButton(
                              onPressed: _onTopRightPlusTapped,
                              tooltip: 'Add',
                              icon: const Icon(
                                Icons.add,
                                size: 28,
                                weight: 800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Navigation Bar directly underneath the squad image
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
              ),
              child: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: _champagneGold,
                indicatorWeight: 2.5,
                labelColor: _deepBlack,
                unselectedLabelColor: Colors.grey,
                labelPadding: EdgeInsets.symmetric(horizontal: 18.0),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
                tabs: [
                  Tab(text: 'EVENTS'),
                  Tab(text: 'POSTS'),
                  Tab(text: 'PAYMENTS'),
                  Tab(text: 'POLLS'),
                  Tab(text: 'FILES'),
                ],
              ),
            ),

            // Tab Views Body
            Expanded(
              child: TabBarView(
                children: [
                  _buildPlaceholderTab('Events'),
                  _buildPlaceholderTab('Posts'),
                  _buildPlaceholderTab('Payments'),
                  _buildPlaceholderTab('Polls'),
                  _buildPlaceholderTab('Files'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String tabName) {
    return Center(
      child: Text(
        '$tabName coming soon',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w300,
          color: Colors.grey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
