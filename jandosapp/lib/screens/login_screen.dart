import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import 'home_shell.dart';
import 'register_screen.dart';
import '../widgets/tool_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;

  /// Loading inicial ao abrir app (2s)
  bool _showInitialLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showInitialLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// LOADING AO CLICAR EM ENTRAR
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => const Center(child: ToolLoader(size: 80)),
    );

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // ignore: use_build_context_synchronously
      final app = AppStateScope.of(context);
      await app.signInWithFirebase(cred.user!);

      if (!mounted) return;

      Navigator.of(context).pop();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao entrar"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputDecoration _input(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: Colors.black54),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFFCD193C), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// LOADING INICIAL
    if (_showInitialLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: ToolLoader(size: 90)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final horizontalPadding = isWide ? 34.0 : 22.0;
            final maxFormWidth = isWide ? 480.0 : 420.0;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Card(
                    elevation: 5,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            /// LOGO — CORRIGIDA, SEM ESPAÇO EXTRA
                            Align(
                              alignment: const Alignment(
                                0.15,
                                0,
                              ), // leve deslocamento à direita
                              child: SizedBox(
                                height:
                                    150, // reduzido (corrige o espaço gigante)
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Image.asset(
                                    "assets/autocenter_logo.png",
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            /// TÍTULO
                            Text(
                              'CHECKLIST DE INSPEÇÃO VEICULAR',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                            ),

                            const SizedBox(height: 24),

                            /// EMAIL
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: _input(
                                "E-mail",
                                Icons.alternate_email,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Informe seu e-mail";
                                }
                                if (!v.contains("@")) {
                                  return "E-mail inválido";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            /// SENHA
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              focusNode: _passwordFocus,
                              decoration: _input(
                                "Senha",
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Informe sua senha";
                                }
                                if (v.length < 6) {
                                  return "Mínimo 6 caracteres";
                                }
                                return null;
                              },
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Esqueci minha senha",
                                  style: TextStyle(
                                    color: Color(0xFF005DFF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// BOTÃO ENTRAR
                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFCD193C),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _signIn,
                                child: const Text(
                                  "Entrar",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            /// CADASTRE-SE
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Não tem conta?",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      "Cadastre-se",
                                      style: TextStyle(
                                        color: Color(0xFF005DFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
