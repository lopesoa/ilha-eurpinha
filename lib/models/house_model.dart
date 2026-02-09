import 'package:cloud_firestore/cloud_firestore.dart';

enum HouseStatus { ativa, inativa }

class HouseModel {
  final String id;
  final String identificador;
  final HouseStatus status;
  final bool associado; // Se a casa é associada ou não
  final bool isentaAgua;
  final bool isentaAssociacao;
  final DateTime dataInicioCobranca;
  final DateTime createdAt;
  final double? mapX; // Coordenada X relativa (0-1)
  final double? mapY; // Coordenada Y relativa (0-1)

  HouseModel({
    required this.id,
    required this.identificador,
    required this.status,
    this.associado = true, // Por padrão é associado
    required this.isentaAgua,
    required this.isentaAssociacao,
    required this.dataInicioCobranca,
    required this.createdAt,
    this.mapX,
    this.mapY,
  });

  factory HouseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final associado = data['associado'] ?? true;
    return HouseModel(
      id: doc.id,
      identificador: data['identificador'] ?? '',
      status: HouseStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => HouseStatus.ativa,
      ),
      associado: associado,
      isentaAgua: data['isentaAgua'] ?? false,
      // Se não é associado, automaticamente isento de associação
      isentaAssociacao: !associado
          ? true
          : (data['isentaAssociacao'] ?? data['isentaLuz'] ?? false),
      dataInicioCobranca: (data['dataInicioCobranca'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      mapX: data['mapX']?.toDouble(),
      mapY: data['mapY']?.toDouble(),
    );
  }

  // Getter para compatibilidade
  String get numero => identificador;

  // Verifica se é isenta de ambas as cobranças
  bool get isento => isentaAgua && isentaAssociacao;

  // Compatibilidade com código legado
  bool get isentaLuz => isentaAssociacao;

  Map<String, dynamic> toFirestore() {
    return {
      'identificador': identificador,
      'status': status.name,
      'associado': associado,
      'isentaAgua': isentaAgua,
      'isentaAssociacao': isentaAssociacao,
      'dataInicioCobranca': Timestamp.fromDate(dataInicioCobranca),
      'createdAt': Timestamp.fromDate(createdAt),
      'mapX': mapX,
      'mapY': mapY,
    };
  }

  // Verifica se deve gerar cobrança
  bool shouldGenerateCharge(DateTime mesReferencia, String tipo) {
    // Sistema válido apenas a partir de janeiro/2026
    final dataMinima = DateTime(2026, 1, 1);

    // Verifica se a casa está ativa
    if (status != HouseStatus.ativa) return false;

    // Verifica se está isenta
    if (tipo == 'agua' && isentaAgua) return false;
    if (tipo == 'associacao' && isentaAssociacao) return false;

    // Verifica se o mês é >= janeiro/2026
    if (mesReferencia.isBefore(dataMinima)) return false;

    // Verifica se o mês é >= data de início da cobrança
    if (mesReferencia.isBefore(dataInicioCobranca)) return false;

    return true;
  }
}
