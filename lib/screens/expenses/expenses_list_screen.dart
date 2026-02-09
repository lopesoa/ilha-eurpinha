import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'expense_form_screen.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  ExpenseCategory? _selectedCategoria;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Recarrega os dados do usuário para garantir permissões atualizadas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      authProvider.reloadUserData();
    });
  }

  List<ExpenseModel> _applyFilters(List<ExpenseModel> expenses) {
    return expenses.where((expense) {
      // Filtro de data
      final isInDateRange =
          expense.data.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          expense.data.isBefore(_endDate.add(const Duration(days: 1)));

      // Filtro de categoria
      final matchesCategoria =
          _selectedCategoria == null || expense.categoria == _selectedCategoria;

      // Filtro de descrição
      final matchesSearch =
          _searchQuery.isEmpty ||
          expense.descricao.toLowerCase().contains(_searchQuery.toLowerCase());

      return isInDateRange && matchesCategoria && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros ativos
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // Barra de busca
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por descrição...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 8),
                // Chips de filtros ativos
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(
                        '${DateFormat('dd/MM/yy').format(_startDate)} - ${DateFormat('dd/MM/yy').format(_endDate)}',
                      ),
                      onSelected: (_) => _showFilterDialog(),
                      avatar: const Icon(Icons.calendar_today, size: 16),
                    ),
                    if (_selectedCategoria != null)
                      FilterChip(
                        label: Text(_getCategoriaLabel(_selectedCategoria!)),
                        onDeleted: () =>
                            setState(() => _selectedCategoria = null),
                        onSelected: (_) => _showFilterDialog(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de despesas
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: ExpenseService().getExpensesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorDisplay(message: 'Erro ao carregar despesas');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allExpenses = snapshot.data ?? [];
                final expenses = _applyFilters(allExpenses);

                if (expenses.isEmpty) {
                  return const EmptyState(
                    icon: Icons.trending_down,
                    message: 'Nenhuma despesa encontrada',
                  );
                }

                // Agrupar por mês/ano
                final groupedExpenses = <String, List<ExpenseModel>>{};
                for (var expense in expenses) {
                  final key = DateFormat(
                    'MMMM yyyy',
                    'pt_BR',
                  ).format(expense.data);
                  groupedExpenses.putIfAbsent(key, () => []).add(expense);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedExpenses.length,
                  itemBuilder: (context, index) {
                    final key = groupedExpenses.keys.elementAt(index);
                    final monthExpenses = groupedExpenses[key]!;
                    final total = monthExpenses.fold(
                      0.0,
                      (sum, expense) => sum + expense.valor,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                key.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'pt_BR',
                                  symbol: 'R\$',
                                ).format(total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...monthExpenses.map(
                          (expense) => _ExpenseCard(
                            expense: expense,
                            canManage: canManage,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Despesa'),
            )
          : null,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtros'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro de data
                  const Text(
                    'Período',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat('dd/MM/yy').format(_startDate),
                          ),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() => _startDate = date);
                            }
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('até'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(DateFormat('dd/MM/yy').format(_endDate)),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() => _endDate = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Filtro de categoria
                  const Text(
                    'Categoria',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ExpenseCategory?>(
                    value: _selectedCategoria,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      ...ExpenseCategory.values.map(
                        (categoria) => DropdownMenuItem(
                          value: categoria,
                          child: Text(_getCategoriaLabel(categoria)),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => _selectedCategoria = value),
                  ),
                  const SizedBox(height: 16),
                  // Atalhos de período
                  const Text(
                    'Atalhos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.today, size: 16),
                        label: const Text('Mês Atual'),
                        onPressed: () {
                          setDialogState(() {
                            _startDate = DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              1,
                            );
                            _endDate = DateTime(
                              DateTime.now().year,
                              DateTime.now().month + 1,
                              0,
                            );
                          });
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Último Mês'),
                        onPressed: () {
                          setDialogState(() {
                            final lastMonth = DateTime(
                              DateTime.now().year,
                              DateTime.now().month - 1,
                            );
                            _startDate = DateTime(
                              lastMonth.year,
                              lastMonth.month,
                              1,
                            );
                            _endDate = DateTime(
                              lastMonth.year,
                              lastMonth.month + 1,
                              0,
                            );
                          });
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_view_month, size: 16),
                        label: const Text('Últimos 3 Meses'),
                        onPressed: () {
                          setDialogState(() {
                            _endDate = DateTime.now();
                            _startDate = DateTime.now().subtract(
                              const Duration(days: 90),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      1,
                    );
                    _endDate = DateTime(
                      DateTime.now().year,
                      DateTime.now().month + 1,
                      0,
                    );
                    _selectedCategoria = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Limpar'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {}); // Atualiza a lista
                  Navigator.pop(context);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
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
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final bool canManage;

  const _ExpenseCard({required this.expense, required this.canManage});

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

  Color _getCategoriaColor(ExpenseCategory categoria) {
    switch (categoria) {
      case ExpenseCategory.manutencao:
        return Colors.orange;
      case ExpenseCategory.limpeza:
        return Colors.blue;
      case ExpenseCategory.seguranca:
        return Colors.red;
      case ExpenseCategory.energia:
        return Colors.yellow.shade700;
      case ExpenseCategory.agua:
        return Colors.cyan;
      case ExpenseCategory.associacao:
        return Colors.purple.shade700;
      case ExpenseCategory.evento:
        return Colors.purple;
      case ExpenseCategory.administrativa:
        return Colors.grey;
      case ExpenseCategory.outro:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: expense.pago
              ? Colors.green.withOpacity(0.2)
              : _getCategoriaColor(expense.categoria).withOpacity(0.2),
          child: Icon(
            expense.pago ? Icons.check_circle : Icons.trending_down,
            color: expense.pago
                ? Colors.green
                : _getCategoriaColor(expense.categoria),
          ),
        ),
        title: Text(expense.descricao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getCategoriaLabel(expense.categoria),
              style: TextStyle(
                color: _getCategoriaColor(expense.categoria),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Vencimento: ${DateFormat('dd/MM/yyyy').format(expense.data)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (expense.pago && expense.dataPagamento != null)
              Text(
                'Pago em: ${DateFormat('dd/MM/yyyy').format(expense.dataPagamento!)}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$',
              ).format(expense.valor),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  if (!expense.pago)
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Marcar como pago'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'mark_unpaid',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Marcar como não pago'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(context, value),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'mark_paid':
        try {
          await ExpenseService().markAsPaid(expense.id, DateTime.now());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Despesa marcada como paga'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
            );
          }
        }
        break;
      case 'mark_unpaid':
        try {
          await ExpenseService().markAsUnpaid(expense.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Despesa marcada como não paga'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
            );
          }
        }
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseFormScreen(expense: expense),
          ),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir esta despesa?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          try {
            await ExpenseService().deleteExpense(expense.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Despesa excluída com sucesso'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao excluir: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;
    }
  }
}
