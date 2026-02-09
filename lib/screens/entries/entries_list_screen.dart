import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/entry_model.dart';
import '../../services/entry_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_display.dart';
import 'entry_form_screen.dart';

class EntriesListScreen extends StatefulWidget {
  const EntriesListScreen({super.key});

  @override
  State<EntriesListScreen> createState() => _EntriesListScreenState();
}

class _EntriesListScreenState extends State<EntriesListScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  EntryType? _selectedTipo;
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

  List<EntryModel> _applyFilters(List<EntryModel> entries) {
    return entries.where((entry) {
      // Filtro de data
      final isInDateRange =
          entry.data.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          entry.data.isBefore(_endDate.add(const Duration(days: 1)));

      // Filtro de tipo
      final matchesTipo = _selectedTipo == null || entry.tipo == _selectedTipo;

      // Filtro de descrição
      final matchesSearch =
          _searchQuery.isEmpty ||
          entry.descricao.toLowerCase().contains(_searchQuery.toLowerCase());

      return isInDateRange && matchesTipo && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entradas'),
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
                    if (_selectedTipo != null)
                      FilterChip(
                        label: Text(_getTipoLabel(_selectedTipo!)),
                        onDeleted: () => setState(() => _selectedTipo = null),
                        onSelected: (_) => _showFilterDialog(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de entradas
          Expanded(
            child: StreamBuilder<List<EntryModel>>(
              stream: EntryService().getEntriesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorDisplay(message: 'Erro ao carregar entradas');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEntries = snapshot.data ?? [];
                final entries = _applyFilters(allEntries);

                if (entries.isEmpty) {
                  return const EmptyState(
                    icon: Icons.trending_up,
                    message: 'Nenhuma entrada encontrada',
                  );
                }

                // Agrupar por mês/ano
                final groupedEntries = <String, List<EntryModel>>{};
                for (var entry in entries) {
                  final key = DateFormat(
                    'MMMM yyyy',
                    'pt_BR',
                  ).format(entry.data);
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
                          (entry) =>
                              _EntryCard(entry: entry, canManage: canManage),
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
                  // Filtro de tipo
                  const Text(
                    'Tipo de Entrada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EntryType?>(
                    value: _selectedTipo,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...EntryType.values.map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(_getTipoLabel(tipo)),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => _selectedTipo = value),
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
                    _selectedTipo = null;
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
