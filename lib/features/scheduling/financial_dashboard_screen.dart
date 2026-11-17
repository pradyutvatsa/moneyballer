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

      // 1. Fetch live wallet balance from the User record
      final userRequest = ModelQueries.get(
        User.classType,
        UserModelIdentifier(id: authUser.userId),
      );
      final userResponse = await Amplify.API
          .query(request: userRequest)
          .response;
      final fetchedUser = userResponse.data;

      // 2. Fetch all Payment records linked to this organizer
      final paymentRequest = ModelQueries.list(
        Payment.classType,
        where: Payment.USER.eq(authUser.userId),
      );
      final paymentResponse = await Amplify.API
          .query(request: paymentRequest)
          .response;

      final items = paymentResponse.data?.items;
      final fetchedPayments = items?.whereType<Payment>().toList() ?? [];

      // Sort transactions by newest first
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

  @override
  Widget build(BuildContext context) {
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

                  const SizedBox(height: 48),

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
    // Determine visual style based on whether it's a debit or credit
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
