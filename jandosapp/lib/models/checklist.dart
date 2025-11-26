import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'photo_placeholder.dart';
import 'user_role.dart';

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
  final UserRole createdByRole;
  final String? createdByUid;

  // 🔥 NOVOS CAMPOS — Orçamento Prévio
  final String? orcamentoPrevio; // texto do orçamento
  final String? orcamentoAutor; // nome do criador
  final DateTime? orcamentoData; // data da criação

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
    required this.createdByRole,
    this.createdByUid,

    // 🔥 novos campos
    this.orcamentoPrevio,
    this.orcamentoAutor,
    this.orcamentoData,
  });

  // ===============================================================
  // 🔄 Converte Checklist -> Map (Firebase)
  // ===============================================================
  Map<String, dynamic> toMap() => {
    'id': id,
    'placa': placa,
    'nomeCliente': nomeCliente,
    'nomeCarro': nomeCarro,
    'modeloCarro': modeloCarro,
    'marcaCarro': marcaCarro,
    'anoCarro': anoCarro,
    'corCarro': corCarro,
    'observacoes': observacoes,
    'fotos': fotos.map((p) => p.path).toList(),

    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,

    // ignore: deprecated_member_use
    'createdByRole': describeEnum(createdByRole),

    'createdByUid': createdByUid ?? FirebaseAuth.instance.currentUser?.uid,

    // 🔥 novos campos
    'orcamentoPrevio': orcamentoPrevio,
    'orcamentoAutor': orcamentoAutor,
    'orcamentoData': orcamentoData?.millisecondsSinceEpoch,
  };

  // ===============================================================
  // 🔄 Converte Map -> Checklist (Firebase → App)
  // ===============================================================
  factory Checklist.fromMap(Map<String, dynamic> map) => Checklist(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    placa: map['placa'] ?? '',
    nomeCliente: map['nomeCliente'] ?? '',
    nomeCarro: map['nomeCarro'] ?? '',
    modeloCarro: map['modeloCarro'] ?? '',
    marcaCarro: map['marcaCarro'] ?? '',
    anoCarro: map['anoCarro'] is int
        ? map['anoCarro']
        : int.tryParse((map['anoCarro'] ?? '').toString()) ??
              DateTime.now().year,

    corCarro: map['corCarro'] ?? '',
    observacoes: map['observacoes'] ?? '',

    fotos: (map['fotos'] as List<dynamic>? ?? [])
        .map((p) => PhotoPlaceholder(p.toString()))
        .toList(),

    createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    createdBy: map['createdBy'] ?? '',

    createdByRole: (map['createdByRole'] == 'admin')
        ? UserRole.admin
        : UserRole.mechanic,

    createdByUid: map['createdByUid'],

    // 🔥 novos campos
    orcamentoPrevio: map['orcamentoPrevio'],
    orcamentoAutor: map['orcamentoAutor'],
    orcamentoData: map['orcamentoData'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['orcamentoData'])
        : null,
  );
}
