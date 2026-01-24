import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/resident_model.dart';
import '../../models/house_model.dart';
import '../../services/resident_service.dart';
import '../../services/house_service.dart';
import '../../utils/validators.dart';

class ResidentFormScreen extends StatefulWidget {
  final ResidentModel? resident;

  const ResidentFormScreen({super.key, this.resident});

  @override
  State<ResidentFormScreen> createState() => _ResidentFormScreenState();
}

class _ResidentFormScreenState extends State<ResidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _dataNascimentoController = TextEditingController();

  String? _selectedHouseId;
  ResidentType _tipo = ResidentType.integrante;
  DateTime _dataNascimento = DateTime.now().subtract(
    const Duration(days: 365 * 20),
  );
  bool _status = true;
  bool _isLoading = false;
  bool _loadingHouses = true;
  List<HouseModel> _houses = [];

  bool get isEditing => widget.resident != null;

  @override
  void initState() {
    super.initState();
    _loadHouses();
    if (isEditing) {
      _nomeController.text = widget.resident!.nome;
      _selectedHouseId = widget.resident!.houseId;
      _tipo = widget.resident!.tipo;
      _dataNascimento = widget.resident!.dataNascimento;
      _status = widget.resident!.status;
    }
    _dataNascimentoController.text = DateFormat(
      'dd/MM/yyyy',
    ).format(_dataNascimento);
  }

  Future<void> _loadHouses() async {
    setState(() => _loadingHouses = true);
    try {
      final houses = await HouseService().getHousesByStatus(HouseStatus.ativa);
      if (mounted) {
        setState(() {
          _houses = houses;
          _loadingHouses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHouses = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar casas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _dataNascimentoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma casa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar se já existe responsável para esta casa
    if (_tipo == ResidentType.responsavel) {
      final existingResponsible = await ResidentService().getHouseResponsible(
        _selectedHouseId!,
      );

      // Se existe responsável e não é este morador sendo editado
      if (existingResponsible != null &&
          existingResponsible.id != widget.resident?.id) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Esta casa já possui um responsável: ${existingResponsible.nome}',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final resident = ResidentModel(
        id: widget.resident?.id ?? '',
        nome: _nomeController.text.trim(),
        dataNascimento: _dataNascimento,
        houseId: _selectedHouseId!,
        tipo: _tipo,
        status: _status,
      );

      if (isEditing) {
        await ResidentService().updateResident(widget.resident!.id, resident);
      } else {
        await ResidentService().createResident(resident);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Morador atualizado!' : 'Morador criado!',
            ),
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
      initialDate: _dataNascimento,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _dataNascimento = picked;
        _dataNascimentoController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Morador' : 'Novo Morador'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Nome completo',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: Validators.name,
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dataNascimentoController,
              decoration: const InputDecoration(
                labelText: 'Data de Nascimento',
                prefixIcon: Icon(Icons.cake_outlined),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: _isLoading ? null : _selectDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedHouseId,
              decoration: InputDecoration(
                labelText: 'Casa',
                prefixIcon: _loadingHouses
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.home_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: _houses.isEmpty && !_loadingHouses
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadHouses,
                        tooltip: 'Recarregar casas',
                      )
                    : null,
              ),
              hint: _loadingHouses
                  ? const Text('Carregando casas...')
                  : _houses.isEmpty
                  ? const Text('Nenhuma casa ativa cadastrada')
                  : const Text('Selecione uma casa'),
              items: _houses
                  .map(
                    (h) => DropdownMenuItem(
                      value: h.id,
                      child: Text(h.identificador),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading || _loadingHouses || _houses.isEmpty
                  ? null
                  : (v) => setState(() => _selectedHouseId = v),
            ),
            if (_houses.isEmpty && !_loadingHouses)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cadastre uma casa ativa primeiro',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ResidentType>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.supervisor_account_outlined),
                border: OutlineInputBorder(),
              ),
              items: ResidentType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t == ResidentType.responsavel
                            ? 'Responsável'
                            : 'Integrante',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isLoading ? null : (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativo'),
              value: _status,
              onChanged: _isLoading ? null : (v) => setState(() => _status = v),
            ),
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
