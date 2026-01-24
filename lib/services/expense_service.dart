import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'expenses';

  // Stream de todas as despesas
  Stream<List<ExpenseModel>> getExpensesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar despesa por ID
  Future<ExpenseModel?> getExpense(String expenseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(expenseId).get();
      if (doc.exists) {
        return ExpenseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar nova despesa
  Future<String> createExpense(ExpenseModel expense) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(expense.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar despesa
  Future<void> updateExpense(String expenseId, ExpenseModel expense) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(expenseId)
          .update(expense.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar despesa
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection(_collection).doc(expenseId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar despesas por período
  Future<List<ExpenseModel>> getExpensesByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('data', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar despesas de um mês/ano
  Future<List<ExpenseModel>> getExpensesByMonth(int month, int year) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      return await getExpensesByPeriod(startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total de despesas em um período
  Future<double> getTotalByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final expenses = await getExpensesByPeriod(startDate, endDate);
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total de despesas em um mês/ano
  Future<double> getTotalByMonth(int month, int year) async {
    try {
      final expenses = await getExpensesByMonth(month, year);
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Buscar despesas por categoria
  Stream<List<ExpenseModel>> getExpensesByCategoryStream(
    ExpenseCategory categoria,
  ) {
    return _firestore
        .collection(_collection)
        .where('categoria', isEqualTo: categoria.name)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Calcular total por categoria em um período
  Future<double> getTotalByCategoryAndPeriod(
    ExpenseCategory categoria,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('categoria', isEqualTo: categoria.name)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Buscar despesas pagas
  Stream<List<ExpenseModel>> getPaidExpensesStream() {
    return _firestore
        .collection(_collection)
        .where('pago', isEqualTo: true)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar despesas pendentes
  Stream<List<ExpenseModel>> getPendingExpensesStream() {
    return _firestore
        .collection(_collection)
        .where('pago', isEqualTo: false)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Marcar despesa como paga
  Future<void> markAsPaid(String expenseId, DateTime dataPagamento) async {
    try {
      await _firestore.collection(_collection).doc(expenseId).update({
        'pago': true,
        'dataPagamento': Timestamp.fromDate(dataPagamento),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Marcar despesa como não paga
  Future<void> markAsUnpaid(String expenseId) async {
    try {
      await _firestore.collection(_collection).doc(expenseId).update({
        'pago': false,
        'dataPagamento': null,
      });
    } catch (e) {
      rethrow;
    }
  }
}
