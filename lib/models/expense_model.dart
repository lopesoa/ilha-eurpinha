import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  agua,
  associacao,
  manutencao,
  limpeza,
  seguranca,
  energia,
  evento,
  administrativa,
  outro,
}

class ExpenseModel {
  final String id;
  final ExpenseCategory categoria;
  final String descricao;
  final double valor;
  final DateTime data;
  final String mesReferencia; // YYYY-MM
  final bool pago;
  final DateTime? dataPagamento;
  final String createdBy; // userId

  ExpenseModel({
    required this.id,
    required this.categoria,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.mesReferencia,
    required this.pago,
    this.dataPagamento,
    required this.createdBy,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      categoria: ExpenseCategory.values.firstWhere(
        (e) => e.name == data['categoria'],
        orElse: () => ExpenseCategory.outro,
      ),
      descricao: data['descricao'] ?? data['observacao'] ?? '',
      valor: (data['valor'] ?? 0.0).toDouble(),
      data: (data['data'] as Timestamp).toDate(),
      mesReferencia: data['mesReferencia'] ?? '',
      pago: data['pago'] ?? false,
      dataPagamento: data['dataPagamento'] != null
          ? (data['dataPagamento'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoria': categoria.name,
      'descricao': descricao,
      'valor': valor,
      'data': Timestamp.fromDate(data),
      'mesReferencia': mesReferencia,
      'pago': pago,
      'dataPagamento': dataPagamento != null
          ? Timestamp.fromDate(dataPagamento!)
          : null,
      'createdBy': createdBy,
    };
  }
}
