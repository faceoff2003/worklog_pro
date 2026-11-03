// Read-only audit for F-FIX-SOLDE.1: what including travelAmountHT changes.
//
// For each client: work entries after the last settlement with
// travelAmountHT > 0 (date, amount, km), then the current balance
// (labor + billable expenses - payments) and the corrected one
// (labor + travel + billable expenses - payments, what the PDF invoices).
//
// Does NOT write, does NOT touch firestore.rules, does NOT deploy anything.
// Only .get() calls against Firestore. Safe to run against production.
//
// Mirrors AccountStatementService:
//   - cutoff on createdAt, strictly after the last settlement, never on date;
//   - last settlement = most recent date, first document on a tie.
//
// Prerequisites: same as list-distinct-enum-values.mjs (`npm install`, then
// Application Default Credentials for the project).
//
// Usage:
//   node list-open-travel-entries.mjs
//   node list-open-travel-entries.mjs --project=worklog-pro-2b3fb
//   node list-open-travel-entries.mjs --self-check   (no Firestore access)
//
// Cost note: full collectionGroup scan of clients, workEntries, expenses,
// payments and client_settlements across every user.

import assert from 'node:assert/strict';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Microseconds since epoch. Dart's toIso8601String() keeps microseconds, which
// Date would drop, and the cutoff is strict: two instants in the same
// millisecond must stay distinct.
function instantOf(value) {
  if (value && typeof value.toDate === 'function') return value.toDate().getTime() * 1000;
  if (typeof value !== 'string') return null;
  const ms = Date.parse(value);
  if (Number.isNaN(ms)) return null;
  const fraction = value.match(/\.(\d+)/);
  const micros = fraction ? Number(fraction[1].padEnd(6, '0').slice(3, 6)) : 0;
  return ms * 1000 + micros;
}

function cents(value) {
  return Number.isInteger(value) ? value : 0;
}

function lastSettlement(settlements) {
  let last = null;
  for (const s of settlements) {
    if (last === null || String(s.date) > String(last.date)) last = s;
  }
  return last;
}

/** Pure: one client's documents in, its audit out. Amounts in cents. */
export function auditClient({ workEntries = [], expenses = [], payments = [], settlements = [] }) {
  const last = lastSettlement(settlements);
  const cutoff = last === null ? null : instantOf(last.createdAt);
  const anomalies = [];
  if (last !== null && cutoff === null) {
    anomalies.push(`createdAt illisible sur le dernier solde : ${JSON.stringify(last.createdAt)}`);
  }

  const isOpen = (doc) => {
    if (cutoff === null) return last === null;
    const at = instantOf(doc.createdAt);
    if (at === null) {
      anomalies.push(`createdAt illisible : ${JSON.stringify(doc.createdAt)} (document exclu)`);
      return false;
    }
    return at > cutoff;
  };

  const work = workEntries.filter(isOpen);
  const labor = work.reduce((sum, e) => sum + cents(e.laborAmountHT), 0);
  const travel = work.reduce((sum, e) => sum + cents(e.travelAmountHT), 0);
  // Absent isBillable = true, the entity's default.
  const billable = expenses
    .filter((e) => e.isBillable !== false)
    .filter(isOpen)
    .reduce((sum, e) => sum + cents(e.amountHT), 0);
  const paid = payments.filter(isOpen).reduce((sum, p) => sum + cents(p.amount), 0);

  const current = labor + billable - paid;
  return {
    settlementDate: last === null ? null : String(last.date),
    travelEntries: work
      .filter((e) => cents(e.travelAmountHT) > 0)
      .sort((a, b) => String(a.date).localeCompare(String(b.date)))
      .map((e) => ({
        date: String(e.date),
        travelCents: cents(e.travelAmountHT),
        km: e.travelDistanceKm ?? 0,
      })),
    currentCents: current,
    correctedCents: current + travel,
    anomalies,
  };
}

function euros(c) {
  const abs = Math.abs(c);
  return `${c < 0 ? '-' : ''}${Math.trunc(abs / 100)},${String(abs % 100).padStart(2, '0')} €`;
}

function selfCheck() {
  const at = (hour) => `2026-03-10T${String(hour).padStart(2, '0')}:00:00.000`;
  const work = (labor, travel, hour, km = 10) => ({
    date: '2026-03-10', laborAmountHT: labor, travelAmountHT: travel, travelDistanceKm: km, createdAt: at(hour),
  });

  const empty = auditClient({});
  assert.deepEqual([empty.currentCents, empty.correctedCents, empty.travelEntries.length], [0, 0, 0]);

  const unsettled = auditClient({
    workEntries: [work(10000, 400, 9), work(5000, 0, 9)],
    expenses: [
      { amountHT: 300, createdAt: at(9) },
      { amountHT: 999, isBillable: false, createdAt: at(9) },
    ],
    payments: [{ amount: 1000, createdAt: at(9) }],
  });
  assert.equal(unsettled.currentCents, 14300);
  assert.equal(unsettled.correctedCents, 14700);
  assert.deepEqual(unsettled.travelEntries, [{ date: '2026-03-10', travelCents: 400, km: 10 }]);

  const settled = auditClient({
    settlements: [
      { date: '2026-03-01', createdAt: at(1) },
      { date: '2026-03-10', createdAt: at(12) },
    ],
    workEntries: [work(100, 10, 11), work(200, 20, 12), work(400, 40, 13)],
    payments: [{ amount: 50, createdAt: at(13) }, { amount: 7, createdAt: at(11) }],
  });
  assert.equal(settled.settlementDate, '2026-03-10');
  assert.equal(settled.currentCents, 350, 'cutoff strict sur createdAt');
  assert.equal(settled.correctedCents, 390);
  assert.equal(settled.travelEntries.length, 1);

  const tie = auditClient({
    settlements: [
      { date: '2026-03-10', createdAt: at(10) },
      { date: '2026-03-10', createdAt: at(14) },
    ],
    workEntries: [work(100, 0, 12)],
  });
  assert.equal(tie.currentCents, 100, 'égalité de date : premier document retenu');

  const micro = auditClient({
    settlements: [{ date: '2026-03-10', createdAt: '2026-03-10T12:00:00.123456' }],
    workEntries: [
      { laborAmountHT: 100, createdAt: '2026-03-10T12:00:00.123457' },
      { laborAmountHT: 200, createdAt: '2026-03-10T12:00:00.123456' },
    ],
  });
  assert.equal(micro.currentCents, 100, 'microsecondes conservées');

  const stamp = { toDate: () => new Date('2026-03-10T13:00:00') };
  const timestamp = auditClient({
    settlements: [{ date: '2026-03-10', createdAt: at(12) }],
    workEntries: [{ laborAmountHT: 100, createdAt: stamp }],
  });
  assert.equal(timestamp.currentCents, 100);

  const unreadable = auditClient({
    settlements: [{ date: '2026-03-10', createdAt: at(12) }],
    workEntries: [{ laborAmountHT: 100, createdAt: 'x' }],
  });
  assert.equal(unreadable.currentCents, 0);
  assert.equal(unreadable.anomalies.length, 1);

  const brokenSettlement = auditClient({
    settlements: [{ date: '2026-03-10', createdAt: null }],
    workEntries: [work(100, 0, 12)],
  });
  assert.equal(brokenSettlement.currentCents, 0);
  assert.equal(brokenSettlement.anomalies.length, 1);

  assert.equal(euros(-1234505), '-12345,05 €');
  console.log('self-check OK');
}

// Only users/{uid}/...: workEntries and expenses also exist under
// clientPortals/{uid}/..., whose mirrored documents would count twice.
async function loadByClient(db, collection) {
  const snap = await db.collectionGroup(collection).get();
  const docs = snap.docs.filter((d) => d.ref.path.startsWith('users/'));
  return { scanned: docs.length, docs };
}

function keyOf(doc, clientId) {
  return `${doc.ref.path.split('/')[1]}/${clientId}`;
}

async function main() {
  const projectIdArg = process.argv.find((a) => a.startsWith('--project='));
  const projectId = projectIdArg
    ? projectIdArg.split('=')[1]
    : process.env.GOOGLE_CLOUD_PROJECT || 'worklog-pro-2b3fb';

  initializeApp({ credential: applicationDefault(), projectId });
  const db = getFirestore();
  console.log(`Projet Firebase interrogé : ${projectId}\n`);

  const clients = new Map();
  const bucket = (key) => {
    if (!clients.has(key)) {
      clients.set(key, { name: null, workEntries: [], expenses: [], payments: [], settlements: [] });
    }
    return clients.get(key);
  };

  const clientDocs = await loadByClient(db, 'clients');
  for (const doc of clientDocs.docs) bucket(keyOf(doc, doc.id)).name = doc.data().name ?? null;

  const scans = [
    ['workEntries', 'workEntries'],
    ['expenses', 'expenses'],
    ['payments', 'payments'],
    ['client_settlements', 'settlements'],
  ];
  const scanned = { clients: clientDocs.scanned };
  for (const [collection, field] of scans) {
    const { scanned: count, docs } = await loadByClient(db, collection);
    scanned[collection] = count;
    for (const doc of docs) bucket(keyOf(doc, doc.data().clientId))[field].push(doc.data());
  }

  console.log(`documents scannés : ${JSON.stringify(scanned)}`);
  if (scanned.clients === 0) {
    console.log("⚠ AUCUN CLIENT SCANNÉ. Ce n'est PAS \"aucun problème\" : vérifie le projet ciblé.");
  }

  let affected = 0;
  let totalDelta = 0;
  let anomalies = 0;
  for (const [key, client] of clients) {
    const audit = auditClient(client);
    const delta = audit.correctedCents - audit.currentCents;
    if (delta !== 0) affected += 1;
    totalDelta += delta;
    anomalies += audit.anomalies.length;

    console.log(`\n${client.name ?? '(client inconnu)'} [${key}]`);
    console.log(`  dernier solde : ${audit.settlementDate ?? 'jamais soldé'}`);
    for (const e of audit.travelEntries) {
      console.log(`  ${e.date}  ${euros(e.travelCents).padStart(12)}  ${e.km} km`);
    }
    if (audit.travelEntries.length === 0) console.log('  aucune prestation ouverte avec déplacement');
    console.log(`  solde actuel  : ${euros(audit.currentCents)}`);
    console.log(`  solde corrigé : ${euros(audit.correctedCents)}${delta !== 0 ? `  (+${euros(delta)})` : ''}`);
    for (const a of audit.anomalies) console.log(`  ⚠ ${a}`);
  }

  console.log(`\nClients dont le solde change : ${affected} / ${clients.size}`);
  console.log(`Écart total : ${euros(totalDelta)}`);
  if (anomalies) console.log(`⚠ Anomalies de données : ${anomalies}, voir ci-dessus.`);
  console.log('\nAucune modification effectuée.');
}

if (process.argv.includes('--self-check')) {
  selfCheck();
} else {
  await main();
}
process.exit(0);
