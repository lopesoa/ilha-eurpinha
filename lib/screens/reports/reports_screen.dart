import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canView = authProvider.currentUser?.canViewReports ?? false;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Relatórios')),
        body: const Center(
          child: Text(
            'Você não tem permissão para visualizar relatórios',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relatórios'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'Mensal'),
              Tab(icon: Icon(Icons.calendar_today), text: 'Anual'),
              Tab(icon: Icon(Icons.account_balance_wallet), text: 'Saldo'),
              Tab(icon: Icon(Icons.people), text: 'Residentes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMonthlyTab(),
            _buildAnnualTab(),
            _buildAccountBalanceTab(),
            _buildResidentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTab() {
    return Column(
      children: [
        _buildMonthYearSelector(),
        Expanded(
          child: FutureBuilder<MonthlyReport>(
            future: ReportService().getMonthlyReport(
              _selectedMonth,
              _selectedYear,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              final report = snapshot.data!;
              return _buildMonthlyReport(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearSelector() {
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
            onPressed: () {
              setState(() {
                if (_selectedMonth == 1) {
                  _selectedMonth = 12;
                  _selectedYear--;
                } else {
                  _selectedMonth--;
                }
              });
            },
          ),
          Text(
            '${monthNames[_selectedMonth - 1]} / $_selectedYear',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_selectedMonth == 12) {
                  _selectedMonth = 1;
                  _selectedYear++;
                } else {
                  _selectedMonth++;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport(MonthlyReport report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumo Financeiro
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo Financeiro',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                _buildReportRow(
                  'Cobranças Esperadas',
                  report.totalExpected,
                  Colors.orange,
                ),
                _buildReportRow(
                  'Cobranças Pagas',
                  report.totalPaid,
                  Colors.green,
                ),
                _buildReportRow(
                  'Inadimplência',
                  report.defaultAmount,
                  Colors.red,
                ),
                const Divider(),
                _buildReportRow(
                  'Entradas Extras',
                  report.totalEntries,
                  Colors.blue,
                ),
                _buildReportRow('Despesas', report.totalExpenses, Colors.red),
                const Divider(),
                _buildReportRow(
                  'Saldo do Mês',
                  report.balance,
                  report.balance >= 0 ? Colors.green : Colors.red,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Estatísticas de Pagamento
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estatísticas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pagas',
                        report.paymentsCount.toString(),
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Pendentes',
                        report.pendingCount.toString(),
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Casas Inadimplentes
        if (report.defaulters.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Casas Inadimplentes (${report.defaulters.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ...report.defaulters.map(
                    (defaulter) => ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.warning, color: Colors.white),
                      ),
                      title: Text('Casa ${defaulter.house.identificador}'),
                      subtitle: Text(
                        'Pendente: ${defaulter.pendingTypes.join(", ")}',
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(defaulter.debtValue),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnnualTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _selectedYear--),
              ),
              Text(
                _selectedYear.toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _selectedYear++),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<AnnualReport>(
            future: ReportService().getAnnualReport(_selectedYear),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              final report = snapshot.data!;
              return _buildAnnualReport(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnualReport(AnnualReport report) {
    final monthNames = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumo Anual ${report.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                _buildReportRow(
                  'Total Esperado',
                  report.totalExpected,
                  Colors.orange,
                ),
                _buildReportRow('Total Pago', report.totalPaid, Colors.green),
                _buildReportRow(
                  'Total Entradas',
                  report.totalEntries,
                  Colors.blue,
                ),
                _buildReportRow(
                  'Total Despesas',
                  report.totalExpenses,
                  Colors.red,
                ),
                const Divider(),
                _buildReportRow(
                  'Saldo Anual',
                  report.balance,
                  report.balance >= 0 ? Colors.green : Colors.red,
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhamento Mensal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                ...report.monthlyReports.asMap().entries.map((entry) {
                  final monthReport = entry.value;
                  return ListTile(
                    title: Text(monthNames[entry.key]),
                    subtitle: Text(
                      'Saldo: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(monthReport.balance)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          ).format(monthReport.totalPaid),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (monthReport.defaulters.isNotEmpty)
                          Text(
                            '${monthReport.defaulters.length} inadimplente${monthReport.defaulters.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResidentsTab() {
    return FutureBuilder<ResidentsReport>(
      future: ReportService().getResidentsReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        final report = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Residentes da Ilha',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Total de Residentes',
                      report.totalResidents,
                      Colors.blue,
                    ),
                    _buildStatRow('Adultos', report.adults, Colors.green),
                    _buildStatRow(
                      'Crianças (< 12 anos)',
                      report.children,
                      Colors.orange,
                    ),
                    _buildStatRow(
                      'Responsáveis',
                      report.responsible,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportRow(
    String label,
    double value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value),
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildAccountBalanceTab() {
    return FutureBuilder<AccountBalanceReport>(
      future: ReportService().getAccountBalanceReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        final report = snapshot.data!;
        final currencyFormat = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        );

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumo Geral
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo em Conta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildBalanceRow(
                          'Cobranças Fixas Pagas',
                          currencyFormat.format(report.totalFixedPayments),
                          Colors.green,
                        ),
                        const Divider(),
                        _buildBalanceRow(
                          'Receitas Extras',
                          currencyFormat.format(report.totalEntries),
                          Colors.green,
                        ),
                        const Divider(),
                        _buildBalanceRow(
                          'Total de Entradas',
                          currencyFormat.format(report.totalIncome),
                          Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        _buildBalanceRow(
                          'Total de Saídas',
                          currencyFormat.format(report.totalExpenses),
                          Colors.red,
                        ),
                        const Divider(thickness: 2),
                        const SizedBox(height: 8),
                        _buildBalanceRow(
                          'Saldo Atual',
                          currencyFormat.format(report.currentBalance),
                          report.currentBalance >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Histórico Mensal
                const Text(
                  'Histórico Mensal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (report.monthlyBalances.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum movimento registrado'),
                    ),
                  )
                else
                  ...report.monthlyBalances.reversed.map((monthBalance) {
                    final monthName = DateFormat.yMMMM(
                      'pt_BR',
                    ).format(monthBalance.month);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(
                          monthName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Saldo: ${currencyFormat.format(monthBalance.balance)}',
                          style: TextStyle(
                            color: monthBalance.balance >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Cobranças Fixas:'),
                                    Text(
                                      currencyFormat.format(
                                        monthBalance.fixedPayments,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Receitas Extras:'),
                                    Text(
                                      currencyFormat.format(
                                        monthBalance.entries,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Entradas:'),
                                    Text(
                                      currencyFormat.format(
                                        monthBalance.totalIncome,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Despesas:'),
                                    Text(
                                      currencyFormat.format(
                                        monthBalance.expenses,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(thickness: 2),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Saldo do Mês:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        monthBalance.balance,
                                      ),
                                      style: TextStyle(
                                        color: monthBalance.balance >= 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
