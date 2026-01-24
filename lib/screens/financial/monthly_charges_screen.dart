import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/house_model.dart';
import '../../models/fixed_value_model.dart';
import '../../models/fixed_payment_model.dart';
import '../../services/house_service.dart';
import '../../services/fixed_value_service.dart';
import '../../services/fixed_payment_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_display.dart';

class MonthlyChargesScreen extends StatefulWidget {
  const MonthlyChargesScreen({super.key});

  @override
  State<MonthlyChargesScreen> createState() => _MonthlyChargesScreenState();
}

class _MonthlyChargesScreenState extends State<MonthlyChargesScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.currentUser?.canManageFinances ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobranças Mensais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonthYear,
            tooltip: 'Selecionar mês/ano',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<HouseModel>>(
              stream: HouseService().getHousesByStatusStream(HouseStatus.ativa),
              builder: (context, housesSnapshot) {
                if (housesSnapshot.hasError) {
                  return ErrorDisplay(message: 'Erro ao carregar casas');
                }

                if (housesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final houses = housesSnapshot.data ?? [];

                if (houses.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma casa ativa cadastrada'),
                  );
                }

                return FutureBuilder<List<FixedPaymentModel>>(
                  future: FixedPaymentService().getPaymentsByMonth(
                    _selectedMonth,
                    _selectedYear,
                  ),
                  builder: (context, paymentsSnapshot) {
                    if (paymentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = paymentsSnapshot.data ?? [];
                    final paymentsMap = {for (var p in payments) p.houseId: p};
                    final mesReferencia = DateTime(
                      _selectedYear,
                      _selectedMonth,
                    );

                    return FutureBuilder<List<FixedValueModel>>(
                      future: FixedValueService().getActiveFixedValues(),
                      builder: (context, valuesSnapshot) {
                        if (valuesSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final allValues = valuesSnapshot.data ?? [];

                        // Filtra casas que devem aparecer na lista
                        final validHouses = houses.where((house) {
                          // Verifica período de cobrança da casa
                          if (mesReferencia.isBefore(
                            DateTime(
                              house.dataInicioCobranca.year,
                              house.dataInicioCobranca.month,
                            ),
                          )) {
                            return false;
                          }

                          // Se não é isenta de água OU não é isenta de associação, deve aparecer
                          // (só oculta se for isenta de AMBAS)
                          return !house.isento;
                        }).toList();

                        if (validHouses.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Nenhuma casa com cobranças neste período',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: validHouses.length,
                                itemBuilder: (context, index) {
                                  final house = validHouses[index];
                                  final payment = paymentsMap[house.id];

                                  // Busca valores válidos para este mês (água ou associação)
                                  FixedValueModel? aguaValue;
                                  FixedValueModel? assocValue;

                                  for (var v in allValues) {
                                    final tipoLower = v.tipo.toLowerCase();
                                    final isAgua =
                                        tipoLower.contains('água') ||
                                        tipoLower.contains('agua');
                                    final isAssoc =
                                        tipoLower.contains('associação') ||
                                        tipoLower.contains('associacao');

                                    // Verifica se o valor está vigente no mês de referência
                                    final inicioValido = !mesReferencia
                                        .isBefore(
                                          DateTime(
                                            v.dataInicio.year,
                                            v.dataInicio.month,
                                          ),
                                        );
                                    final fimValido =
                                        v.dataFim == null ||
                                        !mesReferencia.isAfter(
                                          DateTime(
                                            v.dataFim!.year,
                                            v.dataFim!.month,
                                          ),
                                        );

                                    if (inicioValido && fimValido) {
                                      if (isAgua && !house.isentaAgua)
                                        aguaValue = v;
                                      if (isAssoc && !house.isentaAssociacao)
                                        assocValue = v;
                                    }
                                  }

                                  // Calcula valor total (soma água + associação se aplicável)
                                  final valorTotal =
                                      (aguaValue?.valorPorCasa ?? 0.0) +
                                      (assocValue?.valorPorCasa ?? 0.0);

                                  return _PaymentCard(
                                    house: house,
                                    payment: payment,
                                    valorAgua: aguaValue?.valorPorCasa,
                                    valorAssociacao: assocValue?.valorPorCasa,
                                    valorTotal: valorTotal,
                                    month: _selectedMonth,
                                    year: _selectedYear,
                                    canManage: canManage,
                                    onPaymentChanged: () => setState(() {}),
                                  );
                                },
                              ),
                            ),
                            _buildSummary(payments),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final monthNames = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            '${monthNames[_selectedMonth - 1]} / $_selectedYear',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<FixedPaymentModel> payments) {
    final totalPago = payments
        .where((p) => p.pago)
        .fold(0.0, (sum, p) => sum + p.valor);
    final totalPendente = payments
        .where((p) => !p.pago)
        .fold(0.0, (sum, p) => sum + p.valor);
    final qtdPagas = payments.where((p) => p.pago).length;
    final qtdPendentes = payments.where((p) => !p.pago).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Recebido',
                  value: totalPago,
                  count: qtdPagas,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryCard(
                  title: 'Pendente',
                  value: totalPendente,
                  count: qtdPendentes,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  Future<void> _selectMonthYear() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = selected.month;
        _selectedYear = selected.year;
      });
    }
  }
}

class _PaymentCard extends StatefulWidget {
  final HouseModel house;
  final FixedPaymentModel? payment;
  final double? valorAgua;
  final double? valorAssociacao;
  final double valorTotal;
  final int month;
  final int year;
  final bool canManage;
  final VoidCallback onPaymentChanged;

  const _PaymentCard({
    required this.house,
    required this.payment,
    required this.valorAgua,
    required this.valorAssociacao,
    required this.valorTotal,
    required this.month,
    required this.year,
    required this.canManage,
    required this.onPaymentChanged,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isPaid = widget.payment?.pago ?? false;
    final hasValue = widget.valorTotal > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          'Casa ${widget.house.numero}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasValue)
              const Text(
                'Sem valores fixos vigentes',
                style: TextStyle(color: Colors.red),
              )
            else ...[
              if (widget.valorAgua != null)
                Text(
                  'Água: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(widget.valorAgua)}',
                  style: const TextStyle(fontSize: 13),
                ),
              if (widget.valorAssociacao != null)
                Text(
                  'Associação: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(widget.valorAssociacao)}',
                  style: const TextStyle(fontSize: 13),
                ),
              Text(
                'Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(widget.valorTotal)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isPaid && widget.payment?.dataPagamento != null)
                Text(
                  'Pago em: ${DateFormat('dd/MM/yyyy').format(widget.payment!.dataPagamento!)}',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                ),
            ],
          ],
        ),
        trailing: hasValue && widget.canManage
            ? _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: isPaid,
                      onChanged: (value) => _handleTogglePaid(value),
                    )
            : null,
        isThreeLine: true,
      ),
    );
  }

  Future<void> _handleTogglePaid(bool isPaid) async {
    if (!widget.canManage || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      if (isPaid) {
        await FixedPaymentService().markAsPaid(
          widget.house.id,
          widget.month,
          widget.year,
          widget.valorTotal,
          DateTime.now(),
        );
      } else {
        await FixedPaymentService().markAsUnpaid(
          widget.house.id,
          widget.month,
          widget.year,
        );
      }

      widget.onPaymentChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPaid
                  ? 'Pagamento registrado com sucesso'
                  : 'Pagamento desmarcado',
            ),
            backgroundColor: isPaid ? Colors.green : Colors.orange,
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
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double value;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '$count casa${count != 1 ? 's' : ''}',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
