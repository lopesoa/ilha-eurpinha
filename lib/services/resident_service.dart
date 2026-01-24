import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resident_model.dart';

class ResidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'residents';

  // Stream de todos os moradores
  Stream<List<ResidentModel>> getResidentsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nome')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResidentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream de moradores por casa
  Stream<List<ResidentModel>> getResidentsByHouseStream(String houseId) {
    return _firestore
        .collection(_collection)
        .where('houseId', isEqualTo: houseId)
        .orderBy('tipo', descending: true) // Responsável primeiro
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResidentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Buscar morador por ID
  Future<ResidentModel?> getResident(String residentId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(residentId)
          .get();
      if (doc.exists) {
        return ResidentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Criar novo morador
  Future<String> createResident(ResidentModel resident) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(resident.toFirestore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar morador
  Future<void> updateResident(String residentId, ResidentModel resident) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(residentId)
          .update(resident.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar morador (apenas Admin)
  Future<void> deleteResident(String residentId) async {
    try {
      await _firestore.collection(_collection).doc(residentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Buscar moradores ativos
  Stream<List<ResidentModel>> getActiveResidentsStream() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: true)
        .orderBy('nome')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ResidentModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Contar total de moradores
  Future<int> getTotalResidents() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  // Contar crianças
  Future<int> getChildrenCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: true)
          .get();

      final residents = snapshot.docs
          .map((doc) => ResidentModel.fromFirestore(doc))
          .toList();

      return residents.where((r) => r.isCrianca).length;
    } catch (e) {
      rethrow;
    }
  }

  // Contar adultos
  Future<int> getAdultsCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: true)
          .get();

      final residents = snapshot.docs
          .map((doc) => ResidentModel.fromFirestore(doc))
          .toList();

      return residents.where((r) => !r.isCrianca).length;
    } catch (e) {
      rethrow;
    }
  }

  // Buscar responsável da casa
  Future<ResidentModel?> getHouseResponsible(String houseId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('houseId', isEqualTo: houseId)
          .where('tipo', isEqualTo: 'responsavel')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ResidentModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
