import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/entry_model.dart';

class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'entries';

  // Stream de todas as entradas
  Stream<List<EntryModel>> getEntriesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar entrada por ID
  Future<EntryModel?> getEntry(String entryId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(entryId).get();
      if (doc.exists) {
        return EntryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar nova entrada
  Future<String> createEntry(EntryModel entry) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(entry.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar entrada
  Future<void> updateEntry(String entryId, EntryModel entry) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(entryId)
          .update(entry.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar entrada
  Future<void> deleteEntry(String entryId) async {
    try {
      await _firestore.collection(_collection).doc(entryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar entradas por período
  Future<List<EntryModel>> getEntriesByPeriod(
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

      return snapshot.docs.map((doc) => EntryModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar entradas de um mês/ano
  Future<List<EntryModel>> getEntriesByMonth(int month, int year) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      return await getEntriesByPeriod(startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total de entradas em um período
  Future<double> getTotalByPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final entries = await getEntriesByPeriod(startDate, endDate);
      return entries.fold<double>(0.0, (sum, entry) => sum + entry.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Calcular total de entradas em um mês/ano
  Future<double> getTotalByMonth(int month, int year) async {
    try {
      final entries = await getEntriesByMonth(month, year);
      return entries.fold<double>(0.0, (sum, entry) => sum + entry.valor);
    } catch (e) {
      rethrow;
    }
  }

  // Buscar entradas por tipo
  Stream<List<EntryModel>> getEntriesByTypeStream(EntryType tipo) {
    return _firestore
        .collection(_collection)
        .where('tipo', isEqualTo: tipo.name)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EntryModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Calcular total por tipo em um período
  Future<double> getTotalByTypeAndPeriod(
    EntryType tipo,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('tipo', isEqualTo: tipo.name)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final entries = snapshot.docs
          .map((doc) => EntryModel.fromFirestore(doc))
          .toList();

      return entries.fold<double>(0.0, (sum, entry) => sum + entry.valor);
    } catch (e) {
      rethrow;
    }
  }
}
