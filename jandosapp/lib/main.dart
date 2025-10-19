import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // gerado pelo flutterfire
import 'providers/app_state.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções geradas pelo FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o AppState
  final appState = AppState();

  // Executa o app
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  final AppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState, // passa o AppState para todas as telas
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Checklist Oficina',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 244, 30, 30),
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
