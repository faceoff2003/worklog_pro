// Read-only reconnaissance script for R-SEC.2 (M3, M4, M5).
//
// Single run, single report, three sections:
//   1. project.type / expense.materialCategory / expense.travelMode:
//      distinct values in production (M4 — deciding what to whitelist).
//   2. settings: per-document key count, key list with runtime type,
//      unknown keys, and type mismatches against
//      lib/features/settings/domain/entities/settings.dart (M5 — checking
//      whether any real document would be rejected by the fix, which is
//      committed to firestore.rules but NOT YET DEPLOYED, on its next write).
//   3. clients.defaultRates: documents where the field is absent (fine,
//      the M3 fix tolerates that), not a map, or contains a negative or
//      non-int value (would be rejected by the M3 fix, also committed but
//      not yet deployed, on its next write).
//
// Does NOT write, does NOT touch firestore.rules, does NOT deploy anything.
// Only .get() calls against Firestore. Safe to run against production.
//
// Prerequisites:
//   - `npm install` in this directory (scripts/) once.
//   - Application Default Credentials for the worklog-pro-2b3fb project,
//     e.g. `gcloud auth application-default login`, or
//     GOOGLE_APPLICATION_CREDENTIALS pointing at a service account key
//     with Firestore read access.
//
// Usage:
//   node list-distinct-enum-values.mjs
//   node list-distinct-enum-values.mjs --project=worklog-pro-2b3fb
//
// Cost note: this does a full collectionGroup scan of `projects`,
// `expenses`, `settings` and `clients` across every user (no filters).
// For this app's expected data volume that's cheap, but re-check before
// running it on a much larger dataset.

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const projectIdArg = process.argv.find((a) => a.startsWith('--project='));
const projectId = projectIdArg
  ? projectIdArg.split('=')[1]
  : process.env.GOOGLE_CLOUD_PROJECT || 'worklog-pro-2b3fb';

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

// Known Dart enums (lib/core/constants/enums.dart) — used only to flag
// values that would need adding to a whitelist, or dead values with no
// data behind them. Does not filter the report.
const KNOWN = {
  'projects.type': [
    'nouvelle_installation', 'mise_en_conformite', 'depannage',
    'renovation', 'domotique', 'autre',
  ],
  'expenses.materialCategory': [
    'cables', 'disjoncteurs', 'goulottes', 'outillage', 'luminaires',
    'prises_interrupteurs', 'tableau', 'autre',
  ],
  'expenses.travelMode': ['per_km', 'forfait', 'non_facture'],
};

// Expected runtime type per known Settings field
// (lib/features/settings/domain/entities/settings.dart), mirroring exactly
// what firestore.rules now enforces on write (the M5 fix).
const KNOWN_SETTINGS_FIELDS = {
  dayHours: 'int',
  halfDayHours: 'int',
  defaultPauseMinutes: 'int',
  roundingMinutes: 'int',
  minBillingHours: 'number',
  minBillingAmountCents: 'int',
  currency: 'string',
  country: 'string',
  travelRatePerKmCents: 'int',
  quickTasks: 'array',
  quickVendors: 'array',
  pdfHeader: 'map',
  autoBackupEnabled: 'boolean',
  lastBackupAt: 'string',
  schemaVersion: 'int',
};
const SETTINGS_KEY_CAP = 20; // matches firestore.rules keys().size() <= 20

function runtimeTypeLabel(value) {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  if (typeof value === 'number') return Number.isInteger(value) ? 'int' : 'float';
  if (typeof value === 'object') {
    if (typeof value.toDate === 'function') return 'timestamp';
    return 'map';
  }
  return typeof value; // 'string' | 'boolean' | 'undefined' | ...
}

function typeMatches(value, expected) {
  if (value === null) return true; // M5 pattern: null tolerated everywhere
  switch (expected) {
    case 'int':
      return typeof value === 'number' && Number.isInteger(value);
    case 'number':
      return typeof value === 'number';
    case 'string':
      return typeof value === 'string';
    case 'boolean':
      return typeof value === 'boolean';
    case 'array':
      return Array.isArray(value);
    case 'map':
      return typeof value === 'object' && !Array.isArray(value) && runtimeTypeLabel(value) === 'map';
    default:
      return true;
  }
}

async function tally(collectionGroupName, fieldName) {
  const snap = await db.collectionGroup(collectionGroupName).get();

  const counts = new Map();
  let missingKey = 0;
  let nullValue = 0;
  let wrongType = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    if (!(fieldName in data)) {
      missingKey += 1;
      continue;
    }
    const value = data[fieldName];
    if (value === null) {
      nullValue += 1;
      continue;
    }
    if (typeof value !== 'string') {
      wrongType += 1;
      counts.set(`<${typeof value}> ${JSON.stringify(value)}`, (counts.get(`<non-string>`) || 0) + 1);
      continue;
    }
    counts.set(value, (counts.get(value) || 0) + 1);
  }

  return { totalDocs: snap.size, counts, missingKey, nullValue, wrongType };
}

async function auditSettings() {
  const snap = await db.collectionGroup('settings').get();
  const docs = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const keys = Object.keys(data);
    const fields = keys.map((key) => {
      const value = data[key];
      const actualType = runtimeTypeLabel(value);
      const known = key in KNOWN_SETTINGS_FIELDS;
      const expected = known ? KNOWN_SETTINGS_FIELDS[key] : null;
      const mismatch = known && !typeMatches(value, expected);
      return { key, actualType, known, expected, mismatch };
    });

    docs.push({
      path: doc.ref.path,
      keyCount: keys.length,
      overCap: keys.length > SETTINGS_KEY_CAP,
      fields,
    });
  }

  return { totalDocs: snap.size, docs };
}

function reportSettings(result) {
  console.log(`\n=== settings (audit M5) ===`);
  console.log(`documents scannés : ${result.totalDocs} (plafond rules : ${SETTINGS_KEY_CAP} clés)`);

  for (const doc of result.docs) {
    const capFlag = doc.overCap ? `  <-- DÉPASSE LE PLAFOND (${SETTINGS_KEY_CAP})` : '';
    console.log(`\n  ${doc.path} — ${doc.keyCount} clé(s)${capFlag}`);
    for (const f of doc.fields) {
      let flag = '';
      if (!f.known) flag = '  <-- clé absente de settings.dart';
      else if (f.mismatch) flag = `  <-- type attendu "${f.expected}", trouvé "${f.actualType}"`;
      console.log(`      ${f.key.padEnd(24)} ${f.actualType.padEnd(10)}${flag}`);
    }
  }

  const overCapDocs = result.docs.filter((d) => d.overCap);
  const unknownKeyDocs = result.docs.filter((d) => d.fields.some((f) => !f.known));
  const mismatchDocs = result.docs.filter((d) => d.fields.some((f) => f.mismatch));

  console.log('\n  résumé :');
  console.log(`    docs au-delà du plafond de ${SETTINGS_KEY_CAP} clés : ${overCapDocs.length}`);
  console.log(`    docs avec une clé inconnue de settings.dart        : ${unknownKeyDocs.length}`);
  console.log(`    docs avec un type qui diverge de settings.dart     : ${mismatchDocs.length}`);
  if (overCapDocs.length || unknownKeyDocs.length || mismatchDocs.length) {
    console.log('    -> si la rule M5 (déjà commitée, PAS ENCORE déployée) est déployée telle quelle, ces documents deviendront non modifiables (allow write refusé) au prochain write.');
  }
}

async function auditDefaultRates() {
  const snap = await db.collectionGroup('clients').get();
  let absentCount = 0;
  const issues = [];

  for (const doc of snap.docs) {
    const data = doc.data();
    const path = doc.ref.path;

    if (!('defaultRates' in data) || data.defaultRates === null) {
      absentCount += 1;
      continue; // toléré par le fix M3, pas un problème
    }

    const dr = data.defaultRates;
    if (typeof dr !== 'object' || Array.isArray(dr)) {
      issues.push({ path, issue: `defaultRates n'est pas une map (type: ${runtimeTypeLabel(dr)})` });
      continue;
    }

    for (const key of ['hour', 'halfDay', 'day', 'fixedJob']) {
      if (!(key in dr) || dr[key] === null) continue; // toléré
      const value = dr[key];
      if (typeof value !== 'number' || !Number.isInteger(value)) {
        issues.push({
          path,
          issue: `defaultRates.${key} n'est pas un int (valeur: ${JSON.stringify(value)}, type: ${runtimeTypeLabel(value)})`,
        });
      } else if (value < 0) {
        issues.push({ path, issue: `defaultRates.${key} négatif (${value})` });
      }
    }
  }

  return { totalDocs: snap.size, absentCount, issues };
}

function reportDefaultRates(result) {
  console.log(`\n=== clients.defaultRates (audit M3) ===`);
  console.log(`documents scannés     : ${result.totalDocs}`);
  console.log(`defaultRates absent   : ${result.absentCount} (toléré par le fix M3, pas un problème)`);
  console.log(`documents en violation du fix M3 : ${result.issues.length}`);
  for (const { path, issue } of result.issues) {
    console.log(`  ${path} — ${issue}`);
  }
  if (result.issues.length) {
    console.log('  -> si la rule M3 (déjà commitée, PAS ENCORE déployée) est déployée telle quelle, ces documents deviendront non modifiables (allow write refusé) au prochain write.');
  }
}

function report(label, knownKey, result) {
  console.log(`\n=== ${label} ===`);
  console.log(`documents scannés : ${result.totalDocs}`);
  console.log(`champ absent      : ${result.missingKey}`);
  console.log(`champ null        : ${result.nullValue}`);
  if (result.wrongType) console.log(`type inattendu    : ${result.wrongType} (!)`);

  const known = new Set(KNOWN[knownKey]);
  const sorted = [...result.counts.entries()].sort((a, b) => b[1] - a[1]);

  console.log('valeurs distinctes trouvées :');
  for (const [value, count] of sorted) {
    const flag = known.has(value) ? '' : '  <-- ABSENTE de enums.dart / whitelist candidate';
    console.log(`  ${String(count).padStart(6)}  ${value}${flag}`);
  }
  if (sorted.length === 0) {
    console.log('  (aucune valeur non-nulle trouvée)');
  }

  const unused = KNOWN[knownKey].filter((v) => !result.counts.has(v));
  if (unused.length) {
    console.log(`valeurs connues jamais utilisées en base : ${unused.join(', ')}`);
  }
}

const projectsResult = await tally('projects', 'type');
report('project.type', 'projects.type', projectsResult);

const materialResult = await tally('expenses', 'materialCategory');
report('expense.materialCategory', 'expenses.materialCategory', materialResult);

const travelResult = await tally('expenses', 'travelMode');
report('expense.travelMode', 'expenses.travelMode', travelResult);

const settingsResult = await auditSettings();
reportSettings(settingsResult);

const defaultRatesResult = await auditDefaultRates();
reportDefaultRates(defaultRatesResult);

console.log('\nAucune modification effectuée. Sections 1 = décider les whitelists M4. Sections 2-3 = vérifier que le fix M5/M3 commité (non déployé) ne bloquera aucun document réel avant de déployer.');
process.exit(0);
