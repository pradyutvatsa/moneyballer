import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_authenticator/amplify_authenticator.dart';

import 'amplify_outputs.dart';

import 'package:moneyballer/models/ModelProvider.dart';
import 'package:moneyballer/features/scheduling/dashboard_screen.dart';

void main() {
  runApp(const MoneyBallerApp());
}

class MoneyBallerApp extends StatefulWidget {
  const MoneyBallerApp({super.key});

  @override
  State<MoneyBallerApp> createState() => _MoneyBallerAppState();
}

class _MoneyBallerAppState extends State<MoneyBallerApp> {
  bool _isAmplifyConfigured = false;

  // Premium Color Palette
  static const Color _crispWhite = Color(0xFFFAF7F2);
  static const Color _deepBlack = Color(0xFF0F0F0F);
  static const Color _champagneGold = Color(0xFFC2A878);

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      if (!Amplify.isConfigured) {
        final auth = AmplifyAuthCognito();
        final api = AmplifyAPI(
          options: APIPluginOptions(modelProvider: ModelProvider.instance),
        );

        await Amplify.addPlugins([auth, api]);
        await Amplify.configure(amplifyConfig);
      }

      setState(() {
        _isAmplifyConfigured = true;
      });
      safePrint('Successfully configured Amplify with Gen 2 Sandbox!');
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  ThemeData _buildPremiumTheme() {
    return ThemeData(
      scaffoldBackgroundColor: _crispWhite,
      primaryColor: _deepBlack,
      colorScheme: const ColorScheme.light(
        primary: _deepBlack,
        secondary: _champagneGold,
        surface: _crispWhite,
      ),
      // Auth Form Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w300,
        ),
        labelStyle: const TextStyle(
          color: _deepBlack,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.2,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 0.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _champagneGold, width: 1.5),
        ),
      ),
      // Auth Primary Buttons (Sign In / Sign Up)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _deepBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ), // Clean geometric edges
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
      ),
      // Auth Secondary Text Buttons (Forgot Password / Switch to Sign Up)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _champagneGold,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAmplifyConfigured) {
      return MaterialApp(
        theme: _buildPremiumTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _champagneGold)),
        ),
      );
    }

    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        title: 'MoneyBaller',
        theme: _buildPremiumTheme(), // Authenticator instantly inherits this aesthetic
        home: const DashboardScreen(),
      ),
    );
  }
}
