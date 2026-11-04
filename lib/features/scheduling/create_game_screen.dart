// Ensure these imports are at the top of create_game_screen.dart:
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'Create Game',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildLabel('Date'),
            _buildPickerField(
              text: _selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.toLocal()}'.split(' ')[0],
              icon: Icons.calendar_today,
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),

            _buildLabel('Time'),
            _buildPickerField(
              text: _selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),

            _buildLabel('Location'),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: _inputStyle('Enter field or park name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 24),

            _buildLabel('Max Players limit'),
            TextFormField(
              controller: _maxPlayersController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: _inputStyle('e.g., 10 or 20'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Limit is required' : null,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate() &&
                    _selectedDate != null &&
                    _selectedTime != null) {
                  final int maxPlayers = int.parse(_maxPlayersController.text);
                  // Calculate the upfront organizer float fee based on session size[cite: 1]
                  final double fee = maxPlayers <= 10 ? 1.99 : 2.99;

                  try {
                    // 1. Fetch the authenticated Cognito User
                    final authUser = await Amplify.Auth.getCurrentUser();
                    final userId = authUser.userId;

                    // 2. Fetch the Organizer's current wallet balance from DynamoDB
                    final userRequest = ModelQueries.list(
                      User.classType,
                      where: User.ID.eq(userId),
                    );
                    final userResponse = await Amplify.API
                        .query(request: userRequest)
                        .response;
                    final users = userResponse.data?.items;

                    if (users == null || users.isEmpty || users.first == null) {
                      safePrint('Organizer profile not found in DynamoDB.');
                      return;
                    }
                    final organizer = users.first!;

                    // 3. Verify sufficient funds
                    if (organizer.walletBalance < fee) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Insufficient funds. Please top up \$$fee to schedule.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    // 4. Deduct the upfront fee from the organizer's wallet[cite: 1]
                    final updatedOrganizer = organizer.copyWith(
                      walletBalance: organizer.walletBalance - fee,
                    );
                    await Amplify.API
                        .mutate(
                          request: ModelMutations.update(updatedOrganizer),
                        )
                        .response;

                    // 5. Generate the Payment receipt using the full user object[cite: 5]
                    final payment = Payment(
                      amount: fee,
                      type: 'Organizer Fee Debit',
                      status: 'Completed',
                      user: organizer,
                    );
                    await Amplify.API
                        .mutate(request: ModelMutations.create(payment))
                        .response;

                    // 6. Schedule the Game[cite: 1]
                    final combinedDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    );

                    final newGame = Game(
                      date: TemporalDate(_selectedDate!),
                      time: TemporalTime(combinedDateTime),
                      location: _locationController.text,
                      organizerId: userId,
                      maxPlayers: maxPlayers,
                      appFee: fee,
                      minimumBalanceRequired: fee,
                    );

                    final gameResponse = await Amplify.API
                        .mutate(request: ModelMutations.create(newGame))
                        .response;

                    if (gameResponse.hasErrors) {
                      safePrint('Game creation errors: ${gameResponse.errors}');
                    } else {
                      safePrint(
                        'Game scheduled and \$$fee deducted successfully!',
                      );
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  } on ApiException catch (e) {
                    safePrint('Transaction failed: $e');
                  }
                }
              },
              child: const Text(
                'SCHEDULE GAME',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 3),
      ),
    );
  }

  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
