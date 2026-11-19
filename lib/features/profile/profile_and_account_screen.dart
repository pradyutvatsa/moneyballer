import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class ProfileAndAccountScreen extends StatefulWidget {
  const ProfileAndAccountScreen({super.key});

  @override
  State<ProfileAndAccountScreen> createState() =>
      _ProfileAndAccountScreenState();
}

class _ProfileAndAccountScreenState extends State<ProfileAndAccountScreen> {
  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  // Backend & UI State
  User? _userProfile;
  bool _isLoading = true;
  File? _localProfileImage;
  String? _cloudProfileImageUrl;

  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  DateTime _birthDate = DateTime(1990, 1, 1);
  String _gender = 'Male';
  final String _country = 'Australia';
  final String _timeZone = 'AEST (Sydney)';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 1. Fetch User Profile & S3 Photo from AWS
  Future<void> _fetchUserData() async {
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

          if (_userProfile != null) {
            // Fallback to splitting the legacy 'name' field if firstName isn't populated yet
            if (_userProfile!.firstName != null &&
                _userProfile!.firstName!.isNotEmpty) {
              _firstName = _userProfile!.firstName!;
              _middleName = _userProfile!.middleName ?? '';
              _lastName = _userProfile!.lastName ?? '';
            } else {
              final parts = _userProfile!.name.split(' ');
              _firstName = parts.isNotEmpty ? parts.first : '';
              _lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            }

            if (_userProfile!.birthDate != null) {
              _birthDate = _userProfile!.birthDate!.getDateTime();
            }

            if (_userProfile!.gender != null &&
                _userProfile!.gender!.isNotEmpty) {
              _gender = _userProfile!.gender!;
            }
          }
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      safePrint('Error fetching user profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Execute ModelMutations.update() to sync changes to DynamoDB
  Future<void> _updateUserProfile({
    String? newFirst,
    String? newMiddle,
    String? newLast,
    DateTime? newBirthDate,
    String? newGender,
  }) async {
    if (_userProfile == null) return;

    final updatedFirst = newFirst ?? _firstName;
    final updatedMiddle = newMiddle ?? _middleName;
    final updatedLast = newLast ?? _lastName;
    final updatedBirthDate = newBirthDate ?? _birthDate;
    final updatedGender = newGender ?? _gender;

    // Keep the legacy full 'name' field synced for other screens
    final combinedFullName = updatedMiddle.isEmpty
        ? '$updatedFirst $updatedLast'.trim()
        : '$updatedFirst $updatedMiddle $updatedLast'.trim();

    try {
      final updatedUser = _userProfile!.copyWith(
        name: combinedFullName.isNotEmpty
            ? combinedFullName
            : _userProfile!.name,
        firstName: updatedFirst,
        middleName: updatedMiddle,
        lastName: updatedLast,
        birthDate: TemporalDate(updatedBirthDate),
        gender: updatedGender,
      );

      final request = ModelMutations.update(updatedUser);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Update errors: ${response.errors}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save changes.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _userProfile = response.data;
            _firstName = updatedFirst;
            _middleName = updatedMiddle;
            _lastName = updatedLast;
            _birthDate = updatedBirthDate;
            _gender = updatedGender;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated.'),
              backgroundColor: _deepBlack,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      safePrint('Mutation failed: $e');
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  String _buildFullName() {
    if (_firstName.isEmpty && _lastName.isEmpty) {
      return _userProfile?.name.toUpperCase() ?? 'ADD NAME';
    }
    if (_middleName.isEmpty) {
      return '$_firstName $_lastName'.toUpperCase();
    }
    return '$_firstName $_middleName $_lastName'.toUpperCase();
  }

  // Birth Date Rolodex Modal wired to SAVE
  void _showBirthDateModal() {
    DateTime tempDate = _birthDate;
    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateUserProfile(newBirthDate: tempDate);
                        },
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            color: _deepBlack,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _birthDate,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Gender Picker Modal wired to SAVE
  void _showGenderModal() {
    String tempGender = _gender;
    final List<String> genderOptions = ['Male', 'Female'];

    int initialIndex = genderOptions.indexOf(_gender);
    if (initialIndex < 0) initialIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 250,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _updateUserProfile(newGender: tempGender);
                        },
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            color: _deepBlack,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFEEEEEE),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (int index) {
                      tempGender = genderOptions[index];
                    },
                    children: genderOptions
                        .map(
                          (g) => Center(
                            child: Text(
                              g,
                              style: const TextStyle(
                                fontSize: 18,
                                color: _deepBlack,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _champagneGold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: _champagneGold,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: _deepBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initialLetter = _firstName.isNotEmpty
        ? _firstName[0].toUpperCase()
        : (_userProfile?.name.isNotEmpty == true
              ? _userProfile!.name[0].toUpperCase()
              : '?');

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
          'PROFILE & ACCOUNT',
          style: TextStyle(
            fontSize: 18,
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
                // Current Image & Action Button
                Center(
                  child: Column(
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        initialLetter,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
                                child: Text(
                                  initialLetter,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          safePrint('Change profile picture tapped');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _deepBlack,
                          side: const BorderSide(color: _deepBlack, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                        ),
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: const Text(
                          'CHANGE PROFILE PICTURE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Full Name Card wired to NameEditScreen & SAVE
                _buildFieldCard(
                  title: 'FULL NAME',
                  value: _buildFullName(),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NameEditScreen(
                          initialFirst: _firstName,
                          initialMiddle: _middleName,
                          initialLast: _lastName,
                        ),
                      ),
                    );
                    if (result != null && result is Map<String, String>) {
                      await _updateUserProfile(
                        newFirst: result['first']!,
                        newMiddle: result['middle']!,
                        newLast: result['last']!,
                      );
                    }
                  },
                ),

                _buildFieldCard(
                  title: 'BIRTH DATE',
                  value: _formatDate(_birthDate),
                  onTap: _showBirthDateModal,
                ),

                _buildFieldCard(
                  title: 'GENDER',
                  value: _gender,
                  onTap: _showGenderModal,
                ),

                _buildFieldCard(
                  title: 'COUNTRY OR REGION',
                  value: _country,
                  onTap: () {},
                ),

                _buildFieldCard(
                  title: 'TIME ZONE',
                  value: _timeZone,
                  onTap: () {},
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32.0),
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Text(
                      'DELETE ACCOUNT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ============================================================================
// DEDICATED NAME EDIT SCREEN
// ============================================================================

class NameEditScreen extends StatefulWidget {
  final String initialFirst;
  final String initialMiddle;
  final String initialLast;

  const NameEditScreen({
    super.key,
    required this.initialFirst,
    required this.initialMiddle,
    required this.initialLast,
  });

  @override
  State<NameEditScreen> createState() => _NameEditScreenState();
}

class _NameEditScreenState extends State<NameEditScreen> {
  late TextEditingController _firstController;
  late TextEditingController _middleController;
  late TextEditingController _lastController;

  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(text: widget.initialFirst);
    _middleController = TextEditingController(text: widget.initialMiddle);
    _lastController = TextEditingController(text: widget.initialLast);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _middleController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  void _saveName() {
    if (_firstController.text.trim().isEmpty ||
        _lastController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First and Last name are mandatory.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'first': _firstController.text.trim(),
      'middle': _middleController.text.trim(),
      'last': _lastController.text.trim(),
    });
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isMandatory,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _champagneGold,
                  letterSpacing: 1.5,
                ),
              ),
              if (isMandatory)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            cursorColor: _champagneGold,
            style: const TextStyle(
              fontSize: 18,
              color: _deepBlack,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _champagneGold, width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              isDense: true,
            ),
          ),
        ],
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
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            const Text(
              'EDIT NAME',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
                color: _deepBlack,
              ),
            ),
            TextButton(
              onPressed: _saveName,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  color: _deepBlack,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTextField('FIRST NAME', _firstController, true),
                _buildTextField('MIDDLE NAME', _middleController, false),
                _buildTextField('LAST NAME', _lastController, true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
