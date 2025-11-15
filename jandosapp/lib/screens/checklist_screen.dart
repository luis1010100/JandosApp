import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/checklist.dart';
import '../models/photo_placeholder.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, this.editing});

  /// Se não for nulo, entra em modo edição.
  final Checklist? editing;

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  // A _formKey agora engloba todos os steps
  final _formKey = GlobalKey<FormState>(); 
  int _currentStep = 0; // Controla qual etapa está ativa

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

  // --- Constantes de Design (Doc 4.1) ---
  static const Color _primaryColor = Color(0xFF1565C0); // Azul Forte
  static const Color _secondaryColor = Color(0xFFFFB300); // Âmbar
  static const Color _backgroundColor = Color(0xFFF6F7F9); // Fundo Claro
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF1B1B1B);
  static const Color _secondaryTextColor = Color(0xFF6B7280);
  static const Color _errorColor = Color(0xFFD32F2F);
  // --- FIM DAS CONSTANTES ---

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

  // --- 🐞 INÍCIO DA CORREÇÃO (1/2): Funções do Stepper ---
  /// Lógica para avançar para o próximo passo
  void _onStepContinue() {
    // Valida apenas os campos do passo atual (Etapa 1)
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        // Se for válido, avança para o próximo passo
        setState(() => _currentStep = 1);
      }
      // Se não for válido, o `validate()` já mostrou os erros. Não faz nada.
    }
    // A lógica de 'Submit' é tratada no controlsBuilder
  }

  /// Lógica para voltar ao passo anterior
  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep = _currentStep - 1);
    }
  }
  // --- 🐞 FIM DA CORREÇÃO (1/2) ---


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
              leading: const Icon(Icons.photo_camera_rounded, color: _textColor),
              title: const Text('Tirar Foto', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _textColor),
              title: const Text('Escolher da Galeria', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() => _fotos.add(PhotoPlaceholder(image.path)));
    }
  }

  void _removePhoto(PhotoPlaceholder p) {
    setState(() => _fotos.remove(p));
  }

  Future<void> _submit() async {
    // Valida o formulário inteiro antes de salvar
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final app = AppStateScope.of(context);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final existingUrls =
          _fotos.where((p) => _isHttp(p.path)).map((p) => p.path).toList();
      final localNew = _fotos.where((p) => !_isHttp(p.path)).toList();
      final uploadedUrls = <String>[];

      for (final photo in localNew) {
        final file = File(photo.path);
        final fileName =
            'checklist_photos/${DateTime.now().millisecondsSinceEpoch}_${_placaCtrl.text.trim()}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        uploadedUrls.add(url);
      }

      if (_editing != null) {
        final oldUrls =
            _editing!.fotos.map((e) => e.path).where(_isHttp).toSet();
        final kept = existingUrls.toSet();
        final toDelete = oldUrls.difference(kept);
        for (final u in toDelete) {
          try {
            await FirebaseStorage.instance.refFromURL(u).delete();
          } catch (_) {/* ignora falhas */}
        }
      }

      final allUrls = [...existingUrls, ...uploadedUrls];
      final now = DateTime.now();

      final newData = Checklist(
        id: _editing?.id ?? now.millisecondsSinceEpoch.toString(),
        nomeCliente: _nomeClienteCtrl.text.trim(),
        nomeCarro: _nomeCarroCtrl.text.trim(),
        placa: _placaCtrl.text.trim().toUpperCase(), // Salva em maiúsculo
        modeloCarro: _modeloCtrl.text.trim(),
        marcaCarro: _marcaCtrl.text.trim(),
        anoCarro: int.tryParse(_anoCtrl.text.trim()) ?? now.year,
        corCarro: _corCtrl.text.trim(),
        observacoes: _observacoesCtrl.text.trim(),
        fotos: allUrls.map((p) => PhotoPlaceholder(p)).toList(),
        createdAt: _editing?.createdAt ?? now,
        createdBy: _editing?.createdBy ?? app.userName,
        createdByRole: _editing?.createdByRole ?? (app.role ?? UserRole.mechanic),
        createdByUid: _editing?.createdByUid ?? user?.uid,
      );

      if (_editing == null) {
        await app.addChecklist(newData);
      } else {
        await app.updateChecklist(_editing!, newData);
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
              _editing == null ? 'Checklist salvo!' : 'Checklist atualizado!'),
          content: Text(_editing == null
              ? 'Os dados foram registrados com sucesso.'
              : 'As alterações foram salvas e sincronizadas.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: _primaryColor)),
            ),
          ],
        ),
      );

      if (_editing == null) _clearForm();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: _errorColor));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmClearForm() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Campos?'),
        content: const Text(
            'Tem certeza que deseja apagar todos os dados preenchidos? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar', style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _clearForm();
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nomeClienteCtrl.clear();
    _nomeCarroCtrl.clear();
    _placaCtrl.clear();
    _modeloCtrl.clear();
    _marcaCtrl.clear();
    _anoCtrl.clear();
    _corCtrl.clear();
    _observacoesCtrl.clear();
    _fotos.clear();
    setState(() {
       _currentStep = 0; // Reseta para a primeira etapa
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Checklist' : 'Novo Checklist',
          style:
              const TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
        elevation: 1.0,
        actions: [
          if (!isEditing)
            IconButton(
              tooltip: 'Limpar campos',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _isSaving ? null : _confirmClearForm,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          
          // --- 🐞 INÍCIO DA CORREÇÃO (2/2): Ligando as funções ---
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          // --- 🐞 FIM DA CORREÇÃO (2/2) ---

          // Botões de controle customizados (Doc 4.4)
          controlsBuilder: (context, details) {
            final bool isLastStep = _currentStep == 1;
            
            // Lógica antiga estava correta, mas 'details.onStepContinue' era nulo
            return Container(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  // Botão "Salvar" ou "Continuar"
                  FilledButton.icon(
                    // Agora, 'details.onStepContinue' está ligado a '_onStepContinue'
                    // e não será nulo. O botão será habilitado.
                    onPressed: _isSaving ? null : (isLastStep ? _submit : details.onStepContinue),
                    icon: isLastStep
                        ? (_isSaving 
                            ? Container( // Indicador de Loading
                                width: 20,
                                height: 20,
                                // 🐞 CORREÇÃO: Removido 'const' para o widget dinâmico
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded))
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      isLastStep
                          ? (_isSaving ? 'SALVANDO...' : 'SALVAR CHECKLIST')
                          : 'CONTINUAR',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor, // Azul
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Botão "Voltar"
                  if (_currentStep > 0)
                    TextButton(
                      // Agora, 'details.onStepCancel' está ligado a '_onStepCancel'
                      onPressed: _isSaving ? null : details.onStepCancel,
                      child: const Text('Voltar', style: TextStyle(color: _secondaryTextColor)),
                    ),
                ],
              ),
            );
          },
          steps: [
            // --- ETAPA 1: IDENTIFICAÇÃO ---
            _buildStep(
              title: 'Identificação',
              step: 0,
              content: [
                _tf(_nomeClienteCtrl, 'Nome do Cliente*'),
                _tf(_nomeCarroCtrl, 'Nome do Carro*'),
                _tf(
                  _placaCtrl,
                  'Placa*',
                  textCapitalization: TextCapitalization.characters, // Doc 6.0
                  validator: (v) {
                    if (v == null || v.trim().length != 7) return 'Placa inválida';
                    return null;
                  },
                ),
                _tf(_modeloCtrl, 'Modelo*'),
                _tf(_marcaCtrl, 'Marca*'),
                _tf(
                  _anoCtrl,
                  'Ano*',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null ||
                        n < 1900 ||
                        n > DateTime.now().year + 1) {
                      return 'Ano inválido';
                    }
                    return null;
                  },
                ),
                _tf(_corCtrl, 'Cor*'),
              ],
            ),
            // --- ETAPA 2: DANOS E FOTOS ---
            _buildStep(
              title: 'Danos e Fotos',
              step: 1,
              // 🐞 CORREÇÃO: O conteúdo deste passo não precisa de validação,
              // então passamos 'needsValidation: false'
              needsValidation: false,
              content: [
                TextFormField(
                  controller: _observacoesCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: _inputDecoration('Observações / Danos (opcional)'),
                  // Sem validador, pois é opcional
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

  /// Helper para criar um Step (Evita repetição)
  Step _buildStep({
    required String title,
    required int step,
    required List<Widget> content,
    bool needsValidation = true, // 🐞 CORREÇÃO: Adicionado
  }) {
    bool isActive = _currentStep >= step;
    StepState state = StepState.indexed;

    if (_currentStep > step) {
      state = StepState.complete;
    } 
    // 🐞 CORREÇÃO: Se o passo atual falhou na validação, marca como erro
    else if (isActive && needsValidation && _formKey.currentState != null && !_formKey.currentState!.validate()) {
       state = StepState.error;
    }

    return Step(
      title: Text(title),
      isActive: isActive,
      state: state,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  // --- Helpers de Widget com novo Design System ---

  /// Helper para a nova decoração (Doc 4.1)
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _secondaryTextColor),
      filled: true,
      fillColor: _cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _secondaryTextColor.withOpacity(0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _secondaryTextColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2.0), // Foco Azul
      ),
      // 🐞 CORREÇÃO: Estilo de erro para quando a validação falha
       errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _errorColor, width: 2.0),
      ),
    );
  }

  /// Helper para o TextField padrão
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
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
              return null;
            },
      ),
    );
  }

  /// Helper para o botão "Adicionar Foto" (Cor Secundária - Âmbar)
  Widget _buildAddPhotoButton() {
    return ElevatedButton.icon(
      onPressed: _addPhoto,
      icon: const Icon(Icons.add_a_photo_outlined, size: 22),
      label: const Text('ADICIONAR FOTO'),
      style: ElevatedButton.styleFrom(
        foregroundColor: _textColor, // Texto escuro
        backgroundColor: _secondaryColor, // Fundo Âmbar (Doc 4.1)
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  /// Helper para o grid de fotos
  Widget _buildPhotoGrid() {
    if (_fotos.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _secondaryTextColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: _secondaryTextColor, size: 36),
            SizedBox(height: 4),
            Text('Nenhuma foto adicionada.', style: TextStyle(color: _secondaryTextColor)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fotos.map((p) {
        final imageWidget = _isHttp(p.path)
            ? Image.network(p.path,
                width: 100, height: 100, fit: BoxFit.cover)
            : Image.file(File(p.path),
                width: 100, height: 100, fit: BoxFit.cover);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Stack(
            children: [
              imageWidget,
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
                    child: const Icon(Icons.delete_forever,
                        color: Colors.white, size: 18),
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