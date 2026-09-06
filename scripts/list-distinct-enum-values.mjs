// Read-only reconnaissance script for R-SEC.2 / M4.
//
// Lists the DISTINCT values actually present in production for the three
// fields that have no Firestore rules whitelist today (SECURITY_AUDIT.md
// M4): project.type, expense.materialCategory, expense.travelMode.
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
// Cost note: this does a full collectionGroup scan of `projects` and
// `expenses` across every user (no filters). For this app's expected data
// volume that's cheap, but re-check before running it on a much larger
// dataset.

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

console.log('\nAucune modification effectuée. À utiliser pour décider du contenu des whitelists M4 dans firestore.rules.');
process.exit(0);
