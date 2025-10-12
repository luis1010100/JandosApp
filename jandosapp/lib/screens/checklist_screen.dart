import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/checklist.dart';
import '../models/photo_placeholder.dart';
import '../providers/app_state.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State {
  final _formKey = GlobalKey<FormState>();
  final _placaCtrl = TextEditingController();
  final _nomeClienteCtrl = TextEditingController();
  final _nomeCarroCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _anoCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final List _fotos = [];

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