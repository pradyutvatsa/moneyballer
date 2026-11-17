import 'package:material_ui/material_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class ContactInformationScreen extends StatefulWidget {
  const ContactInformationScreen({super.key});

  @override
  State<ContactInformationScreen> createState() =>
      _ContactInformationScreenState();
}

class _ContactInformationScreenState extends State<ContactInformationScreen> {
  User? _userProfile;
  bool _isLoading = true;
  List<String> _additionalEmails = [];
  String? _phoneNumber;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchContactData();
  }

  Future<void> _fetchContactData() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();

      final request = ModelQueries.get(
        User.classType,
        UserModelIdentifier(id: authUser.userId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (mounted) {
        setState(() {
          _userProfile = response.data;
          _phoneNumber = _userProfile?.phoneNumber;
          _additionalEmails =
              _userProfile?.additionalEmails?.whereType<String>().toList() ??
              [];
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      safePrint('Error fetching contact info: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateContactInfo({
    String? newPhone,
    List<String>? newEmails,
  }) async {
    if (_userProfile == null) return;

    try {
      final updatedUser = _userProfile!.copyWith(
        phoneNumber: newPhone ?? _phoneNumber,
        additionalEmails: newEmails ?? _additionalEmails,
      );

      final request = ModelMutations.update(updatedUser);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Update errors: ${response.errors}');
      } else {
        if (mounted) {
          setState(() {
            _userProfile = response.data;
            _phoneNumber = _userProfile?.phoneNumber;
            _additionalEmails =
                _userProfile?.additionalEmails?.whereType<String>().toList() ??
                [];
          });
        }
      }
    } on ApiException catch (e) {
      safePrint('Update failed: $e');
    }
  }

  Future<void> _showEditPhoneDialog() async {
    final TextEditingController phoneController = TextEditingController(
      text: _phoneNumber,
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'PHONE NUMBER',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _champagneGold,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: phoneController,
          cursorColor: _champagneGold,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 18,
            color: _deepBlack,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: '+61 400 000 000',
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
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _updateContactInfo(newPhone: phoneController.text.trim());
            },
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEmailDialog() async {
    final TextEditingController emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _crispWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'ADD EMAIL',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _champagneGold,
            letterSpacing: 1.5,
          ),
        ),
        content: TextField(
          controller: emailController,
          cursorColor: _champagneGold,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(
            fontSize: 18,
            color: _deepBlack,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: 'player@example.com',
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
            ),
            onPressed: () async {
              if (emailController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final updatedList = List<String>.from(_additionalEmails)
                  ..add(emailController.text.trim());
                await _updateContactInfo(newEmails: updatedList);
              }
            },
            child: const Text(
              'ADD',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoneOptionsModal() {
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
                    Icons.phone_android_outlined,
                    color: _deepBlack,
                  ),
                  title: const Text(
                    'CHANGE PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _deepBlack,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditPhoneDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'REMOVE PHONE NUMBER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                      letterSpacing: 1.5,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateContactInfo(newPhone: '');
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: _deepBlack,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'CONTACT INFO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ), // Thin typography
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
                'Contact data not found.',
                style: TextStyle(color: _deepBlack),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // Clean geometric edges[cite: 12]
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ), // Subtle stroke[cite: 12]
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRIMARY EMAIL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _champagneGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _userProfile!.email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: _deepBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: _additionalEmails.isNotEmpty
                                ? () => safePrint('Change email logic')
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: _deepBlack,
                              disabledForegroundColor: Colors.grey.shade400,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'CHANGE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_additionalEmails.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'ADDITIONAL EMAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _champagneGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._additionalEmails.map(
                          (email) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              email,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: _deepBlack,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _showAddEmailDialog,
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
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'ADD EMAIL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFEEEEEE),
                        ),
                      ),

                      const Text(
                        'PHONE NUMBER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _champagneGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                                  ? _phoneNumber!
                                  : 'No phone number added',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color:
                                    (_phoneNumber != null &&
                                        _phoneNumber!.isNotEmpty)
                                    ? _deepBlack
                                    : Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                            IconButton(
                              onPressed: _showPhoneOptionsModal,
                              icon: const Icon(
                                Icons.more_horiz,
                                color: _deepBlack,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          else
                            TextButton(
                              onPressed: _showEditPhoneDialog,
                              style: TextButton.styleFrom(
                                foregroundColor: _deepBlack,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
