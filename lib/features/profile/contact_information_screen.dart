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

  final TextEditingController _primaryEmailController = TextEditingController();
  final TextEditingController _phoneDisplayController = TextEditingController();

  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchContactData();
  }

  @override
  void dispose() {
    _primaryEmailController.dispose();
    _phoneDisplayController.dispose();
    super.dispose();
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

          if (_userProfile != null) {
            _primaryEmailController.text = _userProfile!.email;
            _phoneDisplayController.text =
                _phoneNumber ?? 'No phone number added';
          }
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
    String? newPrimaryEmail,
  }) async {
    if (_userProfile == null) return;

    try {
      final updatedUser = _userProfile!.copyWith(
        phoneNumber: newPhone ?? _phoneNumber,
        additionalEmails: newEmails ?? _additionalEmails,
        email: newPrimaryEmail ?? _userProfile!.email,
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

            if (_userProfile != null) {
              _primaryEmailController.text = _userProfile!.email;
              _phoneDisplayController.text =
                  _phoneNumber ?? 'No phone number added';
            }
          });
        }
      }
    } on ApiException catch (e) {
      safePrint('Update failed: $e');
    }
  }

  void _showChangePrimaryEmailModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, bottom: 16.0),
                  child: Text(
                    'SWITCH PRIMARY EMAIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if (_additionalEmails.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'You have no additional emails attached to your account to switch to.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: _deepBlack,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deepBlack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(modalContext);
                        _showAddEmailDialog();
                      },
                      child: const Text(
                        'ADD AN EMAIL',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ..._additionalEmails.map(
                    (email) => ListTile(
                      title: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: _deepBlack,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.swap_horiz,
                        size: 20,
                        color: _champagneGold,
                      ),
                      onTap: () async {
                        Navigator.pop(modalContext);

                        try {
                          setState(() => _isLoading = true);

                          // 1. Sync the new login email with Amazon Cognito
                          final result = await Amplify.Auth.updateUserAttribute(
                            userAttributeKey: AuthUserAttributeKey.email,
                            value: email,
                          );

                          // 2. Sync the profile change to Amazon DynamoDB
                          final newAdditional = List<String>.from(
                            _additionalEmails,
                          );
                          newAdditional.remove(email);
                          newAdditional.add(_userProfile!.email);
                          await _updateContactInfo(
                            newPrimaryEmail: email,
                            newEmails: newAdditional,
                          );

                          // 3. Handle the Cognito Verification Step
                          // 3. Handle the Cognito Verification Step
                          if (result.nextStep.updateAttributeStep ==
                              AuthUpdateAttributeStep
                                  .confirmAttributeWithCode) {
                            if (mounted) {
                              // Immediately launch the code input dialog
                              _showVerificationCodeDialog(email);
                            }
                          } else if (result.nextStep.updateAttributeStep ==
                              AuthUpdateAttributeStep.done) {
                            // Fallback if Cognito skips verification
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Login email updated automatically.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        } on AuthException catch (e) {
                          safePrint('Cognito update failed: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update login email.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showVerificationCodeDialog(String email) async {
    final TextEditingController codeController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) {
          return AlertDialog(
            backgroundColor: _crispWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            title: const Text(
              'VERIFY EMAIL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _champagneGold,
                letterSpacing: 1.5,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the 6-digit code sent to $email.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: _deepBlack,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  cursorColor: _champagneGold,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 22,
                    color: _deepBlack,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4.0,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4.0,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _champagneGold, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying
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
                  backgroundColor: _deepBlack,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: isVerifying
                    ? null
                    : () async {
                        final code = codeController.text.trim();
                        if (code.isEmpty) return;

                        // 1. Cache the Navigator and Messenger BEFORE the async gap
                        final navigator = Navigator.of(dialogContext);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        setDialogState(() => isVerifying = true);

                        try {
                          await Amplify.Auth.confirmUserAttribute(
                            userAttributeKey: AuthUserAttributeKey.email,
                            confirmationCode: code,
                          );

                          // 2. Use the cached variables safely (no mounted checks needed)
                          navigator.pop();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Login email successfully verified and updated!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on AuthException catch (e) {
                          safePrint('Verification failed: $e');
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Invalid code: ${e.message}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setDialogState(() => isVerifying = false);
                        }
                      },
                child: isVerifying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: _champagneGold,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'VERIFY',
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

  Widget _buildFieldCard({
    required String title,
    Widget? actionButton,
    required Widget child,
  }) {
    return Container(
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
              ?actionButton,
            ],
          ),
          const SizedBox(height: 16),
          child,
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
                _buildFieldCard(
                  title: 'PRIMARY EMAIL',
                  actionButton: TextButton(
                    onPressed: _showChangePrimaryEmailModal,
                    style: TextButton.styleFrom(
                      foregroundColor: _deepBlack,
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
                  child: Tooltip(
                    message: _primaryEmailController.text,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _deepBlack.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    waitDuration: const Duration(milliseconds: 400),
                    // Wrapped TextField in IgnorePointer so Tooltip catches the long-press
                    child: IgnorePointer(
                      child: TextField(
                        controller: _primaryEmailController,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: _deepBlack,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),

                _buildFieldCard(
                  title: 'ADDITIONAL EMAILS',
                  actionButton: TextButton(
                    onPressed: _showAddEmailDialog,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_additionalEmails.isEmpty)
                        const Text(
                          'No additional emails attached.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey,
                          ),
                        )
                      else
                        ..._additionalEmails.map(
                          (email) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Tooltip(
                              message: email,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _deepBlack.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              waitDuration: const Duration(milliseconds: 400),
                              child: IgnorePointer(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: email,
                                  ),
                                  readOnly: true,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w300,
                                    color: _deepBlack,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                _buildFieldCard(
                  title: 'PHONE NUMBER',
                  actionButton:
                      (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                      ? IconButton(
                          onPressed: _showPhoneOptionsModal,
                          icon: const Icon(Icons.more_horiz, color: _deepBlack),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : TextButton(
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
                  child: Tooltip(
                    message: _phoneDisplayController.text,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _deepBlack.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    waitDuration: const Duration(milliseconds: 400),
                    child: IgnorePointer(
                      child: TextField(
                        controller: _phoneDisplayController,
                        readOnly: true,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color:
                              (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                              ? _deepBlack
                              : Colors.grey.shade500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
