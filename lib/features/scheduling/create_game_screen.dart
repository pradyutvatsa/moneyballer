import 'package:flutter/material.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
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

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: _deepBlack,
            onPrimary: Colors.white,
            onSurface: _deepBlack,
          ),
          // Fixed type mismatch: DialogThemeData instead of DialogTheme
          dialogTheme: const DialogThemeData(backgroundColor: _crispWhite),
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
          colorScheme: const ColorScheme.light(
            primary: _deepBlack,
            onPrimary: Colors.white,
            onSurface: _deepBlack,
          ),
          // Fixed type mismatch: DialogThemeData instead of DialogTheme
          dialogTheme: const DialogThemeData(backgroundColor: _crispWhite),
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
          'Create Game',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          children: [
            _buildLabel('Date'),
            _buildPickerField(
              text: _selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.toLocal()}'.split(' ')[0],
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 32),

            _buildLabel('Time'),
            _buildPickerField(
              text: _selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickTime,
            ),
            const SizedBox(height: 32),

            _buildLabel('Location'),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(
                fontSize: 18,
                color: _deepBlack,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: _champagneGold,
              decoration: _inputStyle('Enter field or park name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 32),

            _buildLabel('Max Players Limit'),
            TextFormField(
              controller: _maxPlayersController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 18,
                color: _deepBlack,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: _champagneGold,
              decoration: _inputStyle('e.g., 10 or 20'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Limit is required' : null,
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 22),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate() &&
                  _selectedDate != null &&
                  _selectedTime != null) {
                final int maxPlayers = int.parse(_maxPlayersController.text);

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
                  organizerId: 'ORGANIZER_USER',
                  maxPlayers: maxPlayers,
                  appFee: 0.0,
                  minimumBalanceRequired: 0.0,
                );

                try {
                  final request = ModelMutations.create(newGame);
                  final response = await Amplify.API
                      .mutate(request: request)
                      .response;

                  if (response.hasErrors) {
                    safePrint('Mutation errors: ${response.errors}');
                  } else {
                    safePrint(
                      'Game securely saved with backend fee interception!',
                    );
                    if (context.mounted) {
                      Navigator.pop(context, true);
                    }
                  }
                } on ApiException catch (e) {
                  safePrint('Mutation failed: $e');
                }
              }
            },
            child: const Text(
              'SCHEDULE GAME',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _champagneGold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.w300,
      ),
      filled: false,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _champagneGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Widget _buildPickerField({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: _champagneGold.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: _champagneGold),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: text.startsWith('Select')
                    ? Colors.grey.shade400
                    : _deepBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
