import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../utils/validators.dart';

class ExpenseFormScreen extends StatefulWidget {
  final ExpenseModel? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();

  ExpenseCategory _categoria = ExpenseCategory.outro;
  DateTime _data = DateTime.now();
  bool _pago = false;
  DateTime? _dataPagamento;
  bool _isLoading = false;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _descricaoController.text = widget.expense!.descricao;
      _valorController.text = widget.expense!.valor.toStringAsFixed(2);
      _categoria = widget.expense!.categoria;
      _data = widget.expense!.data;
      _pago = widget.expense!.pago;
      _dataPagamento = widget.expense!.dataPagamento;
    }
    _dataController.text = DateFormat('dd/MM/yyyy').format(_data);
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final mesRef = DateFormat('yyyy-MM').format(_data);

      final expense = ExpenseModel(
        id: widget.expense?.id ?? '',
        descricao: _descricaoController.text.trim(),
        valor: double.parse(_valorController.text.replaceAll(',', '.')),
        data: _data,
        categoria: _categoria,
        pago: _pago,
        dataPagamento: _dataPagamento,
        mesReferencia: mesRef,
        createdBy: 'system', // TODO: usar userId do authProvider
      );

      if (isEditing) {
        await ExpenseService().updateExpense(widget.expense!.id, expense);
      } else {
        await ExpenseService().createExpense(expense);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Despesa atualizada com sucesso'
                  : 'Despesa criada com sucesso',
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() {
        _data = picked;
        _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String _getCategoriaLabel(ExpenseCategory categoria) {
    switch (categoria) {
      case ExpenseCategory.manutencao:
        return 'Manutenção';
      case ExpenseCategory.limpeza:
        return 'Limpeza';
      case ExpenseCategory.seguranca:
        return 'Segurança';
      case ExpenseCategory.energia:
        return 'Energia';
      case ExpenseCategory.agua:
        return 'Água';
      case ExpenseCategory.associacao:
        return 'Associação';
      case ExpenseCategory.evento:
        return 'Evento';
      case ExpenseCategory.administrativa:
        return 'Administrativa';
      case ExpenseCategory.outro:
        return 'Outro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Despesa' : 'Nova Despesa'),
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
                    DropdownButtonFormField<ExpenseCategory>(
                      value: _categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: ExpenseCategory.values
                          .map(
                            (categoria) => DropdownMenuItem(
                              value: categoria,
                              child: Text(_getCategoriaLabel(categoria)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _categoria = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: Validators.required('Informe a descrição'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(
                        labelText: 'Valor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'R\$ ',
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
                    TextFormField(
                      controller: _dataController,
                      decoration: const InputDecoration(
                        labelText: 'Data de Vencimento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: _selectDate,
                      validator: Validators.required('Informe a data'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Despesa paga'),
                      value: _pago,
                      onChanged: (value) {
                        setState(() {
                          _pago = value;
                          if (value) {
                            _dataPagamento = DateTime.now();
                          } else {
                            _dataPagamento = null;
                          }
                        });
                      },
                      secondary: Icon(
                        _pago ? Icons.check_circle : Icons.pending,
                        color: _pago ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (_pago && _dataPagamento != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Data de pagamento: ${DateFormat('dd/MM/yyyy').format(_dataPagamento!)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
