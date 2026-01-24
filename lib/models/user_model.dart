import 'package:cloud_firestore/cloud_firestore.dart';

enum UserProfile { admin, presidencia, diretoria, tesouraria, usuario }

class UserModel {
  final String id;
  final String nome;
  final String email;
  final UserProfile perfil;
  final bool ativo;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    required this.ativo,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      perfil: UserProfile.values.firstWhere(
        (e) => e.name == data['perfil'],
        orElse: () => UserProfile.usuario,
      ),
      ativo: data['ativo'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'perfil': perfil.name,
      'ativo': ativo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Métodos auxiliares para permissões

  // Gestão de Usuários
  bool get canManageUsers =>
      perfil == UserProfile.admin || perfil == UserProfile.presidencia;
  bool get canDeleteUsers => perfil == UserProfile.admin;
  bool get canViewUsers =>
      perfil == UserProfile.admin || perfil == UserProfile.presidencia;

  // Gestão de Casas e Residentes
  bool get canManageHouses =>
      perfil == UserProfile.admin ||
      perfil == UserProfile.presidencia ||
      perfil == UserProfile.diretoria;
  bool get canDeleteHouses => perfil == UserProfile.admin;
  bool get canViewHouses => true; // Todos podem visualizar

  bool get canManageResidents =>
      perfil == UserProfile.admin ||
      perfil == UserProfile.presidencia ||
      perfil == UserProfile.diretoria;
  bool get canDeleteResidents => perfil == UserProfile.admin;
  bool get canViewResidents => true; // Todos podem visualizar

  // Gestão Financeira
  bool get canManageFinances =>
      perfil == UserProfile.admin || perfil == UserProfile.tesouraria;
  bool get canManageFixedValues =>
      perfil == UserProfile.admin || perfil == UserProfile.tesouraria;
  bool get canManageCharges =>
      perfil == UserProfile.admin || perfil == UserProfile.tesouraria;
  bool get canManageEntries =>
      perfil == UserProfile.admin || perfil == UserProfile.tesouraria;
  bool get canManageExpenses =>
      perfil == UserProfile.admin || perfil == UserProfile.tesouraria;
  bool get canDeleteRecords => perfil == UserProfile.admin;

  // Relatórios
  bool get canViewReports => perfil != UserProfile.usuario;
  bool get canViewMonthlyReport => perfil != UserProfile.usuario;
  bool get canViewAnnualReport => perfil != UserProfile.usuario;
  bool get canViewBalanceReport => perfil != UserProfile.usuario;
  bool get canViewResidentsReport => perfil != UserProfile.usuario;

  // Outras funcionalidades
  bool get canViewMap => true; // Todos podem visualizar o mapa

  // Helper para obter nome amigável do perfil
  String get perfilName {
    switch (perfil) {
      case UserProfile.admin:
        return 'Administrador';
      case UserProfile.presidencia:
        return 'Presidência';
      case UserProfile.diretoria:
        return 'Diretoria';
      case UserProfile.tesouraria:
        return 'Tesouraria';
      case UserProfile.usuario:
        return 'Usuário';
    }
  }
}
