import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/entry_model.dart';
import '../../services/entry_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'entry_form_screen.dart';

class EntriesListScreen extends StatelessWidget {
  const EntriesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Entradas')),
      body: StreamBuilder<List<EntryModel>>(
        stream: EntryService().getEntriesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorDisplay(message: 'Erro ao carregar entradas');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_up,
              message: 'Nenhuma entrada registrada',
            );
          }

          // Agrupar por mês/ano
          final groupedEntries = <String, List<EntryModel>>{};
          for (var entry in entries) {
            final key = DateFormat('MMMM yyyy', 'pt_BR').format(entry.data);
            groupedEntries.putIfAbsent(key, () => []).add(entry);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final key = groupedEntries.keys.elementAt(index);
              final monthEntries = groupedEntries[key]!;
              final total = monthEntries.fold(
                0.0,
                (sum, entry) => sum + entry.valor,
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
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...monthEntries.map(
                    (entry) => _EntryCard(entry: entry, canManage: canManage),
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
                    builder: (context) => const EntryFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nova Entrada'),
            )
          : null,
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EntryModel entry;
  final bool canManage;

  const _EntryCard({required this.entry, required this.canManage});

  String _getTipoLabel(EntryType tipo) {
    switch (tipo) {
      case EntryType.doacao:
        return 'Doação';
      case EntryType.contribuicao_extra:
        return 'Contribuição Extra';
      case EntryType.evento:
        return 'Evento';
      case EntryType.multa:
        return 'Multa';
      case EntryType.outro:
        return 'Outro';
    }
  }

  Color _getTipoColor(EntryType tipo) {
    switch (tipo) {
      case EntryType.doacao:
        return Colors.purple;
      case EntryType.contribuicao_extra:
        return Colors.blue;
      case EntryType.evento:
        return Colors.orange;
      case EntryType.multa:
        return Colors.red;
      case EntryType.outro:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(entry.tipo).withOpacity(0.2),
          child: Icon(Icons.trending_up, color: _getTipoColor(entry.tipo)),
        ),
        title: Text(entry.descricao),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTipoLabel(entry.tipo),
              style: TextStyle(
                color: _getTipoColor(entry.tipo),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(entry.data),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$',
              ).format(entry.valor),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
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
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EntryFormScreen(entry: entry),
          ),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar exclusão'),
            content: const Text('Deseja realmente excluir esta entrada?'),
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
            await EntryService().deleteEntry(entry.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Entrada excluída com sucesso'),
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
