import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔹 adicionado
import '../models/checklist.dart';
import '../models/photo_placeholder.dart';
import '../models/user_role.dart';
import '../providers/app_state.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key, this.editing});

  /// Se não for nulo, entra em modo edição.
  final Checklist? editing;

  @override
  State createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _formKey = GlobalKey<FormState>();

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
      _fotos.addAll(c.fotos); // já chegam como URLs (PhotoPlaceholder.path)
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

  bool _isHttp(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _addPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _fotos.add(PhotoPlaceholder(image.path))); // arquivo local
    }
  }

  void _removePhoto(PhotoPlaceholder p) {
    setState(() => _fotos.remove(p));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final app = AppStateScope.of(context);
    final user = FirebaseAuth.instance.currentUser; // 🔹 pega UID atual

    try {
      // URLs que já existiam (vieram do Firebase)
      final existingUrls = _fotos
          .where((p) => _isHttp(p.path))
          .map((p) => p.path)
          .toList();

      // Fotos novas locais (subir para o Storage)
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

      // Se edição: remover do Storage URLs que foram excluídos da lista
      if (_editing != null) {
        final oldUrls = _editing!.fotos
            .map((e) => e.path)
            .where(_isHttp)
            .toSet();
        final kept = existingUrls.toSet();
        final toDelete = oldUrls.difference(kept);
        for (final u in toDelete) {
          try {
            await FirebaseStorage.instance.refFromURL(u).delete();
          } catch (_) {
            // ignora falhas de remoção
          }
        }
      }

      final allUrls = [...existingUrls, ...uploadedUrls];
      final now = DateTime.now();

      // 🔹 Cria novo checklist com UID do usuário logado
      final newData = Checklist(
        id: _editing?.id ?? now.millisecondsSinceEpoch.toString(),
        nomeCliente: _nomeClienteCtrl.text.trim(),
        nomeCarro: _nomeCarroCtrl.text.trim(),
        placa: _placaCtrl.text.trim(),
        modeloCarro: _modeloCtrl.text.trim(),
        marcaCarro: _marcaCtrl.text.trim(),
        anoCarro: int.tryParse(_anoCtrl.text.trim()) ?? now.year,
        corCarro: _corCtrl.text.trim(),
        observacoes: _observacoesCtrl.text.trim(),
        fotos: allUrls.map((p) => PhotoPlaceholder(p)).toList(),
        createdAt: _editing?.createdAt ?? now,
        createdBy: _editing?.createdBy ?? app.userName,
        createdByRole:
            _editing?.createdByRole ?? (app.role ?? UserRole.mechanic),
        createdByUid: _editing?.createdByUid ?? user?.uid, // 🔹 salva UID
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
            _editing == null ? 'Checklist salvo!' : 'Checklist atualizado!',
          ),
          content: Text(
            _editing == null
                ? 'Os dados foram registrados com sucesso.'
                : 'As alterações foram salvas e sincronizadas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (_editing == null) _clearForm();
      // ignore: use_build_context_synchronously
      if (Navigator.canPop(context)) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // volta da tela de edição
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Checklist' : 'Novo Checklist'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tf(_nomeClienteCtrl, 'Nome do Cliente*'),
              _tf(_nomeCarroCtrl, 'Nome do Carro*'),
              _tf(
                _placaCtrl,
                'Placa*',
                validator: (v) {
                  if (v == null || v.trim().length != 7) {
                    return 'Placa inválida';
                  }
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
                  if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                    return 'Ano inválido';
                  }
                  return null;
                },
              ),
              _tf(_corCtrl, 'Cor*'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoesCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Fotos',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._fotos.map(
                    (p) => Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: _isHttp(p.path)
                              ? Image.network(p.path, fit: BoxFit.cover)
                              : Image.file(File(p.path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _removePhoto(p),
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _isSaving
                            ? 'Salvando...'
                            : (isEditing
                                ? 'Salvar Alterações'
                                : 'Salvar Checklist'),
                      ),
                    ),
                  ),
                  if (!isEditing) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpar Campos'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: validator ??
            (v) {
              if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
              return null;
            },
      ),
    );
  }
}
