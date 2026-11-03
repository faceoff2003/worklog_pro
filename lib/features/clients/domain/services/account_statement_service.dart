import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Nature d'une ligne de relevé. Calculé, jamais stocké.
enum StatementLineType { workEntry, expense, payment, settlement }

/// État de paiement d'une prestation. Calculé, jamais stocké.
enum WorkEntryPaymentState { settled, paid, partial, unpaid }

/// Statut d'une prestation dans le relevé.
class WorkEntryPaymentStatus {
  final WorkEntryPaymentState state;

  /// Reste à payer sur cette prestation (zéro sauf partielle/impayée).
  final Money remaining;

  const WorkEntryPaymentStatus(this.state, this.remaining);

  String get label {
    switch (state) {
      case WorkEntryPaymentState.settled:
        return 'Soldée';
      case WorkEntryPaymentState.paid:
        return 'Payée';
      case WorkEntryPaymentState.partial:
        return 'Partielle (reste ${remaining.toEurosString()})';
      case WorkEntryPaymentState.unpaid:
        return 'Impayée';
    }
  }
}

/// Une ligne du relevé.
class StatementLine {
  final StatementLineType type;

  /// Identifiant du document source.
  final String id;
  final DateOnly date;

  /// Effet sur le solde : positif pour une prestation ou une dépense, négatif
  /// pour un paiement. Pour un solde : montant archivé `balanceAtSettlement`,
  /// purement informatif.
  final Money amount;

  /// Solde courant après cette ligne. Repart de zéro après chaque solde.
  final Money runningBalance;

  /// Vrai si la ligne est antérieure au dernier solde, ou est un solde.
  final bool isArchived;
  final String? description;

  /// Renseigné uniquement pour une prestation.
  final WorkEntryPaymentStatus? status;

  /// Jour de saisie, renseigné uniquement si [date] est antérieure à celle du
  /// solde qui précède la ligne (saisie en retard).
  final DateOnly? enteredOn;

  const StatementLine({
    required this.type,
    required this.id,
    required this.date,
    required this.amount,
    required this.runningBalance,
    required this.isArchived,
    this.description,
    this.status,
    this.enteredOn,
  });
}

/// Relevé de compte d'un client.
class AccountStatement {
  final List<StatementLine> lines;

  /// Totaux de l'époque courante, c'est-à-dire depuis le dernier solde.
  final Money totalWork;
  final Money totalExpenses;
  final Money totalPayments;
  final ClientSettlement? lastSettlement;

  const AccountStatement({
    required this.lines,
    required this.totalWork,
    required this.totalExpenses,
    required this.totalPayments,
    this.lastSettlement,
  });

  /// Solde courant. Négatif = avance du client.
  Money get balance => totalWork + totalExpenses - totalPayments;

  /// Statut de chaque prestation, par identifiant.
  Map<String, WorkEntryPaymentStatus> get workEntryStatuses => {
        for (final line in lines)
          if (line.status != null) line.id: line.status!,
      };
}

/// Calcule le relevé de compte d'un client. Dart pur, sans écriture : le relevé
/// est dérivé des données, jamais stocké. Règles détaillées dans
/// `doc/F-RELEVE_PLAN.md`.
///
/// **Coupure** : un solde sépare les lignes selon leur `createdAt`, jamais selon
/// leur `date`. Une ligne appartient à l'époque courante si et seulement si
/// `createdAt` est strictement postérieur à celui du dernier solde. Une
/// prestation datée le jour d'un solde compte donc si elle a été saisie après.
///
/// **Dernier solde** : `date` la plus récente, puis `createdAt` le plus récent,
/// puis `id` le plus grand ([latestFirst], partagé avec
/// `SettlementRepository.watchLastSettlement`).
///
/// **Montant d'une prestation** : `laborAmountHT + travelAmountHT`. Le solde est
/// ce que facture le PDF, soit `ReportData.theoreticalBalance`.
///
/// **Ordre** : par époque, puis `date`, puis prestation < dépense < paiement,
/// puis `createdAt`, puis `id`. Indépendant de l'ordre d'entrée. Une ligne saisie
/// en retard reste dans l'époque de sa saisie, même avec une date antérieure au
/// solde qui la précède.
///
/// **Statuts** : les paiements de l'époque courante couvrent ses prestations de
/// la plus ancienne à la plus récente (FIFO), quelle que soit leur date. Ils ne
/// sont pas imputés aux dépenses. Toute prestation d'une époque close est soldée.
class AccountStatementService {
  const AccountStatementService();

  AccountStatement build({
    required List<WorkEntry> workEntries,
    required List<Expense> expenses,
    required List<Payment> payments,
    required List<ClientSettlement> settlements,
  }) {
    final last = _lastSettlement(settlements);
    final others = settlements.where((s) => !identical(s, last)).toList()
      ..sort((a, b) {
        final byCreatedAt = a.createdAt.compareTo(b.createdAt);
        return byCreatedAt != 0 ? byCreatedAt : a.id.compareTo(b.id);
      });
    final closing = last == null
        ? const <ClientSettlement>[]
        : [...others.where((s) => !s.createdAt.isAfter(last.createdAt)), last];

    final drafts = _drafts(workEntries, expenses, payments);
    final buckets = List.generate(closing.length + 1, (_) => <_Draft>[]);
    for (final draft in drafts) {
      final index = closing.indexWhere((s) => !draft.createdAt.isAfter(s.createdAt));
      buckets[index == -1 ? closing.length : index].add(draft);
    }
    for (final bucket in buckets) {
      bucket.sort(_compare);
    }

    final lines = <StatementLine>[];
    for (var i = 0; i < closing.length; i++) {
      // Un solde saisi après le "dernier" mais daté avant lui n'a aucun effet
      // sur le calcul. Il reste affiché, juste avant le solde retenu.
      if (identical(closing[i], last)) {
        lines.addAll(others.where((s) => s.createdAt.isAfter(last!.createdAt)).map(_settlementLine));
      }
      lines.addAll(_epochLines(buckets[i], isArchived: true, previous: i == 0 ? null : closing[i - 1]));
      lines.add(_settlementLine(closing[i]));
    }

    final current = buckets.last;
    lines.addAll(_epochLines(current, isArchived: false, previous: closing.lastOrNull));

    return AccountStatement(
      lines: lines,
      totalWork: _sum(current, StatementLineType.workEntry),
      totalExpenses: _sum(current, StatementLineType.expense),
      totalPayments: -_sum(current, StatementLineType.payment),
      lastSettlement: last,
    );
  }

  /// Tri du plus récent au plus ancien : `date`, puis `createdAt`, puis `id`.
  /// Le premier élément est le dernier solde (D2 : à date égale, le dernier saisi).
  static int latestFirst(ClientSettlement a, ClientSettlement b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    final byCreatedAt = b.createdAt.compareTo(a.createdAt);
    return byCreatedAt != 0 ? byCreatedAt : b.id.compareTo(a.id);
  }

  ClientSettlement? _lastSettlement(List<ClientSettlement> settlements) {
    if (settlements.isEmpty) return null;
    return ([...settlements]..sort(latestFirst)).first;
  }

  List<_Draft> _drafts(List<WorkEntry> workEntries, List<Expense> expenses, List<Payment> payments) => [
        for (final e in workEntries)
          _Draft(StatementLineType.workEntry, e.id, e.date, e.createdAt, e.laborAmountHT + e.travelAmountHT,
              e.tasks.isNotEmpty ? e.tasks.join(', ') : e.notes),
        for (final e in expenses)
          if (e.isBillable) _Draft(StatementLineType.expense, e.id, e.date, e.createdAt, e.amountHT, e.description),
        for (final p in payments) _Draft(StatementLineType.payment, p.id, p.date, p.createdAt, -p.amount, p.note),
      ];

  static int _compare(_Draft a, _Draft b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byType = a.type.index.compareTo(b.type.index);
    if (byType != 0) return byType;
    final byCreatedAt = a.createdAt.compareTo(b.createdAt);
    return byCreatedAt != 0 ? byCreatedAt : a.id.compareTo(b.id);
  }

  List<StatementLine> _epochLines(List<_Draft> drafts, {required bool isArchived, ClientSettlement? previous}) {
    var unallocated = -_sum(drafts, StatementLineType.payment);
    var running = Money.zero;
    final lines = <StatementLine>[];
    for (final draft in drafts) {
      running += draft.amount;
      WorkEntryPaymentStatus? status;
      if (draft.type == StatementLineType.workEntry) {
        if (isArchived) {
          status = const WorkEntryPaymentStatus(WorkEntryPaymentState.settled, Money.zero);
        } else {
          final covered = unallocated < draft.amount ? unallocated : draft.amount;
          unallocated -= covered;
          final remaining = draft.amount - covered;
          final state = remaining == Money.zero
              ? WorkEntryPaymentState.paid
              : covered == Money.zero
                  ? WorkEntryPaymentState.unpaid
                  : WorkEntryPaymentState.partial;
          status = WorkEntryPaymentStatus(state, remaining);
        }
      }
      lines.add(StatementLine(
        type: draft.type,
        id: draft.id,
        date: draft.date,
        amount: draft.amount,
        runningBalance: running,
        isArchived: isArchived,
        description: draft.description,
        status: status,
        enteredOn: previous != null && draft.date < previous.date ? DateOnly.fromDateTime(draft.createdAt) : null,
      ));
    }
    return lines;
  }

  StatementLine _settlementLine(ClientSettlement s) => StatementLine(
        type: StatementLineType.settlement,
        id: s.id,
        date: s.date,
        amount: s.balanceAtSettlement,
        runningBalance: Money.zero,
        isArchived: true,
        description: s.note,
      );

  Money _sum(List<_Draft> drafts, StatementLineType type) => drafts
      .where((d) => d.type == type)
      .fold(Money.zero, (total, d) => total + d.amount);
}

class _Draft {
  final StatementLineType type;
  final String id;
  final DateOnly date;
  final DateTime createdAt;
  final Money amount;
  final String? description;

  const _Draft(this.type, this.id, this.date, this.createdAt, this.amount, this.description);
}
