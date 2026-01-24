import 'package:cloud_firestore/cloud_firestore.dart';

enum ResidentType { responsavel, integrante }

class ResidentModel {
  final String id;
  final String nome;
  final DateTime dataNascimento;
  final String houseId;
  final ResidentType tipo;
  final bool status;

  ResidentModel({
    required this.id,
    required this.nome,
    required this.dataNascimento,
    required this.houseId,
    required this.tipo,
    required this.status,
  });

  factory ResidentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ResidentModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      dataNascimento: (data['dataNascimento'] as Timestamp).toDate(),
      houseId: data['houseId'] ?? '',
      tipo: ResidentType.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => ResidentType.integrante,
      ),
      status: data['status'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'dataNascimento': Timestamp.fromDate(dataNascimento),
      'houseId': houseId,
      'tipo': tipo.name,
      'status': status,
    };
  }

  // Calcula a idade atual
  int get idade {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;

    if (hoje.month < dataNascimento.month ||
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }

    return idade;
  }

  // Verifica se é criança (< 12 anos)
  bool get isCrianca => idade < 12;
}
