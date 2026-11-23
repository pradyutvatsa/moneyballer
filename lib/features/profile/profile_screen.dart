import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/scheduling/financial_dashboard_screen.dart';
import 'package:moneyballer/features/profile/contact_information_screen.dart';
import 'package:moneyballer/features/profile/profile_and_account_screen.dart';
import 'package:moneyballer/features/profile/my_squads_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _userProfile;
  bool _isLoading = true;
  File? _localProfileImage;
  String? _cloudProfileImageUrl;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();

      final request = ModelQueries.get(
        User.classType,
        UserModelIdentifier(id: authUser.userId),
      );
      final response = await Amplify.API.query(request: request).response;

      String? fetchedImageUrl;
      try {
        final urlResult = await Amplify.Storage.getUrl(
          path: StoragePath.fromString(
            'profile-pictures/${authUser.userId}/profile.jpg',
          ),
        ).result;
        fetchedImageUrl = urlResult.url.toString();
      } on StorageException catch (e) {
        safePrint('No cloud profile photo found: $e');
      }

      if (mounted) {
        setState(() {
          _userProfile = response.data;
          _cloudProfileImageUrl = fetchedImageUrl;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      safePrint('Error fetching user profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
    } on Exception catch (e) {
      safePrint('Error signing out: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      setState(() {
        _localProfileImage = File(pickedFile.path);
      });
      try {
        final authUser = await Amplify.Auth.getCurrentUser();
        final awsFile = AWSFile.fromPath(pickedFile.path);
        final uploadPath = StoragePath.fromString(
          'profile-pictures/${authUser.userId}/profile.jpg',
        );
        await Amplify.Storage.uploadFile(
          localFile: awsFile,
          path: uploadPath,
        ).result;
        safePrint('Successfully uploaded photo to S3!');
      } on Exception catch (e) {
        safePrint('Error uploading photo to S3: $e');
      }
    }
  }

  void _showPhotoOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: _deepBlack,
                  ),
                  title: const Text(
                    'TAKE PHOTO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _deepBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: _deepBlack,
                  ),
                  title: const Text(
                    'CHOOSE PHOTO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _deepBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
        title: const Text(
          'PROFILE',
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
          : _userProfile == null
          ? const Center(
              child: Text(
                'Profile not found in database.',
                style: TextStyle(color: _deepBlack),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 120,
                        height: 150,
                        decoration: BoxDecoration(
                          color: _deepBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _champagneGold.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: _localProfileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.file(
                                  _localProfileImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : _cloudProfileImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _cloudProfileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Center(
                                    child: Text(
                                      _userProfile!.name.isNotEmpty
                                          ? _userProfile!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w300,
                                        fontSize: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  _userProfile!.name.isNotEmpty
                                      ? _userProfile!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        top: -12,
                        right: -12,
                        child: GestureDetector(
                          onTap: _showPhotoOptionsModal,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: _crispWhite,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: _champagneGold,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: _deepBlack,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    _userProfile!.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Standard Menu Cards
                _buildActionCard(
                  title: 'Contact Information',
                  icon: Icons.contact_mail_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactInformationScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  title: 'Profile and Account',
                  icon: Icons.person_outline,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileAndAccountScreen(),
                      ),
                    );
                    _fetchUserProfile();
                  },
                ),
                _buildActionCard(
                  title: 'My Squads',
                  icon: Icons.group_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MySquadsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  title: 'Payments',
                  icon: Icons.payment_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FinancialDashboardScreen(),
                    ),
                  ),
                ),
                _buildActionCard(
                  title: 'Notification',
                  icon: Icons.notifications_outlined,
                  onTap: () {},
                ),
                _buildActionCard(
                  title: 'Calendar Settings',
                  icon: Icons.calendar_today_outlined,
                  onTap: () {},
                ),
                _buildActionCard(
                  title: 'Help Centre',
                  icon: Icons.help_outline,
                  onTap: () {},
                ),
                _buildActionCard(
                  title: 'Recommend MoneyBaller',
                  icon: Icons.thumb_up_outlined,
                  onTap: () {},
                ),
                _buildActionCard(
                  title: 'Terms and Legal',
                  icon: Icons.gavel_outlined,
                  onTap: () {},
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlack,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _signOut,
                  child: const Text(
                    'LOG OUT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: _deepBlack),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _deepBlack,
                  letterSpacing: 1.5,
                ),
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
