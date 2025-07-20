import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bitebuddy/firebase_options.dart';
import 'package:bitebuddy/providers/auth_provider.dart';
import 'package:bitebuddy/providers/theme_provider.dart';
import 'package:bitebuddy/screens/splash_screen.dart';
import 'package:bitebuddy/theme/duotone_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'BiteBuddy',
            debugShowCheckedModeBanner: false,
            theme: DuotoneTheme.lightTheme(),
            darkTheme: DuotoneTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

