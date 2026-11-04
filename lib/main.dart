import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplify_outputs.dart';

import 'package:amplify_authenticator/amplify_authenticator.dart';
import 'package:moneyballer/features/scheduling/dashboard_screen.dart';
import 'package:moneyballer/models/ModelProvider.dart';

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

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      // 1. Safely handle hot restarts by checking if plugins are already loaded
      if (!Amplify.isConfigured) {
        final auth = AmplifyAuthCognito();
        // Tell the API plugin to use your newly generated Gen 2 models
        final api = AmplifyAPI(
          options: APIPluginOptions(modelProvider: ModelProvider.instance),
        );

        await Amplify.addPlugins([auth, api]);
        await Amplify.configure(amplifyConfig);
      }

      // 2. Safely reveal the UI
      setState(() {
        _isAmplifyConfigured = true;
      });
      safePrint('Successfully configured Amplify with Gen 2 Sandbox!');
    } on Exception catch (e) {
      safePrint('An error occurred configuring Amplify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Show a loading spinner while Amplify configures in the background
    if (!_isAmplifyConfigured) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // 2. Once configured, render the Authenticator and the main app
    return Authenticator(
      child: MaterialApp(
        builder: Authenticator.builder(),
        title: 'MoneyBaller',
        theme: ThemeData(primarySwatch: Colors.blue),
        // Drop your new dashboard right here!
        home: const DashboardScreen(),
      ),
    );
  }
}
