import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

// ===== Models =====

enum UserRole { mechanic, admin }

class Checklist {
  final String id;
  final String car;
  final int year;
  final String model;
  final String color;
  final String owner;
  final DateTime arrivalDate;
  final String notes;
  final List<String> photos; // placeholder paths/urls
  final DateTime createdAt;
  final String createdBy;

  Checklist({
    required this.id,
    required this.car,
    required this.year,
    required this.model,
    required this.color,
    required this.owner,
    required this.arrivalDate,
    required this.notes,
    required this.photos,
    required this.createdAt,
    required this.createdBy,
  });
}

// ===== Simple In-Memory App State =====

class AppState extends ChangeNotifier {
  UserRole? _role;
  String? _userName;
  final List<Checklist> _checklists = [];

  UserRole? get role => _role;
  String get userName => _userName ?? 'Usuário';
  List<Checklist> get checklists => List.unmodifiable(_checklists);

  void signIn({required String name, required UserRole role}) {
    _userName = name;
    _role = role;
    notifyListeners();
  }

  void signOut() {
    _role = null;
    _userName = null;
    _checklists.clear();
    notifyListeners();
  }

  void addChecklist(Checklist c) {
    _checklists.insert(0, c);
    notifyListeners();
  }
}

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
  UserRole _selectedRole = UserRole.mechanic;
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: UserRole.mechanic, child: Text('Mecânico')),
                        DropdownMenuItem(value: UserRole.admin, child: Text('Administrador')),
                      ],
                      onChanged: (role) => setState(() => _selectedRole = role ?? UserRole.mechanic),
                      decoration: const InputDecoration(labelText: 'Perfil'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            app.signIn(name: _nameCtrl.text.trim(), role: _selectedRole);
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

// ===== Home with Bottom Navigation =====

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
    // Admin abre no Histórico; Mecânico abre no Checklist
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
        actions: const [SizedBox()],
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

// ===== Checklist Screen =====

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _arrivalDateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<String> _photos = [];

  @override
  void dispose() {
    _carCtrl.dispose();
    _yearCtrl.dispose();
    _modelCtrl.dispose();
    _colorCtrl.dispose();
    _ownerCtrl.dispose();
    _arrivalDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      _arrivalDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _addPhotoPlaceholder() {
    // Placeholder: aqui você integraria image_picker/camera e faria upload
    setState(() {
      _photos.add('photo_${_photos.length + 1}.jpg');
    });
  }

  void _removePhoto(String p) {
    setState(() => _photos.remove(p));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 foto.')),
      );
      return;
    }

    final app = AppStateScope.of(context);
    final parsedDate = _arrivalDateCtrl.text.isEmpty
        ? DateTime.now()
        : DateFormat('dd/MM/yyyy').parse(_arrivalDateCtrl.text);

    final checklist = Checklist(
      id: UniqueKey().toString(),
      car: _carCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      model: _modelCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
      owner: _ownerCtrl.text.trim(),
      arrivalDate: parsedDate,
      notes: _notesCtrl.text.trim(),
      photos: List.from(_photos),
      createdAt: DateTime.now(),
      createdBy: app.userName,
    );

    app.addChecklist(checklist);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Checklist salva'),
        content: const Text('Seu checklist foi registrado com sucesso.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _formKey.currentState!.reset();
              setState(() {
                _arrivalDateCtrl.clear();
                _photos.clear();
              });
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Novo Checklist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _w(TextFormField(
                    controller: _carCtrl,
                    decoration: const InputDecoration(labelText: 'Carro*'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  )),
                  _w(TextFormField(
                    controller: _yearCtrl,
                    decoration: const InputDecoration(labelText: 'Ano*'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1900 || n > DateTime.now().year + 1) return 'Ano inválido';
                      return null;
                    },
                  )),
                  _w(TextFormField(
                    controller: _modelCtrl,
                    decoration: const InputDecoration(labelText: 'Modelo*'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  )),
                  _w(TextFormField(
                    controller: _colorCtrl,
                    decoration: const InputDecoration(labelText: 'Cor*'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  )),
                  _w(TextFormField(
                    controller: _ownerCtrl,
                    decoration: const InputDecoration(labelText: 'Proprietário*'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  )),
                  _w(TextFormField(
                    controller: _arrivalDateCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Data de chegada*',
                      suffixIcon: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Observações (texto livre)'),
              ),
              const SizedBox(height: 16),
              const Text('Fotos', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _photos.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  if (index == _photos.length) {
                    return OutlinedButton.icon(
                      onPressed: _addPhotoPlaceholder,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Adicionar'),
                    );
                  }
                  final p = _photos[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p, textAlign: TextAlign.center),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removePhoto(p),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar checklist'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper for responsive wrap
  Widget _w(Widget child) => SizedBox(
        width: 360,
        child: child,
      );
}

// ===== History Screen =====

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final items = app.checklists;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? const Center(
                child: Text('Sem checklists ainda. Faça o primeiro na aba "Checklist".'),
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => ChecklistCard(item: items[i]),
              ),
      ),
    );
  }
}

class ChecklistCard extends StatelessWidget {
  final Checklist item;
  const ChecklistCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('${item.car} • ${item.model} • ${item.color}'),
        subtitle: Text('Proprietário: ${item.owner}\nChegada: ${DateFormat('dd/MM/yyyy').format(item.arrivalDate)}\nCriado: ${df.format(item.createdAt)} por ${item.createdBy}'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showDialog(
          context: context,
          builder: (_) => _ChecklistDialog(item: item),
        ),
      ),
    );
  }
}

class _ChecklistDialog extends StatelessWidget {
  final Checklist item;
  const _ChecklistDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes do Checklist'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Carro', item.car),
              _row('Ano', item.year.toString()),
              _row('Modelo', item.model),
              _row('Cor', item.color),
              _row('Proprietário', item.owner),
              _row('Chegada', DateFormat('dd/MM/yyyy').format(item.arrivalDate)),
              const SizedBox(height: 8),
              const Text('Observações', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(item.notes.isEmpty ? '—' : item.notes),
              const SizedBox(height: 12),
              const Text('Fotos (placeholders)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.photos
                    .map((p) => Chip(label: Text(p), avatar: const Icon(Icons.photo)))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        )
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}