import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: constant_identifier_names
enum EntryType { doacao, contribuicao_extra, evento, multa, outro }

class EntryModel {
  final String id;
  final EntryType tipo;
  final String descricao;
  final String? houseId;
  final double valor;
  final DateTime data;
  final String mesReferencia; // YYYY-MM
  final String createdBy; // userId

  EntryModel({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.houseId,
    required this.valor,
    required this.data,
    required this.mesReferencia,
    required this.createdBy,
  });

  factory EntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EntryModel(
      id: doc.id,
      tipo: EntryType.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => EntryType.outro,
      ),
      descricao: data['descricao'] ?? data['observacao'] ?? '',
      houseId: data['houseId'],
      valor: (data['valor'] ?? 0.0).toDouble(),
      data: (data['data'] as Timestamp).toDate(),
      mesReferencia: data['mesReferencia'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipo': tipo.name,
      'descricao': descricao,
      'houseId': houseId,
      'valor': valor,
      'data': Timestamp.fromDate(data),
      'mesReferencia': mesReferencia,
      'createdBy': createdBy,
    };
  }
}
