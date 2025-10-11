import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // descomente quando for integrar Firebase
  runApp(MyApp());
}

// ===== Models =====

enum UserRole { mechanic, admin }

class Checklist {
  final String id;
  final String placa;
  final String nomeCliente;
  final String nomeCarro;
  final String modeloCarro;
  final String marcaCarro;
  final int anoCarro;
  final String corCarro;
  final String observacoes;
  final List<PhotoPlaceholder> fotos;
  final DateTime createdAt;
  final String createdBy;

  Checklist({
    required this.id,
    required this.placa,
    required this.nomeCliente,
    required this.nomeCarro,
    required this.modeloCarro,
    required this.marcaCarro,
    required this.anoCarro,
    required this.corCarro,
    required this.observacoes,
    required this.fotos,
    required this.createdAt,
    required this.createdBy,
  });
}

class PhotoPlaceholder {
  final String path;
  PhotoPlaceholder(this.path);
}

// ===== Simple In-Memory App State =====

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _userName;
  String? _userEmail;
  final List<Checklist> _checklists = [];

  UserRole? get role => _role;
  String get userName => _userName ?? 'Usuário';
  String get userEmail => _userEmail ?? '';
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  void signIn({required String name, required String email, required UserRole role}) {
    _userName = name;
    _userEmail = email;
    _role = role;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    _userName = null;
    _userEmail = null;
    _checklists.clear();
    notifyListeners();
  }

  void addChecklist(Checklist c) {
    _checklists.insert(0, c);
    notifyListeners();
  }

  void removeChecklist(Checklist c) {
    _checklists.remove(c);
    notifyListeners();
  }

  void updateChecklist(Checklist oldC, Checklist newC) {
    final index = _checklists.indexOf(oldC);
    if (index != -1) {
      _checklists[index] = newC;
      notifyListeners();
    }
  }
}

// ===== AppStateScope =====

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required super.notifier, required super.child});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in context');
    return scope!.notifier!;
  }
}

// ===== Root App =====

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Checklist Oficina',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}

// ===== Login Screen =====

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Entrar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      obscureText: _obscure,
                      validator: (v) => (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final email = _emailCtrl.text.trim();
                            UserRole role;
                            if (email == 'admin@oficina.com') {
                              role = UserRole.admin;
                            } else {
                              role = UserRole.mechanic;
                            }
                            app.signIn(name: _nameCtrl.text.trim(), email: email, role: role);
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomeShell()),
                            );
                          }
                        },
                        child: const Text('Entrar'),
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
  }
}

// ===== HomeShell com Bottom Navigation =====

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = AppStateScope.of(context).role;
    _index = (role == UserRole.admin) ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final role = AppStateScope.of(context).role;
    final pages = [
      const ChecklistScreen(),
      const HistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Checklist Oficina — ${role == UserRole.admin ? 'Admin' : 'Mecânico'}'),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Checklist'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}

// ===== ChecklistScreen =====

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _nomeClienteCtrl = TextEditingController();
  final _nomeCarroCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final List<PhotoPlaceholder> _fotos = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _placaCtrl.dispose();
    _nomeClienteCtrl.dispose();
    _nomeCarroCtrl.dispose();
    _modeloCtrl.dispose();
    _marcaCtrl.dispose();
    _anoCtrl.dispose();
    _corCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _addPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _fotos.add(PhotoPlaceholder(image.path)));
    }
  }

  void _removePhoto(PhotoPlaceholder p) {
    setState(() => _fotos.remove(p));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppStateScope.of(context);
    final checklist = Checklist(
      id: UniqueKey().toString(),
      placa: _placaCtrl.text.trim(),
      nomeCliente: _nomeClienteCtrl.text.trim(),
      nomeCarro: _nomeCarroCtrl.text.trim(),
      modeloCarro: _modeloCtrl.text.trim(),
      marcaCarro: _marcaCtrl.text.trim(),
      anoCarro: int.tryParse(_anoCtrl.text.trim()) ?? DateTime.now().year,
      corCarro: _corCtrl.text.trim(),
      observacoes: _observacoesCtrl.text.trim(),
      fotos: List.from(_fotos),
      createdAt: DateTime.now(),
      createdBy: app.userName,
    );
    app.addChecklist(checklist);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checklist Salvo'),
        content: const Text('Seu checklist foi registrado com sucesso.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState!.reset();
    _placaCtrl.clear();
    _nomeClienteCtrl.clear();
    _nomeCarroCtrl.clear();
    _modeloCtrl.clear();
    _marcaCtrl.clear();
    _anoCtrl.clear();
    _corCtrl.clear();
    _observacoesCtrl.clear();
    setState(() {
      _fotos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Novo Checklist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildTextField(_placaCtrl, 'Placa*', validator: (v) {
              final regex = RegExp(r'^[A-Z]{3}-\d{4}$');
              if (v == null || !regex.hasMatch(v)) return 'Placa inválida (ex: ABC-1234)';
              return null;
            }),
            _buildTextField(_nomeClienteCtrl, 'Nome do Cliente*'),
            _buildTextField(_nomeCarroCtrl, 'Nome do Carro*'),
            _buildTextField(_modeloCtrl, 'Modelo*'),
            _buildTextField(_marcaCtrl, 'Marca*'),
            _buildTextField(_anoCtrl, 'Ano*', keyboardType: TextInputType.number, validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1900 || n > DateTime.now().year + 1) return 'Ano inválido';
              return null;
            }),
            _buildTextField(_corCtrl, 'Cor*'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacoesCtrl,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Observações'),
            ),
            const SizedBox(height: 16),
            const Text('Fotos', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._fotos.map((p) => Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: Image.file(
                            File(p.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _removePhoto(p),
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )),
                OutlinedButton.icon(
                  onPressed: _addPhoto,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Checklist'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpar Campos'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
          {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: ctrl, decoration: InputDecoration(labelText: label), keyboardType: keyboardType, validator: validator),
      );
}

// ===== HistoryScreen (Admin apenas) =====

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    if (app.role != UserRole.admin) {
      return const Center(child: Text('Acesso restrito ao Admin.'));
    }
    final items = app.checklists;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? const Center(child: Text('Sem checklists ainda.'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ChecklistCard(item: items[i]),
              ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final Checklist item;
  const _ChecklistCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final appState = AppStateScope.of(context);
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('${item.nomeCarro} • ${item.modeloCarro} • ${item.corCarro}'),
        subtitle: Text(
            'Cliente: ${item.nomeCliente}\nPlaca: ${item.placa}\nCriado: ${df.format(item.createdAt)} por ${item.createdBy}'),
        isThreeLine: true,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(onPressed: () => _mostrarDetalhes(context, item), icon: const Icon(Icons.visibility)),
          IconButton(
            onPressed: () => _editarChecklist(context, item),
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ]),
      ),
    );
  }

  void _mostrarDetalhes(BuildContext context, Checklist item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detalhes do Checklist'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Placa: ${item.placa}'),
              Text('Cliente: ${item.nomeCliente}'),
              Text('Carro: ${item.nomeCarro}'),
              Text('Modelo: ${item.modeloCarro}'),
              Text('Marca: ${item.marcaCarro}'),
              Text('Ano: ${item.anoCarro}'),
              Text('Cor: ${item.corCarro}'),
              Text('Observações: ${item.observacoes}'),
              const SizedBox(height: 12),
              const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (item.fotos.isEmpty)
                const Text('Nenhuma foto.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.fotos
                      .map((p) => Image.file(
                            File(p.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')
          ),
        ],
      ),
    );
  }

  void _editarChecklist(BuildContext context, Checklist item) {
    // Para simplificação, apenas mostramos uma mensagem.
    // Aqui você poderia navegar para uma tela de edição com os campos preenchidos.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Checklist'),
        content: const Text('Funcionalidade de edição não implementada.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')
          ),
        ],
      ),
    );
  }
}
