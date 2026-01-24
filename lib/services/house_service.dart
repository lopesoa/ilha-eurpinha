import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/house_model.dart';

class HouseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'houses';

  // Stream de todas as casas
  Stream<List<HouseModel>> getHousesStream() {
    return _firestore
        .collection(_collection)
        .orderBy('identificador')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream de casas ativas
  Stream<List<HouseModel>> getActiveHousesStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'ativa')
        .orderBy('identificador')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar uma casa por ID
  Future<HouseModel?> getHouse(String houseId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(houseId).get();
      if (doc.exists) {
        return HouseModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar nova casa
  Future<String> createHouse(HouseModel house) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(house.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar casa
  Future<void> updateHouse(String houseId, HouseModel house) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(houseId)
          .update(house.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar casa (apenas Admin)
  Future<void> deleteHouse(String houseId) async {
    try {
      await _firestore.collection(_collection).doc(houseId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar casas por status
  Future<List<HouseModel>> getHousesByStatus(HouseStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status.name)
          .orderBy('identificador')
          .get();
      return snapshot.docs.map((doc) => HouseModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Stream de casas por status
  Stream<List<HouseModel>> getHousesByStatusStream(HouseStatus status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status.name)
        .orderBy('identificador')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HouseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Contar total de casas
  Future<int> getTotalHouses() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  // Contar casas ativas
  Future<int> getActiveHousesCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'ativa')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }
}
