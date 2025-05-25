import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:water_v0/screens/EspaceMembre.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/EspaceChef.dart';
import 'package:provider/provider.dart';
import 'package:water_v0/models/challenge_provider.dart'; // Import ajouté

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChallengeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      title: 'Mon Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF26A69A),
          tertiary: const Color(0xFF66BB6A),
          background: const Color(0xFFF5F9F6),
        ),
        fontFamily: 'Montserrat',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/EspaceChef': (context) => EspaceChef(userId: '', userEmail: ''),
        '/EspaceMembre': (context) => EspaceMembre(memberEmail: ''),
      },
    );
  }
}