import 'package:material_ui/material_ui.dart';
//import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:moneyballer/models/ModelProvider.dart';

class CreateGameScreen extends StatefulWidget {
  final Team? initialTeam;

  const CreateGameScreen({super.key, this.initialTeam});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _userFeeInputController =
      TextEditingController(); // User input for Social Squad

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  bool get _isSocialSquad => widget.initialTeam?.squadType == 'SOCIAL';

  @override
  void initState() {
    super.initState();
    // Trigger UI recalculation whenever maxPlayers or user fee input changes
    _maxPlayersController.addListener(_onFeeInputsChanged);
    _userFeeInputController.addListener(_onFeeInputsChanged);
  }

  void _onFeeInputsChanged() {
    if (_isSocialSquad && mounted) {
      setState(() {});
    }
  }

  /// Computes: userInput + (1.99 or 2.99) / maxPlayers
  double? get _computedSocialTotalFee {
    final int? maxPlayers = int.tryParse(_maxPlayersController.text.trim());
    if (maxPlayers == null || maxPlayers <= 0) return null;

    final double userInput =
        double.tryParse(_userFeeInputController.text.trim()) ?? 0.0;
    final double appTierFee = maxPlayers <= 10 ? 1.99 : 2.99;

    return userInput + (appTierFee / maxPlayers);
  }

  @override
  void dispose() {
    _maxPlayersController.removeListener(_onFeeInputsChanged);
    _userFeeInputController.removeListener(_onFeeInputsChanged);
    _locationController.dispose();
    _maxPlayersController.dispose();
    _userFeeInputController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final int? parsedMaxPlayers = int.tryParse(
      _maxPlayersController.text.trim(),
    );
    final double? computedTotal = _computedSocialTotalFee;
    final double tierFee = (parsedMaxPlayers != null && parsedMaxPlayers > 10)
        ? 2.99
        : 1.99;

    return Scaffold(
      backgroundColor: _crispWhite,
      appBar: AppBar(
        backgroundColor: _crispWhite,
        elevation: 0,
        foregroundColor: _deepBlack,
        title: const Text(
          'SCHEDULE GAME',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
          children: [
            _buildLabel('DATE'),
            _buildPickerTile(
              text: _selectedDate == null
                  ? 'Select Date'
                  : '${_selectedDate!.toLocal()}'.split(' ')[0],
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 28),

            _buildLabel('TIME'),
            _buildPickerTile(
              text: _selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context),
              icon: Icons.access_time,
              onTap: _pickTime,
            ),
            const SizedBox(height: 28),

            _buildLabel('LOCATION'),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(fontSize: 18, color: _deepBlack),
              decoration: _underlineInput('Enter field or venue name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Location is required' : null,
            ),
            const SizedBox(height: 28),

            // 1. Max Players Field
            _buildLabel('MAX PLAYERS (TOTAL ROSTER SIZE)'),
            TextFormField(
              controller: _maxPlayersController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, color: _deepBlack),
              decoration: _underlineInput('e.g., 10 or 14'),
              validator: (v) {
                final val = int.tryParse(v?.trim() ?? '');
                if (val == null || val <= 0) {
                  return 'Enter a valid player count greater than 0';
                }
                return null;
              },
            ),

            // 2. Social Squad Fee Input & Computed Total Fee (follows Max Players)
            if (_isSocialSquad) ...[
              const SizedBox(height: 28),
              _buildLabel('ORGANIZER FEE INPUT (\$ AUD)'),
              TextFormField(
                controller: _userFeeInputController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 18, color: _deepBlack),
                decoration: _underlineInput('e.g., 10.00'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter your base fee amount';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid non-negative amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Computed Total Fee Display Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _champagneGold.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL FEE PER PLAYER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _champagneGold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      computedTotal != null
                          ? '\$${computedTotal.toStringAsFixed(2)} AUD'
                          : 'Enter Max Players to calculate',
                      style: TextStyle(
                        fontSize: computedTotal != null ? 28 : 16,
                        fontWeight: FontWeight.w400,
                        color: computedTotal != null
                            ? _deepBlack
                            : Colors.grey.shade500,
                      ),
                    ),
                    if (computedTotal != null && parsedMaxPlayers != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Includes \$${(_userFeeInputController.text.trim().isEmpty ? 0.0 : double.tryParse(_userFeeInputController.text.trim()) ?? 0.0).toStringAsFixed(2)} + (\$${tierFee.toStringAsFixed(2)} ÷ $parsedMaxPlayers players)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 44),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: _isSubmitting ? null : _submitGame,
              child: const Text(
                'SCHEDULE GAME',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitGame() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null ||
        widget.initialTeam == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final int maxPlayers = int.parse(_maxPlayersController.text.trim());
      final double? userFeeInput = _isSocialSquad
          ? (double.tryParse(_userFeeInputController.text.trim()) ?? 0.0)
          : null;

      final String formattedDate =
          '${_selectedDate!.year.toString().padLeft(4, '0')}-'
          '${_selectedDate!.month.toString().padLeft(2, '0')}-'
          '${_selectedDate!.day.toString().padLeft(2, '0')}';

      final String formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
          '${_selectedTime!.minute.toString().padLeft(2, '0')}:00.000Z';

      const String mutationDocument = '''
        mutation CreateGameWithFee(
          \$date: AWSDate!,
          \$time: AWSTime!,
          \$location: String!,
          \$organizerId: ID!,
          \$maxPlayers: Int!,
          \$squadType: String,
          \$userFeeInput: Float,
          \$teamId: ID
        ) {
          createGameWithFee(
            date: \$date,
            time: \$time,
            location: \$location,
            organizerId: \$organizerId,
            maxPlayers: \$maxPlayers,
            squadType: \$squadType,
            userFeeInput: \$userFeeInput,
            teamId: \$teamId
          ) {
            id
            date
            time
            location
            organizerId
            maxPlayers
            userFeeInput
            appFee
            minimumBalanceRequired
            teamId
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: mutationDocument,
        variables: {
          'date': formattedDate,
          'time': formattedTime,
          'location': _locationController.text.trim(),
          'organizerId': authUser.userId,
          'maxPlayers': maxPlayers,
          'squadType': widget.initialTeam!.squadType,
          'userFeeInput': userFeeInput,
          'teamId': widget.initialTeam!.id,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('CreateGameWithFee errors: ${response.errors}');
      } else {
        safePrint(
          'Game created with backend fee calculation: ${response.data}',
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on ApiException catch (e) {
      safePrint('Schedule game failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _champagneGold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _underlineInput(String hint) {
    return InputDecoration(
      hintText: hint,
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
    );
  }

  Widget _buildPickerTile({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _champagneGold),
            const SizedBox(width: 14),
            Text(text, style: const TextStyle(fontSize: 18, color: _deepBlack)),
          ],
        ),
      ),
    );
  }
}
