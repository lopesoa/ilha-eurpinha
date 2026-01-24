import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fixed_payment_model.dart';

class FixedPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fixed_payments';

  // Stream de todos os pagamentos
  Stream<List<FixedPaymentModel>> getPaymentsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('ano', descending: true)
        .orderBy('mes', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FixedPaymentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream de pagamentos por casa
  Stream<List<FixedPaymentModel>> getPaymentsByHouseStream(String houseId) {
    return _firestore
        .collection(_collection)
        .where('houseId', isEqualTo: houseId)
        .orderBy('ano', descending: true)
        .orderBy('mes', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FixedPaymentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar pagamentos de um mês/ano específico
  Future<List<FixedPaymentModel>> getPaymentsByMonth(
    int month,
    int year,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('mes', isEqualTo: month)
          .where('ano', isEqualTo: year)
          .get();

      return snapshot.docs
          .map((doc) => FixedPaymentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar pagamento específico de uma casa em um mês/ano
  Future<FixedPaymentModel?> getPayment(
    String houseId,
    int month,
    int year,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('houseId', isEqualTo: houseId)
          .where('mes', isEqualTo: month)
          .where('ano', isEqualTo: year)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FixedPaymentModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar novo pagamento
  Future<String> createPayment(FixedPaymentModel payment) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(payment.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar pagamento
  Future<void> updatePayment(
    String paymentId,
    FixedPaymentModel payment,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(paymentId)
          .update(payment.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Marcar como pago
  Future<void> markAsPaid(
    String houseId,
    int month,
    int year,
    double valor,
    DateTime dataPagamento,
  ) async {
    try {
      final existing = await getPayment(houseId, month, year);

      if (existing != null) {
        // Atualizar existente
        final updated = FixedPaymentModel(
          id: existing.id,
          houseId: houseId,
          mes: month,
          ano: year,
          valor: valor,
          pago: true,
          dataPagamento: dataPagamento,
        );
        await updatePayment(existing.id, updated);
      } else {
        // Criar novo
        final payment = FixedPaymentModel(
          id: '',
          houseId: houseId,
          mes: month,
          ano: year,
          valor: valor,
          pago: true,
          dataPagamento: dataPagamento,
        );
        await createPayment(payment);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Marcar como não pago
  Future<void> markAsUnpaid(String houseId, int month, int year) async {
    try {
      final existing = await getPayment(houseId, month, year);

      if (existing != null) {
        final updated = FixedPaymentModel(
          id: existing.id,
          houseId: houseId,
          mes: month,
          ano: year,
          valor: existing.valor,
          pago: false,
          dataPagamento: null,
        );
        await updatePayment(existing.id, updated);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Deletar pagamento
  Future<void> deletePayment(String paymentId) async {
    try {
      await _firestore.collection(_collection).doc(paymentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total recebido em um mês/ano
  Future<double> getTotalReceived(int month, int year) async {
    try {
      final payments = await getPaymentsByMonth(month, year);
      return payments
          .where((p) => p.pago)
          .fold<double>(0.0, (sum, p) => sum + p.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total pendente em um mês/ano
  Future<double> getTotalPending(int month, int year) async {
    try {
      final payments = await getPaymentsByMonth(month, year);
      return payments
          .where((p) => !p.pago)
          .fold<double>(0.0, (sum, p) => sum + p.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Contar casas que pagaram em um mês/ano
  Future<int> getPaidCount(int month, int year) async {
    try {
      final payments = await getPaymentsByMonth(month, year);
      return payments.where((p) => p.pago).length;
    } catch (e) {
      rethrow;
    }
  }

  // Contar casas pendentes em um mês/ano
  Future<int> getPendingCount(int month, int year) async {
    try {
      final payments = await getPaymentsByMonth(month, year);
      return payments.where((p) => !p.pago).length;
    } catch (e) {
      rethrow;
    }
  }
}
