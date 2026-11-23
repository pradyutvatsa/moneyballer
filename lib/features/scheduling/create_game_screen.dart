import 'package:material_ui/material_ui.dart';
import 'package:amplify_api/amplify_api.dart';
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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<Team> _userSquads = [];
  Team? _selectedTeam;
  bool _isLoadingSquads = true;
  bool _isSubmitting = false;

  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.initialTeam;
    _fetchUserSquads();
  }

  Future<void> _fetchUserSquads() async {
    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final request = ModelQueries.list(
        TeamMember.classType,
        where: TeamMember.USER.eq(authUser.userId),
      );
      final response = await Amplify.API.query(request: request).response;

      final squads =
          response.data?.items
              .whereType<TeamMember>()
              .map((m) => m.team)
              .whereType<Team>()
              .where((team) => team.organizerId == authUser.userId)
              .toList() ??
          [];

      if (mounted) {
        setState(() {
          _userSquads = squads;
          // Ensure _selectedTeam matches an instance in _userSquads
          if (_selectedTeam != null) {
            _selectedTeam = squads.firstWhere(
              (t) => t.id == _selectedTeam!.id,
              orElse: () => _selectedTeam!,
            );
          } else if (squads.length == 1) {
            _selectedTeam = squads.first;
          }
          _isLoadingSquads = false;
        });
      }
    } on ApiException catch (e) {
      safePrint('Fetch user squads failed: $e');
      if (mounted) setState(() => _isLoadingSquads = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _deepBlack),
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
          colorScheme: const ColorScheme.light(primary: _deepBlack),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _scheduleGame() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a squad, date, and time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authUser = await Amplify.Auth.getCurrentUser();
      final int maxPlayers = int.parse(_maxPlayersController.text.trim());
      final double calculatedFee = maxPlayers <= 10 ? 1.99 : 2.99;

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
        location: _locationController.text.trim(),
        organizerId: authUser.userId,
        maxPlayers: maxPlayers,
        appFee: calculatedFee,
        minimumBalanceRequired: calculatedFee,
        team: _selectedTeam!, // Bound directly to the selected Squad
      );

      final request = ModelMutations.create(newGame);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Create Game errors: ${response.errors}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.errors.first.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } on ApiException catch (e) {
      safePrint('Mutation failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
        title: const Text(
          'SCHEDULE SQUAD GAME',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        backgroundColor: _crispWhite,
        foregroundColor: _deepBlack,
        elevation: 0,
      ),
      body: _isLoadingSquads
          ? const Center(
              child: CircularProgressIndicator(color: _champagneGold),
            )
          : _userSquads.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_off_outlined,
                      size: 48,
                      color: _champagneGold,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Squad Found',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: _deepBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Games can only be scheduled inside a squad. Create or join a squad first in the Teams tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text(
                    'SQUAD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Team>(
                    initialValue: _selectedTeam,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    hint: const Text('Select a squad'),
                    items: _userSquads
                        .map(
                          (team) => DropdownMenuItem<Team>(
                            value: team,
                            child: Text(
                              team.name,
                              style: const TextStyle(
                                fontSize: 18,
                                color: _deepBlack,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: widget.initialTeam != null
                        ? null // Locked when opened directly from a specific Squad screen
                        : (team) => setState(() => _selectedTeam = team),
                    validator: (value) =>
                        value == null ? 'Please select a squad' : null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'DATE & TIME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.toLocal()}'.split(' ')[0],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            _selectedTime == null
                                ? 'Select Time'
                                : _selectedTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter field or venue',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Location is required'
                        : null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'MAX PLAYERS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _champagneGold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _maxPlayersController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g., 10 or 14',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null || parsed < 2) {
                        return 'Enter at least 2 players';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deepBlack,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _scheduleGame,
                      child: Text(
                        _isSubmitting ? 'SCHEDULING...' : 'SCHEDULE GAME',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
