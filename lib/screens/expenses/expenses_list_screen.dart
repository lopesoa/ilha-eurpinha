import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'expense_form_screen.dart';

class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Despesas')),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: ExpenseService().getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Erro ao carregar despesas');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_down,
              message: 'Nenhuma despesa registrada',
            );
          }

          // Agrupar por mês/ano
          final groupedExpenses = <String, List<ExpenseModel>>{};
          for (var expense in expenses) {
            final key = DateFormat('MMMM yyyy', 'pt_BR').format(expense.data);
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
                    (expense) =>
                        _ExpenseCard(expense: expense, canManage: canManage),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
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
