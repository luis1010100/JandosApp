import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_state.dart';
import 'home_shell.dart';
import 'register_screen.dart';

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
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Função de login (mantida) com feedbacks de UI
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      // Login com Firebase Auth (mantido)
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      // ignore: use_build_context_synchronously
      final app = AppStateScope.of(context);

      // Atualiza AppState com dados do Firebase Realtime Database (mantido)
      await app.signInWithFirebase(user);

      // Navega para Home (mantido)
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Erro desconhecido';
      if (e.code == 'user-not-found') message = 'Usuário não encontrado';
      if (e.code == 'wrong-password') message = 'Senha incorreta';
      if (e.code == 'invalid-credential') message = 'Credenciais inválidas';
      if (e.code == 'network-request-failed') message = 'Sem conexão. Tente novamente.';

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // **RESPONSIVO**: usa LayoutBuilder + MediaQuery
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final horizontalPadding = isWide ? 32.0 : 20.0;
            final maxFormWidth = isWide ? 480.0 : 420.0;

            // Em telas muito altas, centraliza; em telas curtas, ancora mais abaixo
            final topSpacing = constraints.maxHeight > 720 ? 48.0 : 16.0;
            final bottomSpacing = constraints.maxHeight > 720 ? 48.0 : 16.0;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topSpacing,
                  horizontalPadding,
                  bottomSpacing,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Card(
                    elevation: Theme.of(context).brightness == Brightness.dark ? 0.5 : 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Branding leve (opcional: adicione seu logo aqui)
                            // const SizedBox(height: 4),
                            Text(
                              'Entrar',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 20),

                            // E-mail
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                hintText: 'exemplo@dominio.com',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Informe seu e-mail';
                                // validação simples de e-mail
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Senha
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: 'Mínimo 6 caracteres',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              autofillHints: const [AutofillHints.password],
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Informe sua senha';
                                if (value.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),

                            // Link "esqueci minha senha" (opcional – pode ligar depois)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        // TODO: implementar fluxo de reset (fase 2)
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Recuperação de senha em breve'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                child: const Text('Esqueci minha senha'),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Botão Entrar
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _loading ? null : _signIn,
                                child: _loading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.4),
                                      )
                                    : const Text('Entrar'),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Cadastre-se
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Não tem conta? ',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: _loading ? null : _goToRegister,
                                    child: const Text('Cadastre-se'),
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