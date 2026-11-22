import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:country_picker/country_picker.dart';
import 'package:moneyballer/common/utils/country_timezones.dart';
import 'package:moneyballer/models/ModelProvider.dart';
import 'package:image_picker/image_picker.dart';

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
  String _country = 'Australia';
  String _timeZone = 'Australia/Sydney (UTC+11:00)';

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

            if (_userProfile!.country != null &&
                _userProfile!.country!.isNotEmpty) {
              _country = _userProfile!.country!;
            }

            if (_userProfile!.timeZone != null &&
                _userProfile!.timeZone!.isNotEmpty) {
              _timeZone = _userProfile!.timeZone!;
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

  // Show Take Photo / Choose Photo Bottom Sheet
  void _showPhotoOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (modalContext) {
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
                    Navigator.pop(modalContext);
                    _pickAndUploadImage(ImageSource.camera);
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
                    Navigator.pop(modalContext);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pick image from Camera/Gallery and upload to S3
  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    setState(() {
      _localProfileImage = File(pickedFile.path);
    });

    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final awsFile = AWSFile.fromPath(pickedFile.path);
      final uploadPath = StoragePath.fromString(
        'profile-pictures/${authUser.userId}/profile.jpg',
      );

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: awsFile,
        path: uploadPath,
      ).result;

      safePrint(
        'Successfully uploaded photo to S3: ${uploadResult.uploadedItem.path}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated.'),
            backgroundColor: _deepBlack,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on Exception catch (e) {
      safePrint('Error uploading photo to S3: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload profile picture.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 2. Execute ModelMutations.update() to sync changes to DynamoDB
  Future<void> _updateUserProfile({
    String? newFirst,
    String? newMiddle,
    String? newLast,
    DateTime? newBirthDate,
    String? newGender,
    String? newCountry,
    String? newTimeZone,
  }) async {
    if (_userProfile == null) return;

    final updatedFirst = newFirst ?? _firstName;
    final updatedMiddle = newMiddle ?? _middleName;
    final updatedLast = newLast ?? _lastName;
    final updatedBirthDate = newBirthDate ?? _birthDate;
    final updatedGender = newGender ?? _gender;
    final updatedCountry = newCountry ?? _country;
    final updatedTimeZone = newTimeZone ?? _timeZone;

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
        country: updatedCountry,
        timeZone: updatedTimeZone,
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
            _country = updatedCountry;
            _timeZone = updatedTimeZone;
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

  // 3. Country Picker Modal + Confirmation Dialog
  void _showCountryPickerModal() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: _crispWhite,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.75,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16,
          color: _deepBlack,
          fontWeight: FontWeight.w400,
        ),
        searchTextStyle: const TextStyle(fontSize: 16, color: _deepBlack),
      ),
      onSelect: (Country country) {
        if (country.name != _country) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showCountryConfirmationDialog(country.name);
            }
          });
        }
      },
    );
  }

  Future<void> _showCountryConfirmationDialog(String selectedCountry) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'CONFIRM COUNTRY',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _champagneGold,
            letterSpacing: 1.5,
          ),
        ),
        content: Text(
          'Are you sure you want to update your country or region to $selectedCountry?',
          style: const TextStyle(
            fontSize: 16,
            color: _deepBlack,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
              Navigator.pop(dialogContext);
              // Only updates country; last selected _timeZone stays intact unless user opens Time Zone card
              await _updateUserProfile(newCountry: selectedCountry);
            },
            child: const Text(
              'CONFIRM',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Time Zone Picker Modal filtered by currently selected Country
  void _showTimeZonePickerModal() {
    final List<String> countryTimeZones =
        CountryTimezoneHelper.getTimezonesForCountryName(_country);

    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TIME ZONES IN ${_country.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _champagneGold,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(modalContext),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.grey,
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
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: countryTimeZones.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFFEEEEEE),
                      indent: 24,
                      endIndent: 24,
                    ),
                    itemBuilder: (context, index) {
                      final zone = countryTimeZones[index];
                      final isSelected = zone == _timeZone;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          zone,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w300,
                            color: _deepBlack,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: _champagneGold,
                                size: 20,
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(modalContext);
                          if (zone != _timeZone) {
                            await _updateUserProfile(newTimeZone: zone);
                          }
                        },
                      );
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

  // 5. Delete Account Confirmation Dialog ("CONFIRM DELETE")
  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController confirmController = TextEditingController();
    bool isProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) {
          final bool isMatch =
              confirmController.text.trim().toUpperCase() == 'CONFIRM DELETE';

          return AlertDialog(
            backgroundColor: _crispWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: const Text(
              'DELETE ACCOUNT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red,
                letterSpacing: 1.5,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your account will be disabled immediately and permanently purged from our database in 7 days.\n\nType CONFIRM DELETE below to proceed:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: _deepBlack,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  cursorColor: Colors.red,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setDialogState(() {}),
                  style: const TextStyle(
                    fontSize: 16,
                    color: _deepBlack,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CONFIRM DELETE',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () => Navigator.pop(dialogContext),
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: (!isMatch || isProcessing)
                    ? null
                    : () async {
                        final navigator = Navigator.of(dialogContext);
                        final rootNavigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        setDialogState(() => isProcessing = true);

                        try {
                          if (_userProfile != null) {
                            final purgeDate = DateTime.now().toUtc().add(
                              const Duration(days: 7),
                            );
                            final disabledUser = _userProfile!.copyWith(
                              accountStatus: 'PENDING_DELETION',
                              scheduledDeletionAt: TemporalDateTime(purgeDate),
                            );

                            final response = await Amplify.API
                                .mutate(
                                  request: ModelMutations.update(disabledUser),
                                )
                                .response;

                            if (response.hasErrors) {
                              throw Exception(response.errors.first.message);
                            }
                          }

                          navigator.pop();
                          rootNavigator.popUntil((route) => route.isFirst);
                          await Amplify.Auth.signOut();
                        } on Exception catch (e) {
                          safePrint('Account deletion scheduling failed: $e');
                          setDialogState(() => isProcessing = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to schedule deletion: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'DELETE',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
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
                        onPressed: _showPhotoOptionsModal,
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

                // Full Name Card
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
                  onTap: _showCountryPickerModal,
                ),

                // Time Zone Card wired to Country-Filtered Picker
                _buildFieldCard(
                  title: 'TIME ZONE',
                  value: _timeZone,
                  onTap: _showTimeZonePickerModal,
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32.0),
                  child: TextButton(
                    onPressed: _showDeleteAccountDialog,
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
