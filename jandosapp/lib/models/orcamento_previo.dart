import 'package:firebase_auth/firebase_auth.dart';

class OrcamentoPrevio {
  final String id;
  final String checklistId; // 🔗 ligação direta com o checklist
  final String placa; // 🔗 usado para busca
  final String texto; // 📝 orçamento digitado
  final DateTime createdAt; // 📅 data
  final String createdBy; // 👤 nome do usuário
  final String? createdByUid; // 🔐 segurança
  final bool lockedForEdit; // 🔒 somente admin pode editar

  OrcamentoPrevio({
    required this.id,
    required this.checklistId,
    required this.placa,
    required this.texto,
    required this.createdAt,
    required this.createdBy,
    this.createdByUid,
    this.lockedForEdit = true, // 🔒 padrão: mecânico não edita depois
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'checklistId': checklistId,
    'placa': placa,
    'texto': texto,
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'createdByUid': createdByUid ?? FirebaseAuth.instance.currentUser?.uid,
    'lockedForEdit': lockedForEdit,
  };

  factory OrcamentoPrevio.fromMap(Map<String, dynamic> map) {
    return OrcamentoPrevio(
      id: map['id'],
      checklistId: map['checklistId'],
      placa: map['placa'],
      texto: map['texto'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      createdByUid: map['createdByUid'],
      lockedForEdit: map['lockedForEdit'] ?? true,
    );
  }
}
