import 'photo_placeholder.dart';

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
  final List fotos;
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