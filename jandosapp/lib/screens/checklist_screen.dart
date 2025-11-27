import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/checklist.dart';
import '../models/photo_placeholder.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';
import 'orcamento_previo_screen.dart'; // 🔥 ADICIONADO PARA NAVEGAR AO ORÇAMENTO

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, this.editing});

  final Checklist? editing;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _nomeClienteCtrl = TextEditingController();
  final _nomeCarroCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  final List<PhotoPlaceholder> _fotos = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  Checklist? get _editing => widget.editing;

  // ==== PALETA AUTOCENTER ====
  static const Color _primaryColor = Color(0xFFCD193C);
  static const Color _secondaryColor = Color(0xFF005DFF);
  static const Color _backgroundColor = Color(0xFFF6F7F9);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1B1B1B);
  static const Color _secondaryTextColor = Color(0xFF6B7280);
  static const Color _errorColor = Color(0xFFCD193C);

  @override
  void initState() {
    super.initState();
    if (_editing != null) {
      final c = _editing!;
      _nomeClienteCtrl.text = c.nomeCliente;
      _nomeCarroCtrl.text = c.nomeCarro;
      _placaCtrl.text = c.placa;
      _modeloCtrl.text = c.modeloCarro;
      _marcaCtrl.text = c.marcaCarro;
      _anoCtrl.text = c.anoCarro.toString();
      _corCtrl.text = c.corCarro;
      _observacoesCtrl.text = c.observacoes;
      _fotos.addAll(c.fotos);
    }
  }

  @override
  void dispose() {
    _nomeClienteCtrl.dispose();
    _nomeCarroCtrl.dispose();
    _placaCtrl.dispose();
    _modeloCtrl.dispose();
    _marcaCtrl.dispose();
    _anoCtrl.dispose();
    _corCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _isHttp(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _addPhoto() async {
    final ImageSource? source = await showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_rounded,
                color: _textColor,
              ),
              title: const Text(
                'Tirar Foto',
                style: TextStyle(color: _textColor),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: _textColor,
              ),
              title: const Text(
                'Escolher da Galeria',
                style: TextStyle(color: _textColor),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _fotos.add(PhotoPlaceholder(image.path)));
    }
  }

  void _removePhoto(PhotoPlaceholder p) {
    setState(() => _fotos.remove(p));
  }

Future<void> _submit() async {
  if (!_formKey.currentState!.validate() || _isSaving) return;

  setState(() => _isSaving = true);
  final app = AppStateScope.of(context);
  final user = FirebaseAuth.instance.currentUser;

  try {
    // ====== GERAR ID DO CHECKLIST ANTES DE TUDO ======
    final now = DateTime.now();
    final checklistId = _editing?.id ?? now.millisecondsSinceEpoch.toString();

    // ====== FOTOS EXISTENTES (já são URLs) ======
    final existingUrls = _fotos
        .where((p) => _isHttp(p.path))
        .map((p) => p.path)
        .toList();

    // ====== FOTOS NOVAS LOCAIS ======
    final localNew = _fotos.where((p) => !_isHttp(p.path)).toList();
    final uploadedUrls = <String>[];

    for (final photo in localNew) {
      final file = File(photo.path);

      // nome 100% único
      final uniqueId = DateTime.now().microsecondsSinceEpoch.toString();

      // placa limpa
      final cleanPlaca = _placaCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');

      // 🔥 path seguro (uma pasta por checklist)
      final filePath =
          'checklist_photos/$checklistId/${uniqueId}_$cleanPlaca.jpg';

      final ref = FirebaseStorage.instance.ref().child(filePath);

      await ref.putFile(file); // upload da imagem
      final url = await ref.getDownloadURL(); // agora SEM ERRO

      uploadedUrls.add(url);
    }

    // ====== CRIA OBJETO FINAL DO CHECKLIST ======
    final newData = Checklist(
      id: checklistId,
      nomeCliente: _nomeClienteCtrl.text.trim(),
      nomeCarro: _nomeCarroCtrl.text.trim(),
      placa: _placaCtrl.text.trim().toUpperCase(),
      modeloCarro: _modeloCtrl.text.trim(),
      marcaCarro: _marcaCtrl.text.trim(),
      anoCarro: int.tryParse(_anoCtrl.text) ?? now.year,
      corCarro: _corCtrl.text.trim(),
      observacoes: _observacoesCtrl.text.trim(),
      fotos: [
        ...existingUrls,
        ...uploadedUrls,
      ].map((p) => PhotoPlaceholder(p)).toList(),
      createdAt: _editing?.createdAt ?? now,
      createdBy: _editing?.createdBy ?? app.userName,
      createdByRole: _editing?.createdByRole ?? (app.role ?? UserRole.mechanic),
      createdByUid: _editing?.createdByUid ?? user?.uid,
    );

    // ====== SALVAR ======
    if (_editing == null) {
      await app.addChecklist(newData);
    } else {
      await app.updateChecklist(_editing!, newData);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          _editing == null ? 'Checklist salvo!' : 'Checklist atualizado!',
          style: const TextStyle(color: _textColor),
        ),
        content: Text(
          _editing == null
              ? 'Os dados foram registrados com sucesso.'
              : 'As alterações foram salvas.',
          style: const TextStyle(color: _secondaryTextColor),
        ),
        actions: [
          TextButton(
            child: const Text('OK', style: TextStyle(color: _primaryColor)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if (Navigator.canPop(context)) Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: _errorColor,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Checklist' : 'Novo Checklist',
          style: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
        elevation: 1,

        /// 🔥🔥🔥 AQUI: ADICIONADO O BOTÃO DE ORÇAMENTO PRÉVIO
        actions: [
          if (isEditing)
            IconButton(
              tooltip: 'Orçamento Prévio',
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: _primaryColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrcamentoPrevioScreen(checklist: _editing!),
                  ),
                );
              },
            ),

          if (!isEditing)
            IconButton(
              tooltip: 'Limpar campos',
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: _primaryColor,
              ),
              onPressed: _isSaving
                  ? null
                  : () {
                      _nomeClienteCtrl.clear();
                      _nomeCarroCtrl.clear();
                      _placaCtrl.clear();
                      _modeloCtrl.clear();
                      _marcaCtrl.clear();
                      _anoCtrl.clear();
                      _corCtrl.clear();
                      _observacoesCtrl.clear();
                      _fotos.clear();
                      setState(() => _currentStep = 0);
                    },
            ),
        ],
      ),

      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (s) => setState(() => _currentStep = s),
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: _controlsBuilder,
          elevation: 0,
          margin: EdgeInsets.zero,

          steps: [
            _buildStep(
              title: 'Identificação',
              step: 0,
              content: [
                _tf(_nomeClienteCtrl, 'Nome do Cliente*'),
                _tf(_nomeCarroCtrl, 'Nome do Carro*'),
                _tf(
                  _placaCtrl,
                  'Placa*',
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => (v == null || v.trim().length != 7)
                      ? 'Placa inválida'
                      : null,
                ),
                _tf(_modeloCtrl, 'Modelo*'),
                _tf(_marcaCtrl, 'Marca*'),
                _tf(
                  _anoCtrl,
                  'Ano*',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                      return 'Ano inválido';
                    }
                    return null;
                  },
                ),
                _tf(_corCtrl, 'Cor*'),
              ],
            ),

            _buildStep(
              title: 'Danos e Fotos',
              step: 1,
              needsValidation: false,
              content: [
                TextFormField(
                  controller: _observacoesCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: _inputDecoration(
                    'Observações / Danos (opcional)',
                  ),
                ),
                const SizedBox(height: 16),
                _buildPhotoGrid(),
                const SizedBox(height: 12),
                _buildAddPhotoButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ---- Helpers ----------------------------------------------------

  Step _buildStep({
    required String title,
    required int step,
    required List<Widget> content,
    bool needsValidation = true,
  }) {
    bool active = _currentStep >= step;
    StepState state = StepState.indexed;

    if (_currentStep > step) {
      state = StepState.complete;
    } else if (active &&
        needsValidation &&
        _formKey.currentState != null &&
        !_formKey.currentState!.validate()) {
      state = StepState.error;
    }

    return Step(
      title: Text(title, style: const TextStyle(color: _textColor)),
      isActive: active,
      state: state,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  Widget _controlsBuilder(BuildContext context, ControlsDetails details) {
    final bool isLast = _currentStep == 1;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: _isSaving
                ? null
                : (isLast ? _submit : details.onStepContinue),
            icon: isLast
                ? (_isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.save))
                : const Icon(Icons.arrow_forward),
            label: Text(
              isLast
                  ? (_isSaving ? 'SALVANDO...' : 'SALVAR CHECKLIST')
                  : 'CONTINUAR',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          if (_currentStep > 0)
            TextButton(
              onPressed: _isSaving ? null : details.onStepCancel,
              child: const Text(
                'Voltar',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _secondaryTextColor),
      filled: true,
      fillColor: _cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        borderSide: BorderSide(color: _secondaryTextColor.withOpacity(0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        borderSide: BorderSide(color: _secondaryTextColor.withOpacity(0.4)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _errorColor),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _errorColor, width: 2),
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: _inputDecoration(label),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return ElevatedButton.icon(
      onPressed: _addPhoto,
      icon: const Icon(Icons.add_a_photo_outlined, size: 22, color: _textColor),
      label: const Text('ADICIONAR FOTO'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _secondaryColor,
        foregroundColor: _textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    if (_fotos.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: _secondaryTextColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, color: _secondaryTextColor, size: 36),
              SizedBox(height: 4),
              Text(
                'Nenhuma foto adicionada.',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fotos.map((p) {
        final isNetwork = _isHttp(p.path);
        final img = isNetwork
            ? Image.network(p.path, width: 100, height: 100, fit: BoxFit.cover)
            : Image.file(
                File(p.path),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              );

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              img,
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: () => _removePhoto(p),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}