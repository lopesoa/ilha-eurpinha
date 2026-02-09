import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/house_model.dart';
import '../../models/resident_model.dart';
import '../../services/house_service.dart';
import '../../services/resident_service.dart';
import '../../services/fixed_value_service.dart';
import '../../utils/validators.dart';

class HouseFormScreen extends StatefulWidget {
  final HouseModel? house;

  const HouseFormScreen({super.key, this.house});

  @override
  State<HouseFormScreen> createState() => _HouseFormScreenState();
}

class _HouseFormScreenState extends State<HouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificadorController = TextEditingController();
  final _dataInicioController = TextEditingController();

  HouseStatus _status = HouseStatus.ativa;
  bool _associado = true; // Nova flag para indicar se é associado
  DateTime _dataInicioCobranca = DateTime(2026, 1, 1);
  bool _isLoading = false;
  List<String> _availableFixedTypes = [];
  Map<String, bool> _isencoes = {}; // Mapa dinâmico de isenções por tipo

  bool get isEditing => widget.house != null;

  @override
  void initState() {
    super.initState();
    _loadAvailableFixedTypes();
    if (isEditing) {
      _identificadorController.text = widget.house!.identificador;
      _status = widget.house!.status;
      _associado = widget.house!.associado;
      _dataInicioCobranca = widget.house!.dataInicioCobranca;
      // Inicializa isenções com valores da casa
      _isencoes = {
        'água': widget.house!.isentaAgua,
        'agua': widget.house!.isentaAgua,
        'associação': widget.house!.isentaAssociacao,
        'associacao': widget.house!.isentaAssociacao,
      };
    }
    _dataInicioController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(_dataInicioCobranca);
  }

  Future<void> _loadAvailableFixedTypes() async {
    try {
      final activeValues = await FixedValueService().getActiveFixedValues();
      if (mounted) {
        setState(() {
          _availableFixedTypes = activeValues
              .map((v) => v.tipo)
              .toSet()
              .toList();
          // Inicializa isenções para todos os tipos disponíveis
          for (var tipo in _availableFixedTypes) {
            final tipoLower = tipo.toLowerCase();
            if (!_isencoes.containsKey(tipoLower)) {
              _isencoes[tipoLower] = false;
            }
          }
        });
      }
    } catch (e) {
      // Se não houver valores, mantém lista vazia
    }
  }

  @override
  void dispose() {
    _identificadorController.dispose();
    _dataInicioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Extrai valores de água e associação do mapa dinâmico
      final isentaAgua = _isencoes.entries
          .where(
            (e) =>
                e.key.toLowerCase().contains('água') ||
                e.key.toLowerCase().contains('agua'),
          )
          .any((e) => e.value);

      final isentaAssociacao = _isencoes.entries
          .where(
            (e) =>
                e.key.toLowerCase().contains('associação') ||
                e.key.toLowerCase().contains('associacao'),
          )
          .any((e) => e.value);

      // Se não é associado, força isentaAssociacao = true
      final isentaAssociacaoFinal = !_associado ? true : isentaAssociacao;

      final house = HouseModel(
        id: widget.house?.id ?? '',
        identificador: _identificadorController.text.trim(),
        status: _status,
        associado: _associado,
        isentaAgua: isentaAgua,
        isentaAssociacao: isentaAssociacaoFinal,
        dataInicioCobranca: _dataInicioCobranca,
        createdAt: widget.house?.createdAt ?? DateTime.now(),
        mapX: widget.house?.mapX,
        mapY: widget.house?.mapY,
      );

      if (isEditing) {
        await HouseService().updateHouse(widget.house!.id, house);
      } else {
        await HouseService().createHouse(house);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Casa atualizada!' : 'Casa criada!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicioCobranca,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dataInicioCobranca = picked;
        _dataInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  List<Widget> _buildExemptionSwitches() {
    if (_availableFixedTypes.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Cadastre valores fixos primeiro para configurar isenções',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ];
    }

    return _availableFixedTypes.map((tipo) {
      final tipoLower = tipo.toLowerCase();
      final label = 'Isenta de $tipo';
      final value = _isencoes[tipoLower] ?? false;

      // Desabilita switch de associação se não for associado
      final isAssociacaoType = tipoLower.contains('associa');
      final isDisabled = _isLoading || (isAssociacaoType && !_associado);

      return SwitchListTile(
        title: Text(label),
        subtitle: isAssociacaoType && !_associado
            ? const Text(
                'Casa não associada - automaticamente isenta',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              )
            : null,
        value: value,
        onChanged: isDisabled
            ? null
            : (v) => setState(() {
                _isencoes[tipoLower] = v;
              }),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar Casa' : 'Nova Casa')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _identificadorController,
              decoration: const InputDecoration(
                labelText: 'Identificador',
                hintText: 'Ex: Casa 01',
                prefixIcon: Icon(Icons.tag),
                border: OutlineInputBorder(),
              ),
              validator: Validators.required(
                'Identificador \u00e9 obrigat\u00f3rio',
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HouseStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
              ),
              items: HouseStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s == HouseStatus.ativa ? 'Ativa' : 'Inativa'),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Associado'),
              subtitle: const Text(
                'Casas não associadas ficam isentas de cobranças de associação',
              ),
              value: _associado,
              onChanged: _isLoading
                  ? null
                  : (v) {
                      setState(() {
                        _associado = v;
                        // Se marcar como não associado, automaticamente isenta associação
                        if (!v) {
                          for (var key in _isencoes.keys) {
                            if (key.toLowerCase().contains('associa')) {
                              _isencoes[key] = true;
                            }
                          }
                        }
                      });
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataInicioController,
              decoration: const InputDecoration(
                labelText: 'Data Início Cobrança',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _isLoading ? null : _selectDate,
            ),
            const SizedBox(height: 16),
            ..._buildExemptionSwitches(),
            const SizedBox(height: 24),

            // Seção de Moradores (somente se estiver editando)
            if (isEditing) ...[
              const Divider(height: 32),
              Text(
                'Moradores da Casa',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildResidentsSection(),
              const SizedBox(height: 24),
            ],

            FilledButton(
              onPressed: _isLoading ? null : _handleSave,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentsSection() {
    return StreamBuilder<List<ResidentModel>>(
      stream: ResidentService().getResidentsByHouseStream(widget.house!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Erro ao carregar moradores: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final residents = snapshot.data ?? [];

        if (residents.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum morador cadastrado',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        // Separa por tipo
        final responsaveis = residents
            .where((r) => r.tipo == ResidentType.responsavel)
            .toList();
        final criancas = residents.where((r) => r.isCrianca).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResidentStat(
                      'Total',
                      residents.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildResidentStat(
                      'Responsáveis',
                      responsaveis.length.toString(),
                      Icons.shield,
                      Colors.green,
                    ),
                    _buildResidentStat(
                      'Crianças',
                      criancas.length.toString(),
                      Icons.child_care,
                      Colors.orange,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Lista de moradores
                ...residents.map((resident) => _buildResidentTile(resident)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResidentStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildResidentTile(ResidentModel resident) {
    final isResponsavel = resident.tipo == ResidentType.responsavel;
    final isCrianca = resident.isCrianca;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isResponsavel
            ? Colors.green.shade100
            : isCrianca
            ? Colors.orange.shade100
            : Colors.blue.shade100,
        child: Icon(
          isResponsavel
              ? Icons.shield
              : isCrianca
              ? Icons.child_care
              : Icons.person,
          color: isResponsavel
              ? Colors.green.shade700
              : isCrianca
              ? Colors.orange.shade700
              : Colors.blue.shade700,
          size: 20,
        ),
      ),
      title: Text(
        resident.nome,
        style: TextStyle(
          fontWeight: isResponsavel ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Text('${resident.idade} anos'),
          if (isResponsavel) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'RESPONSÁVEL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
          if (isCrianca) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CRIANÇA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        DateFormat('dd/MM/yyyy').format(resident.dataNascimento),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }
}
