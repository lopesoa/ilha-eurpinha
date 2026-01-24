import 'package:cloud_firestore/cloud_firestore.dart';

class FixedValueModel {
  final String id;
  final String tipo;
  final double valorPorCasa;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final bool ativo;

  FixedValueModel({
    required this.id,
    required this.tipo,
    required this.valorPorCasa,
    required this.dataInicio,
    this.dataFim,
    required this.ativo,
  });

  factory FixedValueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FixedValueModel(
      id: doc.id,
      tipo: data['tipo'] ?? '',
      valorPorCasa: (data['valorPorCasa'] ?? data['valor'] ?? 0.0).toDouble(),
      dataInicio: (data['dataInicio'] as Timestamp).toDate(),
      dataFim: data['dataFim'] != null
          ? (data['dataFim'] as Timestamp).toDate()
          : null,
      ativo: data['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipo': tipo,
      'valorPorCasa': valorPorCasa,
      'dataInicio': Timestamp.fromDate(dataInicio),
      'dataFim': dataFim != null ? Timestamp.fromDate(dataFim!) : null,
      'ativo': ativo,
    };
  }
}
