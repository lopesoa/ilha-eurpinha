import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/house_model.dart';
import '../../services/house_service.dart';
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

      final house = HouseModel(
        id: widget.house?.id ?? '',
        identificador: _identificadorController.text.trim(),
        status: _status,
        isentaAgua: isentaAgua,
        isentaAssociacao: isentaAssociacao,
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

      return SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: _isLoading
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
}
