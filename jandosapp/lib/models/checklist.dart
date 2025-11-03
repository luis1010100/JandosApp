import 'package:flutter/foundation.dart';
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
  });

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
      };

  factory Checklist.fromMap(Map<String, dynamic> map) => Checklist(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        placa: map['placa'] ?? '',
        nomeCliente: map['nomeCliente'] ?? '',
        nomeCarro: map['nomeCarro'] ?? '',
        modeloCarro: map['modeloCarro'] ?? '',
        marcaCarro: map['marcaCarro'] ?? '',
        anoCarro: map['anoCarro'] ?? DateTime.now().year,
        corCarro: map['corCarro'] ?? '',
        observacoes: map['observacoes'] ?? '',
        fotos: (map['fotos'] as List<dynamic>? ?? []).map((p) => PhotoPlaceholder(p.toString())).toList(),
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        createdBy: map['createdBy'] ?? '',
        createdByRole: map['createdByRole'] == 'admin' ? UserRole.admin : UserRole.mechanic,
      );
}
