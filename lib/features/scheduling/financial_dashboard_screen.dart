import 'package:material_ui/material_ui.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class FinancialDashboardScreen extends StatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  State<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState extends State<FinancialDashboardScreen> {
  User? _currentUser;
  List<Payment> _transactions = [];
  bool _isLoading = true;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _fetchFinancialData();
  }

  Future<void> _fetchFinancialData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      final authUser = await Amplify.Auth.getCurrentUser();

      // 1. Fetch live wallet balance and PayID details from the User record
      final userRequest = ModelQueries.get(
        User.classType,
        UserModelIdentifier(id: authUser.userId),
      );
      final userResponse = await Amplify.API
          .query(request: userRequest)
          .response;
      final fetchedUser = userResponse.data;

      // 2. Fetch all Payment records linked to this user
      final paymentRequest = ModelQueries.list(
        Payment.classType,
        where: Payment.USER.eq(authUser.userId),
      );
      final paymentResponse = await Amplify.API
          .query(request: paymentRequest)
          .response;

      final items = paymentResponse.data?.items;
      final fetchedPayments = items?.whereType<Payment>().toList() ?? [];

      fetchedPayments.sort(
        (a, b) => (b.createdAt?.getDateTimeInUtc() ?? DateTime.now()).compareTo(
          a.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _currentUser = fetchedUser;
          _transactions = fetchedPayments;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      safePrint('Financial Fetch failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateAustralianPayId(String type, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your PayID.';
    }

    if (type == 'MOBILE') {
      final digitsOnly = trimmed.replaceAll(RegExp(r'\s+|-'), '');
      final auMobileRegex = RegExp(r'^(04\d{8}|\+614\d{8})$');
      if (!auMobileRegex.hasMatch(digitsOnly)) {
        return 'Enter a valid Australian mobile (e.g., 0412 345 678 or +61412345678).';
      }
    } else if (type == 'EMAIL') {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Enter a valid email address.';
      }
    } else if (type == 'ABN') {
      final digitsOnly = trimmed.replaceAll(RegExp(r'\s+'), '');
      if (!RegExp(r'^\d{11}$').hasMatch(digitsOnly)) {
        return 'Enter a valid 11-digit Australian Business Number (ABN).';
      }
    }

    return null;
  }

  String _formatAustralianPayId(String type, String value) {
    final trimmed = value.trim();
    if (type == 'MOBILE') {
      var digits = trimmed.replaceAll(RegExp(r'\s+|-'), '');
      if (digits.startsWith('+61')) {
        digits = '0${digits.substring(3)}';
      }
      if (digits.length == 10) {
        return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
      }
    } else if (type == 'ABN') {
      final digits = trimmed.replaceAll(RegExp(r'\s+'), '');
      if (digits.length == 11) {
        return '${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8)}';
      }
    }
    return trimmed;
  }

  Future<void> _showEditPayIdModal() async {
    if (_currentUser == null) return;

    String selectedType = _currentUser?.payIdType ?? 'MOBILE';
    final TextEditingController payIdController = TextEditingController(
      text: _currentUser?.payId ?? '',
    );
    String? errorText;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _crispWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String hintText = '04XX XXX XXX';
            TextInputType keyboardType = TextInputType.phone;
            if (selectedType == 'EMAIL') {
              hintText = 'name@example.com.au';
              keyboardType = TextInputType.emailAddress;
            } else if (selectedType == 'ABN') {
              hintText = 'XX XXX XXX XXX';
              keyboardType = TextInputType.number;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'AUSTRALIAN PAYID',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _champagneGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: _deepBlack,
                        ),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Only members inside your squads can view your PayID to settle game fees.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PayID Type Selector
                  Row(
                    children: ['MOBILE', 'EMAIL', 'ABN'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: type != 'ABN' ? 8.0 : 0,
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? _deepBlack
                                  : Colors.white,
                              foregroundColor: isSelected
                                  ? Colors.white
                                  : _deepBlack,
                              side: BorderSide(
                                color: isSelected
                                    ? _deepBlack
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              setModalState(() {
                                selectedType = type;
                                errorText = null;
                              });
                            },
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // PayID Input Field
                  TextField(
                    controller: payIdController,
                    keyboardType: keyboardType,
                    cursorColor: _champagneGold,
                    style: const TextStyle(
                      fontSize: 18,
                      color: _deepBlack,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      errorText: errorText,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w300,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _champagneGold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deepBlack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () async {
                        final validationError = _validateAustralianPayId(
                          selectedType,
                          payIdController.text,
                        );
                        if (validationError != null) {
                          setModalState(() => errorText = validationError);
                          return;
                        }

                        final formattedPayId = _formatAustralianPayId(
                          selectedType,
                          payIdController.text,
                        );
                        Navigator.pop(modalContext);
                        await _savePayId(selectedType, formattedPayId);
                      },
                      child: const Text(
                        'SAVE PAYID',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePayId(String payIdType, String payId) async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final updatedUser = _currentUser!.copyWith(
        payId: payId,
        payIdType: payIdType,
      );

      final request = ModelMutations.update(updatedUser);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Update PayID errors: ${response.errors}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save PayID: ${response.errors.first.message}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _currentUser = response.data ?? updatedUser;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Australian PayID saved!'),
              backgroundColor: _deepBlack,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      safePrint('Save PayID failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPayId =
        _currentUser?.payId != null && _currentUser!.payId!.isNotEmpty;

    return Scaffold(
      backgroundColor: _crispWhite,
      appBar: AppBar(
        backgroundColor: _crispWhite,
        elevation: 0,
        foregroundColor: _deepBlack,
        title: const Text(
          'FINANCIALS',
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
              onRefresh: _fetchFinancialData,
              color: _champagneGold,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                children: [
                  // Total Float Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _deepBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 40.0,
                      horizontal: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'TOTAL COLLECTED FLOAT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _champagneGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '\$${(_currentUser?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Australian PayID Card (Squad-Only Visibility)
                  Container(
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
                            Row(
                              children: [
                                const Text(
                                  'PAYID (AUSTRALIA)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _champagneGold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _crispWhite,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: const Text(
                                    'SQUAD ONLY',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: _deepBlack,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _showEditPayIdModal,
                              style: TextButton.styleFrom(
                                foregroundColor: _deepBlack,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                hasPayId ? 'EDIT' : 'ADD',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasPayId
                              ? '${_currentUser!.payId} (${_currentUser!.payIdType ?? 'PAYID'})'
                              : 'No PayID linked yet. Add your mobile, email, or ABN.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: hasPayId ? _deepBlack : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: _deepBlack,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_transactions.isEmpty)
                    const Text(
                      'No payments recorded yet.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    )
                  else
                    for (final tx in _transactions) _buildTransactionCard(tx),
                ],
              ),
            ),
    );
  }

  Widget _buildTransactionCard(Payment tx) {
    final isDebit = tx.type.toLowerCase().contains('debit');
    final amountPrefix = isDebit ? '-' : '+';
    final amountColor = isDebit ? _deepBlack : Colors.green.shade700;
    final statusColor = tx.status.toLowerCase() == 'completed'
        ? _champagneGold
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _deepBlack,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix\$${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
