import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/house_model.dart';
import '../models/resident_model.dart';
import '../models/fixed_payment_model.dart';
import '../models/entry_model.dart';
import '../models/expense_model.dart';
import '../models/fixed_value_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Relatório mensal consolidado
  Future<MonthlyReport> getMonthlyReport(int month, int year) async {
    try {
      final mesReferencia = DateTime(year, month);
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      // Buscar casas ativas
      final housesSnapshot = await _firestore
          .collection('houses')
          .where('status', isEqualTo: 'ativa')
          .get();

      final houses = housesSnapshot.docs
          .map((doc) => HouseModel.fromFirestore(doc))
          .toList();

      // Buscar valores fixos ativos
      final valuesSnapshot = await _firestore
          .collection('fixed_values')
          .where('ativo', isEqualTo: true)
          .get();

      final fixedValues = valuesSnapshot.docs
          .map((doc) => FixedValueModel.fromFirestore(doc))
          .toList();

      // Buscar pagamentos do mês
      final paymentsSnapshot = await _firestore
          .collection('fixed_payments')
          .where(
            'mesReferencia',
            isEqualTo:
                '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
          )
          .get();

      final payments = paymentsSnapshot.docs
          .map((doc) => FixedPaymentModel.fromFirestore(doc))
          .toList();

      // Buscar entradas do mês
      final entriesSnapshot = await _firestore
          .collection('entries')
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final entries = entriesSnapshot.docs
          .map((doc) => EntryModel.fromFirestore(doc))
          .toList();

      // Buscar despesas do mês
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final expenses = expensesSnapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      // Calcular inadimplentes (casas que deveriam pagar mas não pagaram)
      final defaulters = <HouseDefaulter>[];

      for (var house in houses) {
        // Verificar se casa deve gerar cobrança
        if (mesReferencia.isBefore(
          DateTime(
            house.dataInicioCobranca.year,
            house.dataInicioCobranca.month,
          ),
        )) {
          continue;
        }

        if (house.isento) continue; // Se isenta de tudo, não entra

        double expectedValue = 0;
        double paidValue = 0;
        final debts = <String>[];

        for (var value in fixedValues) {
          final tipoLower = value.tipo.toLowerCase();
          final isAgua =
              tipoLower.contains('água') || tipoLower.contains('agua');
          final isAssoc =
              tipoLower.contains('associação') ||
              tipoLower.contains('associacao');

          // Verifica isenção específica
          if (isAgua && house.isentaAgua) continue;
          if (isAssoc && house.isentaAssociacao) continue;

          // Verifica se valor está vigente no mês
          final inicioValido = !mesReferencia.isBefore(
            DateTime(value.dataInicio.year, value.dataInicio.month),
          );
          final fimValido =
              value.dataFim == null ||
              !mesReferencia.isAfter(
                DateTime(value.dataFim!.year, value.dataFim!.month),
              );

          if (inicioValido && fimValido) {
            expectedValue += value.valorPorCasa;

            // Verifica se foi pago
            final payment = payments.firstWhere(
              (p) => p.houseId == house.id,
              orElse: () => FixedPaymentModel(
                id: '',
                houseId: house.id,
                mes: month,
                ano: year,
                valor: 0,
                pago: false,
                dataPagamento: null,
              ),
            );

            if (payment.pago) {
              paidValue += value.valorPorCasa;
            } else {
              debts.add(value.tipo);
            }
          }
        }

        if (expectedValue > paidValue && debts.isNotEmpty) {
          defaulters.add(
            HouseDefaulter(
              house: house,
              expectedValue: expectedValue,
              paidValue: paidValue,
              debtValue: expectedValue - paidValue,
              pendingTypes: debts,
            ),
          );
        }
      }

      // Calcular totais
      final totalExpected = houses.fold<double>(0, (sum, house) {
        if (mesReferencia.isBefore(
          DateTime(
            house.dataInicioCobranca.year,
            house.dataInicioCobranca.month,
          ),
        )) {
          return sum;
        }
        if (house.isento) return sum;

        double houseExpected = 0;
        for (var value in fixedValues) {
          final tipoLower = value.tipo.toLowerCase();
          final isAgua =
              tipoLower.contains('água') || tipoLower.contains('agua');
          final isAssoc =
              tipoLower.contains('associação') ||
              tipoLower.contains('associacao');

          if (isAgua && house.isentaAgua) continue;
          if (isAssoc && house.isentaAssociacao) continue;

          final inicioValido = !mesReferencia.isBefore(
            DateTime(value.dataInicio.year, value.dataInicio.month),
          );
          final fimValido =
              value.dataFim == null ||
              !mesReferencia.isAfter(
                DateTime(value.dataFim!.year, value.dataFim!.month),
              );

          if (inicioValido && fimValido) {
            houseExpected += value.valorPorCasa;
          }
        }
        return sum + houseExpected;
      });

      final totalPaid = payments
          .where((p) => p.pago)
          .fold<double>(0, (sum, p) => sum + p.valor);

      final totalEntries = entries.fold<double>(0, (sum, e) => sum + e.valor);
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.valor);

      return MonthlyReport(
        month: month,
        year: year,
        totalExpected: totalExpected,
        totalPaid: totalPaid,
        totalEntries: totalEntries,
        totalExpenses: totalExpenses,
        defaulters: defaulters,
        paymentsCount: payments.where((p) => p.pago).length,
        pendingCount: payments.where((p) => !p.pago).length,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Relatório anual
  Future<AnnualReport> getAnnualReport(int year) async {
    try {
      final monthlyReports = <MonthlyReport>[];

      for (int month = 1; month <= 12; month++) {
        final report = await getMonthlyReport(month, year);
        monthlyReports.add(report);
      }

      final totalExpected = monthlyReports.fold<double>(
        0,
        (sum, r) => sum + r.totalExpected,
      );
      final totalPaid = monthlyReports.fold<double>(
        0,
        (sum, r) => sum + r.totalPaid,
      );
      final totalEntries = monthlyReports.fold<double>(
        0,
        (sum, r) => sum + r.totalEntries,
      );
      final totalExpenses = monthlyReports.fold<double>(
        0,
        (sum, r) => sum + r.totalExpenses,
      );

      return AnnualReport(
        year: year,
        monthlyReports: monthlyReports,
        totalExpected: totalExpected,
        totalPaid: totalPaid,
        totalEntries: totalEntries,
        totalExpenses: totalExpenses,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Relatório de residentes (crianças e adultos)
  Future<ResidentsReport> getResidentsReport() async {
    try {
      final snapshot = await _firestore.collection('residents').get();
      final residents = snapshot.docs
          .map((doc) => ResidentModel.fromFirestore(doc))
          .toList();

      final now = DateTime.now();
      int children = 0;
      int adults = 0;
      int responsible = 0;

      for (var resident in residents) {
        final age = now.year - resident.dataNascimento.year;
        if (age < 12) {
          children++;
        } else {
          adults++;
        }

        if (resident.tipo == ResidentType.responsavel) {
          responsible++;
        }
      }

      return ResidentsReport(
        totalResidents: residents.length,
        children: children,
        adults: adults,
        responsible: responsible,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Relatório de saldo em conta (consolidado de todos os meses até hoje)
  Future<AccountBalanceReport> getAccountBalanceReport() async {
    try {
      final now = DateTime.now();

      // Buscar todos os pagamentos fixos pagos
      final paymentsSnapshot = await _firestore
          .collection('fixed_payments')
          .where('pago', isEqualTo: true)
          .get();

      final payments = paymentsSnapshot.docs
          .map((doc) => FixedPaymentModel.fromFirestore(doc))
          .toList();

      // Buscar todas as entradas (receitas extras)
      final entriesSnapshot = await _firestore.collection('entries').get();

      final entries = entriesSnapshot.docs
          .map((doc) => EntryModel.fromFirestore(doc))
          .toList();

      // Buscar todas as despesas pagas
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('pago', isEqualTo: true)
          .get();

      final expenses = expensesSnapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      // Calcular totais
      final totalFixedPayments = payments.fold<double>(
        0,
        (sum, p) => sum + p.valor,
      );
      final totalEntries = entries.fold<double>(0, (sum, e) => sum + e.valor);
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.valor);

      final totalIncome = totalFixedPayments + totalEntries;
      final currentBalance = totalIncome - totalExpenses;

      // Agrupar por mês para histórico
      final monthlyBalances = <DateTime, MonthlyBalance>{};

      // Processar pagamentos fixos
      for (var payment in payments) {
        if (payment.dataPagamento != null) {
          final month = DateTime(
            payment.dataPagamento!.year,
            payment.dataPagamento!.month,
          );
          monthlyBalances.putIfAbsent(
            month,
            () => MonthlyBalance(month: month),
          );
          monthlyBalances[month]!.fixedPayments += payment.valor;
        }
      }

      // Processar receitas
      for (var entry in entries) {
        final month = DateTime(entry.data.year, entry.data.month);
        monthlyBalances.putIfAbsent(month, () => MonthlyBalance(month: month));
        monthlyBalances[month]!.entries += entry.valor;
      }

      // Processar despesas
      for (var expense in expenses) {
        if (expense.dataPagamento != null) {
          final month = DateTime(
            expense.dataPagamento!.year,
            expense.dataPagamento!.month,
          );
          monthlyBalances.putIfAbsent(
            month,
            () => MonthlyBalance(month: month),
          );
          monthlyBalances[month]!.expenses += expense.valor;
        }
      }

      // Ordenar por mês
      final sortedBalances = monthlyBalances.values.toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      return AccountBalanceReport(
        totalFixedPayments: totalFixedPayments,
        totalEntries: totalEntries,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        currentBalance: currentBalance,
        monthlyBalances: sortedBalances,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// Models para relatórios
class MonthlyReport {
  final int month;
  final int year;
  final double totalExpected;
  final double totalPaid;
  final double totalEntries;
  final double totalExpenses;
  final List<HouseDefaulter> defaulters;
  final int paymentsCount;
  final int pendingCount;

  MonthlyReport({
    required this.month,
    required this.year,
    required this.totalExpected,
    required this.totalPaid,
    required this.totalEntries,
    required this.totalExpenses,
    required this.defaulters,
    required this.paymentsCount,
    required this.pendingCount,
  });

  double get balance => totalPaid + totalEntries - totalExpenses;
  double get defaultAmount => totalExpected - totalPaid;
}

class HouseDefaulter {
  final HouseModel house;
  final double expectedValue;
  final double paidValue;
  final double debtValue;
  final List<String> pendingTypes;

  HouseDefaulter({
    required this.house,
    required this.expectedValue,
    required this.paidValue,
    required this.debtValue,
    required this.pendingTypes,
  });
}

class AnnualReport {
  final int year;
  final List<MonthlyReport> monthlyReports;
  final double totalExpected;
  final double totalPaid;
  final double totalEntries;
  final double totalExpenses;

  AnnualReport({
    required this.year,
    required this.monthlyReports,
    required this.totalExpected,
    required this.totalPaid,
    required this.totalEntries,
    required this.totalExpenses,
  });

  double get balance => totalPaid + totalEntries - totalExpenses;
}

class ResidentsReport {
  final int totalResidents;
  final int children;
  final int adults;
  final int responsible;

  ResidentsReport({
    required this.totalResidents,
    required this.children,
    required this.adults,
    required this.responsible,
  });
}

class AccountBalanceReport {
  final double totalFixedPayments;
  final double totalEntries;
  final double totalIncome;
  final double totalExpenses;
  final double currentBalance;
  final List<MonthlyBalance> monthlyBalances;

  AccountBalanceReport({
    required this.totalFixedPayments,
    required this.totalEntries,
    required this.totalIncome,
    required this.totalExpenses,
    required this.currentBalance,
    required this.monthlyBalances,
  });
}

class MonthlyBalance {
  final DateTime month;
  double fixedPayments;
  double entries;
  double expenses;

  MonthlyBalance({
    required this.month,
    this.fixedPayments = 0,
    this.entries = 0,
    this.expenses = 0,
  });

  double get totalIncome => fixedPayments + entries;
  double get balance => totalIncome - expenses;
}
