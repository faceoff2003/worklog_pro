import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Instant de saisie : le jour [day] de mars 2026, à [hour] heures.
DateTime _at(int day, [int hour = 12]) => DateTime(2026, 3, day, hour);
DateOnly _d(int day) => DateOnly.fromDateTime(DateTime(2026, 3, day));

WorkEntry _work(String id, int cents, int day, {DateTime? at, int travelCents = 0, List<String> tasks = const [], String? notes}) =>
    WorkEntry(
      id: id,
      date: _d(day),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: 'c1',
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(cents),
      laborAmountHT: Money.fromCents(cents),
      travelAmountHT: Money.fromCents(travelCents),
      tasks: tasks,
      notes: notes,
      createdAt: at ?? _at(day),
      updatedAt: at ?? _at(day),
    );

Expense _expense(String id, int cents, int day, {DateTime? at, bool billable = true}) => Expense(
      id: id,
      date: _d(day),
      clientId: 'c1',
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(cents),
      description: 'desc $id',
      isBillable: billable,
      createdAt: at ?? _at(day),
      updatedAt: at ?? _at(day),
    );

Payment _payment(String id, int cents, int day, {DateTime? at, String? note}) => Payment(
      id: id,
      date: _d(day),
      clientId: 'c1',
      amount: Money.fromCents(cents),
      method: PaymentMethod.cash,
      note: note,
      createdAt: at ?? _at(day),
      updatedAt: at ?? _at(day),
    );

ClientSettlement _settlement(String id, int day, {DateTime? at, int cents = 0, int carry = 0, String? note}) =>
    ClientSettlement(
      id: id,
      clientId: 'c1',
      date: _d(day),
      balanceAtSettlement: Money.fromCents(cents),
      carriedOverAmount: Money.fromCents(carry),
      note: note,
      createdAt: at ?? _at(day),
    );

AccountStatement _build({
  List<WorkEntry> work = const [],
  List<Expense> expenses = const [],
  List<Payment> payments = const [],
  List<ClientSettlement> settlements = const [],
}) =>
    const AccountStatementService().build(
      workEntries: work,
      expenses: expenses,
      payments: payments,
      settlements: settlements,
    );

List<String> _ids(AccountStatement s) => s.lines.map((l) => l.id).toList();
List<int> _running(AccountStatement s) => s.lines.map((l) => l.runningBalance.amountCents).toList();

void main() {
  test('client vide : aucune ligne, solde nul', () {
    final s = _build();
    expect(s.lines, isEmpty);
    expect(s.balance, Money.zero);
    expect(s.lastSettlement, isNull);
    expect(s.workEntryStatuses, isEmpty);
  });

  group('lignes et solde courant', () {
    test('lignes chronologiques, solde courant après chaque ligne, montants signés', () {
      final s = _build(
        work: [_work('w2', 5000, 3), _work('w1', 10000, 1)],
        expenses: [_expense('e1', 2500, 2)],
        payments: [_payment('p1', 4000, 4)],
      );
      expect(_ids(s), ['w1', 'e1', 'w2', 'p1']);
      expect(_running(s), [10000, 12500, 17500, 13500]);
      expect(s.lines.last.amount.amountCents, -4000);
      expect(s.lines.last.type, StatementLineType.payment);
      expect(s.balance.amountCents, 13500);
      expect(s.totalWork.amountCents, 15000);
      expect(s.totalExpenses.amountCents, 2500);
      expect(s.totalPayments.amountCents, 4000);
      expect(s.lines.every((l) => !l.isArchived), isTrue);
    });

    test('dépense non facturable absente', () {
      final s = _build(expenses: [_expense('e1', 999, 1, billable: false)]);
      expect(s.lines, isEmpty);
      expect(s.totalExpenses, Money.zero);
    });

    // F-FIX-SOLDE.2 : changement volontaire, remplace "déplacement exclu, comme
    // clientBalanceProvider" (attendait 10000).
    test('déplacement inclus dans la ligne, le solde courant et le total', () {
      final s = _build(work: [_work('w1', 10000, 1, travelCents: 1234)]);
      expect(s.lines.single.amount.amountCents, 11234);
      expect(s.lines.single.runningBalance.amountCents, 11234);
      expect(s.totalWork.amountCents, 11234);
      expect(s.balance.amountCents, 11234);
    });

    test('déplacement couvert par le FIFO : main-d\'œuvre seule payée = partielle', () {
      final st = _build(
        work: [_work('w1', 10000, 1, travelCents: 1234)],
        payments: [_payment('p1', 10000, 2)],
      );
      final s = st.workEntryStatuses['w1']!;
      expect(s.state, WorkEntryPaymentState.partial);
      expect(s.remaining.amountCents, 1234);
      expect(st.balance.amountCents, 1234);
    });

    test('paiement du montant facturé : payée, solde nul, plus de fausse avance', () {
      final st = _build(
        work: [_work('w1', 10000, 1, travelCents: 1234)],
        payments: [_payment('p1', 11234, 2)],
      );
      expect(st.workEntryStatuses['w1']!.state, WorkEntryPaymentState.paid);
      expect(st.balance, Money.zero);
    });

    test('description : tâches, sinon notes ; dépense ; note de paiement et de solde', () {
      final s = _build(
        work: [_work('w1', 1, 1, tasks: ['a', 'b'], notes: 'n'), _work('w2', 1, 2, notes: 'n')],
        expenses: [_expense('e1', 1, 3)],
        payments: [_payment('p1', 1, 4, note: 'chèque')],
        settlements: [_settlement('s1', 5, note: 'fin')],
      );
      expect(s.lines.map((l) => l.description), ['a, b', 'n', 'desc e1', 'chèque', 'fin']);
    });

    test('ordre à date égale : prestation, dépense, paiement, puis createdAt, puis id', () {
      final s = _build(
        work: [
          _work('w3', 1, 5, at: _at(5, 9)),
          _work('w2', 1, 5, at: _at(5, 8)),
          _work('w1', 1, 5, at: _at(5, 9)),
        ],
        expenses: [_expense('e1', 1, 5, at: _at(5, 1))],
        payments: [_payment('p1', 1, 5, at: _at(5, 0))],
      );
      expect(_ids(s), ['w2', 'w1', 'w3', 'e1', 'p1']);
    });

    test("l'ordre ne dépend pas de l'ordre d'entrée", () {
      final work = [_work('w1', 1, 5), _work('w2', 1, 5), _work('w3', 1, 2)];
      expect(_ids(_build(work: work)), _ids(_build(work: work.reversed.toList())));
    });
  });

  group('statuts FIFO', () {
    Map<String, WorkEntryPaymentStatus> statuses(List<WorkEntry> work, List<Payment> payments) =>
        _build(work: work, payments: payments).workEntryStatuses;

    test('sans paiement : impayée, reste le montant', () {
      final s = statuses([_work('w1', 1000, 1)], []);
      expect(s['w1']!.state, WorkEntryPaymentState.unpaid);
      expect(s['w1']!.remaining.amountCents, 1000);
      expect(s['w1']!.label, 'Impayée');
    });

    test('paiement partiel : la plus ancienne partielle, la suivante impayée', () {
      final s = statuses([_work('w2', 1000, 2), _work('w1', 1000, 1)], [_payment('p1', 400, 3)]);
      expect(s['w1']!.state, WorkEntryPaymentState.partial);
      expect(s['w1']!.remaining.amountCents, 600);
      expect(s['w1']!.label, 'Partielle (reste 6,00 €)');
      expect(s['w2']!.state, WorkEntryPaymentState.unpaid);
    });

    test('paiement exact : payée, reste nul, solde nul', () {
      final st = _build(work: [_work('w1', 1000, 1)], payments: [_payment('p1', 1000, 2)]);
      final s = st.workEntryStatuses['w1']!;
      expect(s.state, WorkEntryPaymentState.paid);
      expect(s.remaining, Money.zero);
      expect(s.label, 'Payée');
      expect(st.balance, Money.zero);
    });

    test('plusieurs paiements cumulés couvrent plusieurs prestations', () {
      final s = statuses(
        [_work('w1', 1000, 1), _work('w2', 1000, 2), _work('w3', 1000, 3)],
        [_payment('p1', 700, 4), _payment('p2', 800, 5)],
      );
      expect(s['w1']!.state, WorkEntryPaymentState.paid);
      expect(s['w2']!.state, WorkEntryPaymentState.partial);
      expect(s['w2']!.remaining.amountCents, 500);
      expect(s['w3']!.state, WorkEntryPaymentState.unpaid);
    });

    test('sur-paiement : tout payé, solde négatif = avance', () {
      final st = _build(work: [_work('w1', 1000, 1)], payments: [_payment('p1', 1500, 2)]);
      expect(st.workEntryStatuses['w1']!.state, WorkEntryPaymentState.paid);
      expect(st.balance.amountCents, -500);
      expect(st.lines.last.runningBalance.amountCents, -500);
    });

    test('un acompte antérieur couvre une prestation ultérieure', () {
      final s = statuses([_work('w1', 1000, 5)], [_payment('p1', 1000, 1)]);
      expect(s['w1']!.state, WorkEntryPaymentState.paid);
    });

    test('prestation à montant nul : payée', () {
      expect(statuses([_work('w1', 0, 1)], [])['w1']!.state, WorkEntryPaymentState.paid);
    });

    test('les dépenses ne consomment pas de paiement', () {
      final st = _build(
        expenses: [_expense('e1', 500, 1)],
        work: [_work('w1', 1000, 2)],
        payments: [_payment('p1', 1000, 3)],
      );
      expect(st.workEntryStatuses['w1']!.state, WorkEntryPaymentState.paid);
      expect(st.balance.amountCents, 500);
      expect(st.lines.firstWhere((l) => l.id == 'e1').status, isNull);
    });
  });

  group('solde de compte', () {
    test('sépare par createdAt, le solde courant repart de zéro, lignes archivées', () {
      final s = _build(
        work: [_work('old', 10000, 1), _work('new', 700, 6)],
        payments: [_payment('pOld', 3000, 2), _payment('pNew', 200, 7)],
        settlements: [_settlement('s1', 5, cents: 7000)],
      );
      expect(_ids(s), ['old', 'pOld', 's1', 'new', 'pNew']);
      expect(_running(s), [10000, 7000, 0, 700, 500]);
      expect(s.lines.map((l) => l.isArchived), [true, true, true, false, false]);
      expect(s.lines[2].type, StatementLineType.settlement);
      expect(s.lines[2].amount.amountCents, 7000);
      expect(s.balance.amountCents, 500);
      expect(s.lastSettlement?.id, 's1');
    });

    test('statuts : soldée avant le solde, même avec un reste dû ; FIFO après seulement', () {
      final s = _build(
        work: [_work('old', 10000, 1), _work('new', 700, 6)],
        payments: [_payment('pOld', 9000, 2), _payment('pNew', 200, 7)],
        settlements: [_settlement('s1', 5, cents: 1000)],
      ).workEntryStatuses;
      expect(s['old']!.state, WorkEntryPaymentState.settled);
      expect(s['old']!.remaining, Money.zero);
      expect(s['old']!.label, 'Soldée');
      expect(s['new']!.state, WorkEntryPaymentState.partial);
      expect(s['new']!.remaining.amountCents, 500);
    });

    test('jour même du solde : saisie après comptée, saisie avant archivée, égalité archivée', () {
      final s = _build(
        work: [
          _work('before', 1, 5, at: _at(5, 11)),
          _work('equal', 2, 5, at: _at(5, 12)),
          _work('after', 4, 5, at: _at(5, 13)),
        ],
        settlements: [_settlement('s1', 5, at: _at(5, 12))],
      );
      expect(_ids(s), ['before', 'equal', 's1', 'after']);
      expect(s.balance.amountCents, 4);
    });

    test('paiement daté avant le solde mais saisi après : époque courante, après le séparateur', () {
      final s = _build(
        payments: [_payment('late', 300, 1, at: _at(9))],
        settlements: [_settlement('s1', 5)],
      );
      expect(_ids(s), ['s1', 'late']);
      expect(s.lines.last.isArchived, isFalse);
      expect(s.balance.amountCents, -300);
    });

    test('prestation datée après le solde mais saisie avant : archivée', () {
      final s = _build(work: [_work('w1', 700, 20, at: _at(1))], settlements: [_settlement('s1', 5)]);
      expect(_ids(s), ['w1', 's1']);
      expect(s.balance, Money.zero);
    });

    test('soldes successifs : une époque par solde, seul le dernier coupe le solde courant', () {
      final s = _build(
        work: [_work('a', 100, 1), _work('b', 200, 6), _work('c', 400, 11)],
        settlements: [_settlement('s2', 10), _settlement('s1', 5)],
      );
      expect(_ids(s), ['a', 's1', 'b', 's2', 'c']);
      expect(_running(s), [100, 0, 200, 0, 400]);
      expect(s.lastSettlement?.id, 's2');
      expect(s.balance.amountCents, 400);
      expect(s.workEntryStatuses['b']!.state, WorkEntryPaymentState.settled);
      expect(s.workEntryStatuses['c']!.state, WorkEntryPaymentState.unpaid);
    });

    test('D2 corrigé : deux soldes le même jour, le plus récent en createdAt est retenu', () {
      final s = _build(
        work: [_work('between', 100, 5, at: _at(5, 12)), _work('after', 200, 5, at: _at(5, 15))],
        settlements: [
          _settlement('first', 5, at: _at(5, 10)),
          _settlement('second', 5, at: _at(5, 14)),
        ],
      );
      expect(s.lastSettlement?.id, 'second');
      expect(s.balance.amountCents, 200);
      expect(_ids(s), ['first', 'between', 'second', 'after']);
    });

    test('D2 corrigé : même date et même createdAt, départage par id', () {
      final s = _build(settlements: [_settlement('b', 5), _settlement('a', 5)]);
      expect(s.lastSettlement?.id, 'b');
      expect(_build(settlements: [_settlement('a', 5), _settlement('b', 5)]).lastSettlement?.id, 'b');
    });

    test('date plus récente gagne sur createdAt : un solde saisi après mais daté avant est sans effet', () {
      final s = _build(
        work: [_work('w', 100, 5, at: _at(5, 15))],
        settlements: [_settlement('main', 5, at: _at(5, 10)), _settlement('backdated', 4, at: _at(6))],
      );
      expect(s.lastSettlement?.id, 'main');
      expect(s.balance.amountCents, 100);
      expect(_ids(s), ['backdated', 'main', 'w']);
    });

    test('D2 : le solde retenu étant le plus récent, le précédent ferme sa propre époque', () {
      final s = _build(
        work: [_work('a', 100, 5, at: _at(5, 9)), _work('b', 200, 5, at: _at(5, 12)), _work('c', 400, 5, at: _at(5, 15))],
        settlements: [
          _settlement('recent', 5, at: _at(5, 14)),
          _settlement('older', 5, at: _at(5, 10)),
        ],
      );
      expect(s.lastSettlement?.id, 'recent');
      expect(_ids(s), ['a', 'older', 'b', 'recent', 'c']);
      expect(s.balance.amountCents, 400);
    });

    group('enteredOn (saisie en retard)', () {
      test('date antérieure au solde qui précède : jour de saisie, tous types de ligne', () {
        final s = _build(
          work: [_work('w', 100, 1, at: _at(9))],
          expenses: [_expense('e', 100, 2, at: _at(10))],
          payments: [_payment('p', 100, 3, at: _at(11))],
          settlements: [_settlement('s1', 5)],
        );
        expect(s.lines.first.type, StatementLineType.settlement);
        expect(s.lines.skip(1).map((l) => l.enteredOn), [_d(9), _d(10), _d(11)]);
      });

      test('même jour ou après le solde : pas de mention', () {
        final s = _build(
          work: [_work('same', 100, 5, at: _at(5, 15)), _work('after', 100, 6)],
          settlements: [_settlement('s1', 5)],
        );
        expect(s.lines.skip(1).map((l) => l.enteredOn), [null, null]);
      });

      test('sans solde, ou dans la première époque : pas de mention', () {
        final s = _build(
          work: [_work('w', 100, 1, at: _at(4))],
          settlements: [_settlement('s1', 5)],
        );
        expect(s.lines.first.enteredOn, isNull);
        expect(_build(work: [_work('w', 100, 1, at: _at(20))]).lines.single.enteredOn, isNull);
      });

      test('époque close : comparée au solde précédent, pas à celui qui la ferme', () {
        final s = _build(
          work: [_work('late', 100, 1, at: _at(7)), _work('ok', 100, 6, at: _at(7))],
          settlements: [_settlement('s1', 5), _settlement('s2', 10)],
        );
        final byId = {for (final l in s.lines) l.id: l};
        expect(byId['late']!.isArchived, isTrue);
        expect(byId['late']!.enteredOn, _d(7));
        expect(byId['ok']!.enteredOn, isNull);
      });

      test('deux soldes le même jour : pas de mention, aucune ligne', () {
        final s = _build(settlements: [
          _settlement('first', 5, at: _at(5, 10)),
          _settlement('second', 5, at: _at(5, 14)),
        ]);
        expect(s.lines.every((l) => l.enteredOn == null), isTrue);
      });
    });

    test('createdAt égaux entre soldes : départage par id', () {
      final s = _build(settlements: [
        _settlement('z', 5),
        _settlement('b', 4, at: _at(1)),
        _settlement('a', 3, at: _at(1)),
      ]);
      expect(_ids(s), ['a', 'b', 'z']);
    });
  });

  group('report à nouveau (carriedOverAmount)', () {
    StatementLine carryLine(AccountStatement s) => s.lines.singleWhere((l) => l.type == StatementLineType.carryOver);
    List<StatementLineType> types(AccountStatement s) => s.lines.map((l) => l.type).toList();

    test('X = 0 : aucune ligne, relevé inchangé', () {
      final s = _build(work: [_work('w', 100, 6)], settlements: [_settlement('s1', 5)]);
      expect(s.lines.first.carriedOver, isNull);
      expect(types(s), [StatementLineType.settlement, StatementLineType.workEntry]);
      expect(s.carriedOver, Money.zero);
      expect(s.balance.amountCents, 100);
    });

    test("positif : première ligne de l'époque, avant une prestation datée avant le solde", () {
      final s = _build(
        work: [_work('late', 100, 2, at: _at(6)), _work('w', 200, 7)],
        settlements: [_settlement('s1', 5, cents: 1500, carry: 1500)],
      );
      expect(_ids(s), ['s1', 's1', 'late', 'w']);
      expect(types(s), [
        StatementLineType.settlement,
        StatementLineType.carryOver,
        StatementLineType.workEntry,
        StatementLineType.workEntry,
      ]);
      final carry = carryLine(s);
      expect(carry.amount.amountCents, 1500);
      expect(carry.runningBalance.amountCents, 1500);
      expect(carry.date, _d(5));
      expect(carry.isArchived, isFalse);
      expect(carry.enteredOn, isNull);
      expect(carry.status, isNull);
      expect(s.lines.first.carriedOver?.amountCents, 1500, reason: 'mention au séparateur');
      expect(s.lines.map((l) => l.runningBalance.amountCents).skip(2), [1600, 1800]);
    });

    test('total : report + prestations + dépenses − paiements, totaux existants inchangés', () {
      final s = _build(
        work: [_work('w', 1000, 6)],
        expenses: [_expense('e', 300, 6)],
        payments: [_payment('p', 400, 7)],
        settlements: [_settlement('s1', 5, carry: 1500)],
      );
      expect(s.carriedOver.amountCents, 1500);
      expect(s.totalWork.amountCents, 1000);
      expect(s.totalExpenses.amountCents, 300);
      expect(s.totalPayments.amountCents, 400);
      expect(s.balance.amountCents, 2400);
      expect(s.lines.last.runningBalance, s.balance);
    });

    test('FIFO positif : un paiement inférieur au report ne couvre aucune prestation', () {
      final s = _build(
        work: [_work('w', 1000, 6)],
        payments: [_payment('p', 1200, 7)],
        settlements: [_settlement('s1', 5, carry: 1500)],
      );
      expect(s.workEntryStatuses['w']!.state, WorkEntryPaymentState.unpaid);
      expect(s.workEntryStatuses['w']!.remaining.amountCents, 1000);
      expect(s.balance.amountCents, 1300);
    });

    test("FIFO positif : au-delà du report, le reste couvre les prestations dans l'ordre", () {
      final s = _build(
        work: [_work('a', 1000, 6), _work('b', 1000, 8)],
        payments: [_payment('p', 2000, 9)],
        settlements: [_settlement('s1', 5, carry: 1500)],
      );
      expect(s.workEntryStatuses['a']!.state, WorkEntryPaymentState.partial);
      expect(s.workEntryStatuses['a']!.remaining.amountCents, 500);
      expect(s.workEntryStatuses['b']!.state, WorkEntryPaymentState.unpaid);
      expect(s.balance.amountCents, 1500);
    });

    test("FIFO négatif (avance) : s'ajoute aux paiements", () {
      final s = _build(
        work: [_work('a', 1000, 6), _work('b', 1000, 8)],
        payments: [_payment('p', 400, 9)],
        settlements: [_settlement('s1', 5, carry: -1200)],
      );
      expect(carryLine(s).runningBalance.amountCents, -1200);
      expect(s.workEntryStatuses['a']!.state, WorkEntryPaymentState.paid);
      expect(s.workEntryStatuses['b']!.state, WorkEntryPaymentState.partial);
      expect(s.workEntryStatuses['b']!.remaining.amountCents, 400);
      expect(s.balance.amountCents, 400);
    });

    test('avance seule, sans prestation : solde négatif', () {
      final s = _build(settlements: [_settlement('s1', 5, carry: -1200)]);
      expect(s.balance.amountCents, -1200);
      expect(types(s), [StatementLineType.settlement, StatementLineType.carryOver]);
    });

    test("époque close : ligne archivée, l'époque repart du report, prestations soldées", () {
      final s = _build(
        work: [_work('w', 300, 6), _work('now', 50, 11)],
        settlements: [_settlement('s1', 5, carry: 1000), _settlement('s2', 10, cents: 1300)],
      );
      expect(types(s), [
        StatementLineType.settlement,
        StatementLineType.carryOver,
        StatementLineType.workEntry,
        StatementLineType.settlement,
        StatementLineType.workEntry,
      ]);
      expect(s.lines[1].isArchived, isTrue);
      expect(s.lines[2].runningBalance.amountCents, 1300, reason: 'égal au balanceAtSettlement de s2');
      expect(s.workEntryStatuses['w']!.state, WorkEntryPaymentState.settled);
      expect(s.carriedOver, Money.zero, reason: 'report de s2, pas de s1');
      expect(s.balance.amountCents, 50);
    });

    test('solde non retenu (saisi après, daté avant) : son report est ignoré', () {
      final s = _build(
        work: [_work('w', 100, 6, at: _at(6, 15))],
        settlements: [_settlement('main', 5, carry: 500), _settlement('backdated', 4, at: _at(6), carry: 9999)],
      );
      expect(s.lastSettlement?.id, 'main');
      expect(carryLine(s).id, 'main');
      expect(s.lines.firstWhere((l) => l.id == 'backdated').carriedOver, isNull);
      expect(s.carriedOver.amountCents, 500);
      expect(s.balance.amountCents, 600);
    });
  });
}
