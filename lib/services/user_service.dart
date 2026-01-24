import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Stream de todos os usuários
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nome')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  // Stream de usuários ativos
  Stream<List<UserModel>> getActiveUsersStream() {
    return _firestore
        .collection(_collection)
        .where('ativo', isEqualTo: true)
        .orderBy('nome')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  // Buscar usuário por ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Atualizar usuário (não pode criar aqui, só via AuthService)
  Future<void> updateUser(String userId, UserModel user) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  // Deletar usuário (apenas Admin)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Desativar usuário (preferível ao invés de deletar)
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'ativo': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Ativar usuário
  Future<void> activateUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'ativo': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Buscar usuários por perfil
  Future<List<UserModel>> getUsersByProfile(UserProfile profile) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('perfil', isEqualTo: profile.name)
          .orderBy('nome')
          .get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Contar total de usuários
  Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  // Contar usuários ativos
  Future<int> getActiveUsersCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('ativo', isEqualTo: true)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }
}
