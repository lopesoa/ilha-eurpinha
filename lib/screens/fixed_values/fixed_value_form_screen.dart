import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/fixed_value_model.dart';
import '../../services/fixed_value_service.dart';
import '../../utils/validators.dart';

class FixedValueFormScreen extends StatefulWidget {
  final FixedValueModel? value;

  const FixedValueFormScreen({super.key, this.value});

  @override
  State<FixedValueFormScreen> createState() => _FixedValueFormScreenState();
}

class _FixedValueFormScreenState extends State<FixedValueFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;
  bool _ativo = true;
  bool _isLoading = false;

  bool get isEditing => widget.value != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _tipoController.text = widget.value!.tipo;
      _valorController.text = widget.value!.valorPorCasa.toStringAsFixed(2);
      _dataInicio = widget.value!.dataInicio;
      _dataFim = widget.value!.dataFim;
      _ativo = widget.value!.ativo;
    }
    _dataInicioController.text = DateFormat('dd/MM/yyyy').format(_dataInicio);
    if (_dataFim != null) {
      _dataFimController.text = DateFormat('dd/MM/yyyy').format(_dataFim!);
    }
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _valorController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Se não está editando, verifica se já existe valor ativo do mesmo tipo
    if (!isEditing) {
      final activeValues = await FixedValueService().getActiveFixedValues();
      final existingActive = activeValues
          .where(
            (v) =>
                v.tipo.toLowerCase() ==
                _tipoController.text.trim().toLowerCase(),
          )
          .toList();

      if (existingActive.isNotEmpty && mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar alteração de valor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Já existe um valor ativo para este tipo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...existingActive.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• R\$ ${v.valorPorCasa.toStringAsFixed(2)} desde ${DateFormat('dd/MM/yyyy').format(v.dataInicio)}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'O valor anterior será encerrado em ${DateFormat('dd/MM/yyyy').format(_dataInicio.subtract(const Duration(days: 1)))} e o novo valor de R\$ ${double.parse(_valorController.text.replaceAll(',', '.')).toStringAsFixed(2)} entrará em vigor a partir de ${DateFormat('dd/MM/yyyy').format(_dataInicio)}.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Confirma esta alteração?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final value = FixedValueModel(
        id: widget.value?.id ?? '',
        tipo: _tipoController.text.trim(),
        valorPorCasa: double.parse(_valorController.text.replaceAll(',', '.')),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        ativo: _ativo,
      );

      if (isEditing) {
        await FixedValueService().updateFixedValue(widget.value!.id, value);
      } else {
        await FixedValueService().createFixedValue(value);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Valor fixo atualizado com sucesso'
                  : 'Valor fixo criado com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : (_dataFim ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
          _dataInicioController.text = DateFormat('dd/MM/yyyy').format(picked);
        } else {
          _dataFim = picked;
          _dataFimController.text = DateFormat('dd/MM/yyyy').format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Valor Fixo' : 'Novo Valor Fixo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _tipoController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Valor Fixo',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        hintText: 'Ex: Água, Associação, Taxa de Limpeza',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.required('Informe o tipo'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(
                        labelText: 'Valor por Casa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'R\$ ',
                        helperText:
                            'Valor que será cobrado de cada casa não isenta',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: Validators.required('Informe o valor'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      subtitle: const Text(
                        'Valores inativos não serão cobrados',
                      ),
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataInicioController,
                      decoration: const InputDecoration(
                        labelText: 'Data de Início',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(true),
                      validator: Validators.required(
                        'Informe a data de início',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataFimController,
                      decoration: InputDecoration(
                        labelText: 'Data de Fim (Opcional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: _dataFim != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _dataFim = null;
                                    _dataFimController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(false),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Atualizar' : 'Salvar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
