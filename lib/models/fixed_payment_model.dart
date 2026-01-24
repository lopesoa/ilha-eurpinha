import 'package:cloud_firestore/cloud_firestore.dart';

class FixedPaymentModel {
  final String id;
  final String houseId;
  final int mes;
  final int ano;
  final double valor;
  final bool pago;
  final DateTime? dataPagamento;

  FixedPaymentModel({
    required this.id,
    required this.houseId,
    required this.mes,
    required this.ano,
    required this.valor,
    required this.pago,
    this.dataPagamento,
  });

  factory FixedPaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    int mes;
    int ano;

    // Compatibilidade: suporta mesReferencia (YYYY-MM) ou mes/ano separados
    if (data['mesReferencia'] != null) {
      final parts = (data['mesReferencia'] as String).split('-');
      ano = int.parse(parts[0]);
      mes = int.parse(parts[1]);
    } else {
      mes = data['mes'] ?? 1;
      ano = data['ano'] ?? DateTime.now().year;
    }

    return FixedPaymentModel(
      id: doc.id,
      houseId: data['houseId'] ?? '',
      mes: mes,
      ano: ano,
      valor: (data['valor'] ?? 0.0).toDouble(),
      pago: data['pago'] ?? false,
      dataPagamento: data['dataPagamento'] != null
          ? (data['dataPagamento'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'houseId': houseId,
      'mes': mes,
      'ano': ano,
      'valor': valor,
      'pago': pago,
      'dataPagamento': dataPagamento != null
          ? Timestamp.fromDate(dataPagamento!)
          : null,
    };
  }
}
