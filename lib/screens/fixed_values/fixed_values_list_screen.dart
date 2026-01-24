import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fixed_value_model.dart';
import '../../services/fixed_value_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'fixed_value_form_screen.dart';
import 'package:intl/intl.dart';

class FixedValuesListScreen extends StatefulWidget {
  const FixedValuesListScreen({super.key});

  @override
  State<FixedValuesListScreen> createState() => _FixedValuesListScreenState();
}

class _FixedValuesListScreenState extends State<FixedValuesListScreen> {
  bool _showOnlyActive = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Valores Fixos'),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyActive ? Icons.filter_alt : Icons.filter_alt_outlined,
            ),
            onPressed: () {
              setState(() => _showOnlyActive = !_showOnlyActive);
            },
            tooltip: _showOnlyActive
                ? 'Mostrar todos'
                : 'Mostrar apenas ativos',
          ),
        ],
      ),
      body: StreamBuilder<List<FixedValueModel>>(
        stream: FixedValueService().getFixedValuesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Erro ao carregar valores fixos');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final values = snapshot.data ?? [];

          if (values.isEmpty) {
            return const EmptyState(
              icon: Icons.attach_money,
              message: 'Nenhum valor fixo cadastrado',
            );
          }

          // Aplicar filtros
          final filteredValues = values.where((value) {
            if (_showOnlyActive && !value.ativo) return false;
            return true;
          }).toList();

          if (filteredValues.isEmpty) {
            return const EmptyState(
              icon: Icons.filter_list_off,
              message: 'Nenhum valor encontrado com os filtros aplicados',
            );
          }

          // Agrupar por tipo para facilitar visualização
          final groupedByType = <String, List<FixedValueModel>>{};
          for (var value in filteredValues) {
            groupedByType.putIfAbsent(value.tipo, () => []).add(value);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedByType.length,
            itemBuilder: (context, index) {
              final tipo = groupedByType.keys.elementAt(index);
              final valuesOfType = groupedByType[tipo]!;

              // Ordenar por data de início (mais recente primeiro)
              valuesOfType.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          tipo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${valuesOfType.length} ${valuesOfType.length == 1 ? 'período' : 'períodos'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...valuesOfType.map(
                    (value) =>
                        _FixedValueCard(value: value, canManage: canManage),
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
                    builder: (context) => const FixedValueFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Valor'),
            )
          : null,
    );
  }
}

class _FixedValueCard extends StatelessWidget {
  final FixedValueModel value;
  final bool canManage;

  const _FixedValueCard({required this.value, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final isActive = value.ativo;
    final tipoLower = value.tipo.toLowerCase();

    // Define cor e ícone baseado no tipo
    Color getColor() {
      if (tipoLower.contains('água') || tipoLower.contains('agua')) {
        return Colors.blue;
      } else if (tipoLower.contains('associação') ||
          tipoLower.contains('associacao')) {
        return Colors.purple;
      } else if (tipoLower.contains('limpeza')) {
        return Colors.green;
      } else if (tipoLower.contains('segurança') ||
          tipoLower.contains('seguranca')) {
        return Colors.red;
      }
      return Colors.orange;
    }

    IconData getIcon() {
      if (tipoLower.contains('água') || tipoLower.contains('agua')) {
        return Icons.water_drop;
      } else if (tipoLower.contains('associação') ||
          tipoLower.contains('associacao')) {
        return Icons.apartment;
      } else if (tipoLower.contains('limpeza')) {
        return Icons.cleaning_services;
      } else if (tipoLower.contains('segurança') ||
          tipoLower.contains('seguranca')) {
        return Icons.security;
      }
      return Icons.attach_money;
    }

    final color = getColor();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? color.withOpacity(0.2)
              : Colors.grey.shade300,
          child: Icon(getIcon(), color: isActive ? color : Colors.grey),
        ),
        title: Text(
          value.tipo,
          style: TextStyle(color: isActive ? null : Colors.grey),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$',
              ).format(value.valorPorCasa),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isActive ? null : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.dataFim == null
                  ? 'Desde ${DateFormat('dd/MM/yyyy').format(value.dataInicio)} (vigente)'
                  : 'De ${DateFormat('dd/MM/yyyy').format(value.dataInicio)} até ${DateFormat('dd/MM/yyyy').format(value.dataFim!)}',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.blue.shade700 : Colors.grey,
                fontWeight: value.dataFim == null ? FontWeight.w500 : null,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Ativo' : 'Inativo',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: canManage
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
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
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FixedValueFormScreen(value: value),
          ),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir este valor fixo?'),
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
            await FixedValueService().deleteFixedValue(value.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Valor fixo excluído com sucesso'),
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
