import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/checklist.dart';
import '../models/user_role.dart';

class OrcamentoPrevioScreen extends StatefulWidget {
  final Checklist? checklist;

  const OrcamentoPrevioScreen({super.key, this.checklist});

  @override
  State<OrcamentoPrevioScreen> createState() => _OrcamentoPrevioScreenState();
}

class _OrcamentoPrevioScreenState extends State<OrcamentoPrevioScreen> {
  final TextEditingController _placaCtrl = TextEditingController();
  final TextEditingController _orcamentoCtrl = TextEditingController();
  Checklist? _selectedChecklist;

  static const Color _primary = Color(0xFFCD193C);
  static const Color _background = Color(0xFFF6F7F9);
  static const Color _text = Color(0xFF1B1B1B);
  static const Color _card = Colors.white;

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final role = app.role;
    final checklists = app.checklists;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Orçamento Prévio',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold),
        ),
        foregroundColor: _text,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione a placa',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),

                TextFormField(
                  controller: _placaCtrl,
                  decoration: InputDecoration(
                    hintText: 'Digite para buscar...',
                    filled: true,
                    fillColor: _card,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          ),

          if (_placaCtrl.text.isNotEmpty && _selectedChecklist == null)
            Expanded(
              child: ListView(
                children: checklists
                    .where(
                      (c) => c.placa.toLowerCase().contains(
                        _placaCtrl.text.toLowerCase(),
                      ),
                    )
                    .map((c) {
                      return ListTile(
                        title: Text(c.placa.toUpperCase()),
                        subtitle: Text(c.nomeCliente),
                        onTap: () {
                          setState(() {
                            _selectedChecklist = c;
                            _placaCtrl.text = c.placa.toUpperCase();
                            _orcamentoCtrl.text = c.orcamentoPrevio ?? "";
                          });
                        },
                      );
                    })
                    .toList(),
              ),
            ),

          if (_selectedChecklist != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Orçamento',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Expanded(
                      child: TextFormField(
                        controller: _orcamentoCtrl,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText:
                              'Descreva peças, valores e observações detalhadas...',
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () async {
                          if (_selectedChecklist == null ||
                              _orcamentoCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Preencha todos os campos.'),
                                backgroundColor: _primary,
                              ),
                            );
                            return;
                          }

                          // MECÂNICO NÃO EDITA ORÇAMENTO EXISTENTE
                          if (_selectedChecklist!.orcamentoPrevio != null &&
                              role != UserRole.admin) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Somente o administrador pode editar um orçamento já enviado.',
                                ),
                                backgroundColor: _primary,
                              ),
                            );
                            return;
                          }

                          final updated = Checklist(
                            id: _selectedChecklist!.id,
                            placa: _selectedChecklist!.placa,
                            nomeCliente: _selectedChecklist!.nomeCliente,
                            nomeCarro: _selectedChecklist!.nomeCarro,
                            modeloCarro: _selectedChecklist!.modeloCarro,
                            marcaCarro: _selectedChecklist!.marcaCarro,
                            anoCarro: _selectedChecklist!.anoCarro,
                            corCarro: _selectedChecklist!.corCarro,
                            observacoes: _selectedChecklist!.observacoes,
                            fotos: _selectedChecklist!.fotos,
                            createdAt: _selectedChecklist!.createdAt,
                            createdBy: _selectedChecklist!.createdBy,
                            createdByRole: _selectedChecklist!.createdByRole,
                            createdByUid: _selectedChecklist!.createdByUid,

                            orcamentoPrevio: _orcamentoCtrl.text.trim(),
                            orcamentoAutor: app.userName,
                            orcamentoData: DateTime.now(),
                          );

                          await app.updateChecklist(
                            _selectedChecklist!,
                            updated,
                          );

                          if (!mounted) return;

                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Orçamento salvo com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          /// ❗ NÃO USA MAIS POP
                          /// NÃO VOLTA TELA – PREVINE O CONGELAMENTO
                        },
                        child: const Text('SALVAR ORÇAMENTO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
