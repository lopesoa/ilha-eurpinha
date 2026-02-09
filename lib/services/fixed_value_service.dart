import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fixed_value_model.dart';

class FixedValueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'fixed_values';

  // Stream de todos os valores fixos
  Stream<List<FixedValueModel>> getFixedValuesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('dataInicio', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FixedValueModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream de valores fixos por casa
  Stream<List<FixedValueModel>> getFixedValuesByHouseStream(String houseId) {
    return _firestore
        .collection(_collection)
        .where('houseId', isEqualTo: houseId)
        .orderBy('dataInicio', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FixedValueModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar valor fixo ativo de uma casa
  Future<FixedValueModel?> getActiveFixedValue(String houseId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('houseId', isEqualTo: houseId)
          .where('dataInicio', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('dataInicio', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final value = FixedValueModel.fromFirestore(snapshot.docs.first);
        // Verifica se ainda está ativo (sem data fim ou data fim no futuro)
        if (value.dataFim == null || value.dataFim!.isAfter(now)) {
          return value;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Buscar valor fixo por ID
  Future<FixedValueModel?> getFixedValue(String valueId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(valueId).get();
      if (doc.exists) {
        return FixedValueModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar novo valor fixo
  Future<String> createFixedValue(FixedValueModel value) async {
    try {
      // Antes de criar, fecha o ciclo do valor anterior do mesmo tipo
      await _closeActiveValueOfType(value.tipo, value.dataInicio);

      final docRef = await _firestore
          .collection(_collection)
          .add(value.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Fecha o valor ativo anterior do mesmo tipo
  Future<void> _closeActiveValueOfType(
    String tipo,
    DateTime newStartDate,
  ) async {
    try {
      // Busca o valor ativo atual do mesmo tipo
      final snapshot = await _firestore
          .collection(_collection)
          .where('tipo', isEqualTo: tipo)
          .where('ativo', isEqualTo: true)
          .get();

      // Fecha cada valor ativo, definindo dataFim como o dia anterior ao novo início
      for (var doc in snapshot.docs) {
        final dataFim = newStartDate.subtract(const Duration(days: 1));
        await doc.reference.update({
          'dataFim': Timestamp.fromDate(dataFim),
          'ativo': false,
        });
      }
    } catch (e) {
      // Se não houver valores anteriores, continua normalmente
    }
  }

  // Buscar valor fixo vigente em uma data específica para um tipo
  Future<FixedValueModel?> getValueByTypeAndDate(
    String tipo,
    DateTime referenceDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('tipo', isEqualTo: tipo)
          .where(
            'dataInicio',
            isLessThanOrEqualTo: Timestamp.fromDate(referenceDate),
          )
          .orderBy('dataInicio', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final value = FixedValueModel.fromFirestore(snapshot.docs.first);
        // Verifica se a data de referência está dentro do período de vigência
        if (value.dataFim == null ||
            value.dataFim!.isAfter(referenceDate) ||
            value.dataFim!.isAtSameMomentAs(referenceDate)) {
          return value;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar valor fixo
  Future<void> updateFixedValue(String valueId, FixedValueModel value) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(valueId)
          .update(value.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar valor fixo
  Future<void> deleteFixedValue(String valueId) async {
    try {
      await _firestore.collection(_collection).doc(valueId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar valores fixos ativos (sem data fim ou data fim no futuro)
  Stream<List<FixedValueModel>> getActiveFixedValuesStream() {
    final now = DateTime.now();
    return _firestore
        .collection(_collection)
        .where('dataInicio', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('dataInicio', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FixedValueModel.fromFirestore(doc))
              .where(
                (value) => value.dataFim == null || value.dataFim!.isAfter(now),
              )
              .toList();
        });
  }

  // Buscar valores fixos ativos como Future
  Future<List<FixedValueModel>> getActiveFixedValues() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('ativo', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => FixedValueModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar todos os valores fixos de um mês/ano específico
  Future<List<FixedValueModel>> getFixedValuesByMonth(
    int month,
    int year,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final snapshot = await _firestore
          .collection(_collection)
          .where('dataInicio', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('dataInicio', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FixedValueModel.fromFirestore(doc))
          .where(
            (value) =>
                value.dataFim == null || value.dataFim!.isAfter(startDate),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
