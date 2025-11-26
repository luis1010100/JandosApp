import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appState = AppState();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AutoCenter',

        // ======================================================
        // 🚀 TEMA OFICIAL AUTOCENTER — SEM ROSA DO MATERIAL 3
        // ======================================================
        theme: ThemeData(
          useMaterial3: true,

          // 🔹 Cor geral de fundo do app
          scaffoldBackgroundColor: const Color(0xFFF6F7F9),

          // 🔹 AppBars brancas e limpas
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1B1B1B),
            elevation: 1,
            centerTitle: false,
          ),

          // ======================================================
          // 🎨 COLOR SCHEME BASE AUTOCENTER
          // ======================================================
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFCD193C), // Vermelho AutoCenter
            secondary: Color(0xFF005DFF), // Azul AutoCenter

            surface: Colors.white, // Cinza claro moderno
          ),

          // 🔹 Inputs padronizados
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),

        home: const LoginScreen(),
      ),
    );
  }
}
