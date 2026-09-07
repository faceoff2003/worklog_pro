// Rules-unit-testing suite for firestore.rules (R-SEC.2).
//
// Run against the emulator only, from the repo root:
//   firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
//
// Never run against production. This suite never calls firebase deploy.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { test, describe, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RULES_PATH = path.resolve(__dirname, '../firestore.rules');

const OWNER = 'owner-uid';
const OTHER = 'other-uid';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-worklog-pro',
    firestore: { rules: fs.readFileSync(RULES_PATH, 'utf8') },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function ownerDb() {
  return testEnv.authenticatedContext(OWNER).firestore();
}
function otherDb() {
  return testEnv.authenticatedContext(OTHER).firestore();
}
function anonDb() {
  return testEnv.unauthenticatedContext().firestore();
}

async function seed(collectionName, docId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection(`users/${OWNER}/${collectionName}`).doc(docId).set(data);
  });
}

function docRef(db, collectionName, docId) {
  return db.collection(`users/${OWNER}/${collectionName}`).doc(docId);
}

/**
 * Standard 5-check pattern (owner allowed / other denied / unauthenticated
 * denied / invalid payload denied / valid payload allowed), plus read and
 * the update path (validation must not be weaker than create), for a
 * collection whose create/update rules are otherwise identical.
 */
function testStandardCollection(collectionName, { valid, invalid }) {
  describe(collectionName, () => {
    test('create — payload valide, owner → autorisé', async () => {
      await assertSucceeds(docRef(ownerDb(), collectionName, 'doc1').set(valid()));
    });

    test('create — payload invalide, owner → refusé', async () => {
      await assertFails(docRef(ownerDb(), collectionName, 'doc1').set(invalid()));
    });

    test('create — autre utilisateur → refusé', async () => {
      await assertFails(docRef(otherDb(), collectionName, 'doc1').set(valid()));
    });

    test('create — non authentifié → refusé', async () => {
      await assertFails(docRef(anonDb(), collectionName, 'doc1').set(valid()));
    });

    test('update — payload valide (createdAt inchangé) → autorisé', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertSucceeds(docRef(ownerDb(), collectionName, 'doc1').update({ updatedAt: new Date() }));
    });

    test('update — payload invalide → refusé', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertFails(docRef(ownerDb(), collectionName, 'doc1').update(invalid()));
    });

    test('update — createdAt modifié → refusé (immuabilité)', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertFails(
        docRef(ownerDb(), collectionName, 'doc1').update({ createdAt: new Date('2099-01-01') }),
      );
    });

    test('read — owner → autorisé', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertSucceeds(docRef(ownerDb(), collectionName, 'doc1').get());
    });

    test('read — autre utilisateur → refusé', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertFails(docRef(otherDb(), collectionName, 'doc1').get());
    });

    test('read — non authentifié → refusé', async () => {
      await seed(collectionName, 'doc1', valid());
      await assertFails(docRef(anonDb(), collectionName, 'doc1').get());
    });
  });
}

// ─────────────────────────────────────────────────────────────
// clients
// ─────────────────────────────────────────────────────────────
testStandardCollection('clients', {
  valid: () => ({
    name: 'Jean Dupont',
    type: 'patron',
    defaultRates: { hour: null, halfDay: null, day: null, fixedJob: null },
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  invalid: () => ({
    name: 'Jean Dupont',
    type: 'type_qui_nexiste_pas',
    defaultRates: { hour: null, halfDay: null, day: null, fixedJob: null },
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

describe('clients — defaultRates (M3)', () => {
  const base = () => ({
    name: 'Jean Dupont',
    type: 'patron',
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  test('defaultRates absent du document → accepté (docs existants sans la map)', async () => {
    await assertSucceeds(docRef(ownerDb(), 'clients', 'doc1').set(base()));
  });

  test('defaultRates avec les 4 clés à null (nouveau client sans tarif) → accepté', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'clients', 'doc1').set({
        ...base(),
        defaultRates: { hour: null, halfDay: null, day: null, fixedJob: null },
      }),
    );
  });

  test('defaultRates avec valeurs entières positives → accepté', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'clients', 'doc1').set({
        ...base(),
        defaultRates: { hour: 2000, halfDay: 15000, day: 30000, fixedJob: null },
      }),
    );
  });

  test('defaultRates.hour négatif → refusé (M3 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'clients', 'doc1').set({
        ...base(),
        defaultRates: { hour: -500, halfDay: null, day: null, fixedJob: null },
      }),
    );
  });

  test('defaultRates.hour de mauvais type (string) → refusé (M3 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'clients', 'doc1').set({
        ...base(),
        defaultRates: { hour: 'gratuit', halfDay: null, day: null, fixedJob: null },
      }),
    );
  });

  test('defaultRates non-map (ex: chaîne) → refusé', async () => {
    await assertFails(
      docRef(ownerDb(), 'clients', 'doc1').set({ ...base(), defaultRates: 'invalide' }),
    );
  });

  test('defaultRates avec une seule clé renseignée (partiel) → accepté', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'clients', 'doc1').set({
        ...base(),
        defaultRates: { hour: 2000 },
      }),
    );
  });
});

// ─────────────────────────────────────────────────────────────
// projects
// ─────────────────────────────────────────────────────────────
testStandardCollection('projects', {
  valid: () => ({
    clientId: 'client-1',
    label: 'Chantier Rue de la Loi',
    status: 'actif',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  invalid: () => ({
    clientId: 'client-1',
    label: 'Chantier Rue de la Loi',
    status: 'statut_qui_nexiste_pas',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

describe('projects — type whitelist (M4)', () => {
  const base = () => ({
    clientId: 'client-1',
    label: 'Chantier Rue de la Loi',
    status: 'actif',
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  test('type absent du document → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'projects', 'doc1').set(base()));
  });

  test('type null → accepté (donnée réelle : le champ existe en base avec des valeurs null)', async () => {
    await assertSucceeds(docRef(ownerDb(), 'projects', 'doc1').set({ ...base(), type: null }));
  });

  test('type valeur valide (depannage) → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'projects', 'doc1').set({ ...base(), type: 'depannage' }));
  });

  test('type valeur invalide → refusé (M4 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'projects', 'doc1').set({ ...base(), type: 'type_qui_nexiste_pas' }),
    );
  });
});

// ─────────────────────────────────────────────────────────────
// workEntries
// ─────────────────────────────────────────────────────────────
testStandardCollection('workEntries', {
  valid: () => ({
    date: '2026-01-01',
    startTime: 480,
    endTime: 600,
    laborAmountHT: 1000,
    billingMode: 'hourly',
    clientId: 'client-1',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  invalid: () => ({
    date: '2026-01-01',
    startTime: 480,
    endTime: 600,
    laborAmountHT: -1000,
    billingMode: 'hourly',
    clientId: 'client-1',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

// ─────────────────────────────────────────────────────────────
// expenses
// ─────────────────────────────────────────────────────────────
testStandardCollection('expenses', {
  valid: () => ({
    date: '2026-01-01',
    clientId: 'client-1',
    category: 'materials',
    amountHT: 500,
    description: 'Câble 3G2.5',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  invalid: () => ({
    date: '2026-01-01',
    clientId: 'client-1',
    category: 'categorie_qui_nexiste_pas',
    amountHT: 500,
    description: 'Câble 3G2.5',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

describe('expenses — materialCategory / travelMode whitelist (M4)', () => {
  const base = () => ({
    date: '2026-01-01',
    clientId: 'client-1',
    category: 'materials',
    amountHT: 500,
    description: 'Câble 3G2.5',
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  test('materialCategory absent → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'expenses', 'doc1').set(base()));
  });

  test('materialCategory null → accepté (donnée réelle : 4 documents materialCategory null en prod)', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), materialCategory: null }),
    );
  });

  test('materialCategory valeur valide (cables) → accepté', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), materialCategory: 'cables' }),
    );
  });

  test('materialCategory valeur invalide → refusé (M4 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), materialCategory: 'nexiste_pas' }),
    );
  });

  test('travelMode absent → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'expenses', 'doc1').set(base()));
  });

  test('travelMode null → accepté (donnée réelle : 14/14 documents travelMode null en prod)', async () => {
    await assertSucceeds(docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), travelMode: null }));
  });

  test('travelMode valeur valide (per_km) → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), travelMode: 'per_km' }));
  });

  test('travelMode valeur invalide → refusé (M4 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'expenses', 'doc1').set({ ...base(), travelMode: 'nexiste_pas' }),
    );
  });
});

// ─────────────────────────────────────────────────────────────
// payments
// ─────────────────────────────────────────────────────────────
testStandardCollection('payments', {
  valid: () => ({
    date: '2026-01-01',
    clientId: 'client-1',
    amount: 1000,
    method: 'cash',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  invalid: () => ({
    date: '2026-01-01',
    clientId: 'client-1',
    amount: 0, // isStrictPositiveInt exige > 0
    method: 'cash',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
});

// ─────────────────────────────────────────────────────────────
// client_settlements — immuable (M2, non modifié dans ce sprint)
// ─────────────────────────────────────────────────────────────
describe('client_settlements', () => {
  const valid = () => ({
    clientId: 'client-1',
    date: '2026-01-01',
    balanceAtSettlement: 0,
    createdAt: new Date(),
  });
  const invalid = () => ({
    clientId: 'client-1',
    date: '2026-01-01',
    balanceAtSettlement: 'zero', // doit être un int
    createdAt: new Date(),
  });

  test('create — payload valide, owner → autorisé', async () => {
    await assertSucceeds(docRef(ownerDb(), 'client_settlements', 'doc1').set(valid()));
  });

  test('create — payload invalide, owner → refusé', async () => {
    await assertFails(docRef(ownerDb(), 'client_settlements', 'doc1').set(invalid()));
  });

  test('create — autre utilisateur → refusé', async () => {
    await assertFails(docRef(otherDb(), 'client_settlements', 'doc1').set(valid()));
  });

  test('create — non authentifié → refusé', async () => {
    await assertFails(docRef(anonDb(), 'client_settlements', 'doc1').set(valid()));
  });

  test('read — owner → autorisé', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertSucceeds(docRef(ownerDb(), 'client_settlements', 'doc1').get());
  });

  test('read — autre utilisateur → refusé', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertFails(docRef(otherDb(), 'client_settlements', 'doc1').get());
  });

  test('read — non authentifié → refusé', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertFails(docRef(anonDb(), 'client_settlements', 'doc1').get());
  });

  test('update — même payload valide, owner → refusé (immuable, M2)', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertFails(docRef(ownerDb(), 'client_settlements', 'doc1').update({ note: 'x' }));
  });

  test('delete — owner → refusé (M2 tranché : verrouillé, deleteSettlement() sans UI)', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertFails(docRef(ownerDb(), 'client_settlements', 'doc1').delete());
  });

  test('delete — autre utilisateur → refusé', async () => {
    await seed('client_settlements', 'doc1', valid());
    await assertFails(docRef(otherDb(), 'client_settlements', 'doc1').delete());
  });
});

// ─────────────────────────────────────────────────────────────
// settings — zéro validation aujourd'hui (M5)
// ─────────────────────────────────────────────────────────────
describe('settings', () => {
  const reasonable = () => ({
    dayHours: 8,
    halfDayHours: 4,
    defaultPauseMinutes: 0,
    roundingMinutes: 15,
    minBillingHours: 2.0,
    minBillingAmountCents: 2500,
    currency: 'EUR',
    country: 'BE',
    travelRatePerKmCents: 50,
    quickTasks: ['Tirage câble'],
    quickVendors: ['Brico'],
    pdfHeader: { name: 'Jean', phone: '', mentionHT: 'Prix HT' },
    autoBackupEnabled: false,
    schemaVersion: 1,
  });

  test('write — payload "raisonnable", owner → autorisé', async () => {
    await assertSucceeds(docRef(ownerDb(), 'settings', 'doc1').set(reasonable()));
  });

  test('write — payload avec champ mal typé (dayHours: string) → refusé (M5 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'settings', 'doc1').set({ ...reasonable(), dayHours: 'huit' }),
    );
  });

  test('write — document vide {} (doc legacy sans aucun champ connu) → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'settings', 'doc1').set({}));
  });

  test('write — un seul champ connu renseigné → accepté', async () => {
    await assertSucceeds(docRef(ownerDb(), 'settings', 'doc1').set({ schemaVersion: 1 }));
  });

  test('write — champ inconnu supplémentaire toléré (schéma non fermé) → accepté', async () => {
    await assertSucceeds(
      docRef(ownerDb(), 'settings', 'doc1').set({ ...reasonable(), champInconnu: 'ok' }),
    );
  });

  test('write — minBillingHours négatif → refusé (M5 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'settings', 'doc1').set({ ...reasonable(), minBillingHours: -1.0 }),
    );
  });

  test('write — quickTasks au-delà du plafond (201 éléments) → refusé (M5 corrigé)', async () => {
    await assertFails(
      docRef(ownerDb(), 'settings', 'doc1').set({
        ...reasonable(),
        quickTasks: Array.from({ length: 201 }, (_, i) => `tâche ${i}`),
      }),
    );
  });

  test('write — plus de 20 clés top-level → refusé (M5 corrigé)', async () => {
    const bloated = { ...reasonable() };
    for (let i = 0; i < 20; i += 1) bloated[`champExtra${i}`] = i;
    await assertFails(docRef(ownerDb(), 'settings', 'doc1').set(bloated));
  });

  test('write — autre utilisateur → refusé', async () => {
    await assertFails(docRef(otherDb(), 'settings', 'doc1').set(reasonable()));
  });

  test('write — non authentifié → refusé', async () => {
    await assertFails(docRef(anonDb(), 'settings', 'doc1').set(reasonable()));
  });

  test('read — owner → autorisé', async () => {
    await seed('settings', 'doc1', reasonable());
    await assertSucceeds(docRef(ownerDb(), 'settings', 'doc1').get());
  });

  test('read — autre utilisateur → refusé', async () => {
    await seed('settings', 'doc1', reasonable());
    await assertFails(docRef(otherDb(), 'settings', 'doc1').get());
  });

  test('read — non authentifié → refusé', async () => {
    await seed('settings', 'doc1', reasonable());
    await assertFails(docRef(anonDb(), 'settings', 'doc1').get());
  });
});

// ─────────────────────────────────────────────────────────────
// settings — doc fixe "main" (FirestoreSettingsRepository, F-SETTINGS.4)
//
// La rule elle-même ne distingue pas les IDs de document (voir le describe
// "settings" ci-dessus, doc1). Ce groupe caractérise le contrat exact que
// FirestoreSettingsRepository utilise en production : users/{uid}/settings/
// main, avec le nouveau champ updatedAt (DateTime? -> ISO string, ajouté à
// Settings pour F-SETTINGS.4).
// ─────────────────────────────────────────────────────────────
describe('settings — doc "main" (FirestoreSettingsRepository)', () => {
  const reasonableWithUpdatedAt = () => ({
    dayHours: 8,
    halfDayHours: 4,
    defaultPauseMinutes: 0,
    roundingMinutes: 15,
    minBillingHours: 2.0,
    minBillingAmountCents: 2500,
    currency: 'EUR',
    country: 'BE',
    travelRatePerKmCents: 50,
    quickTasks: ['Tirage câble'],
    quickVendors: ['Brico'],
    pdfHeader: { name: 'Jean', phone: '', mentionHT: 'Prix HT' },
    autoBackupEnabled: false,
    schemaVersion: 1,
    updatedAt: '2026-03-15T10:30:00.000Z',
  });

  test('lecture — doc absent → get() autorisé, exists === false', async () => {
    await assertSucceeds(docRef(ownerDb(), 'settings', 'main').get());
    const snap = await docRef(ownerDb(), 'settings', 'main').get();
    assert.equal(snap.exists, false);
  });

  test('lecture — doc existant → get() autorisé, données lisibles', async () => {
    await seed('settings', 'main', reasonableWithUpdatedAt());
    const snap = await docRef(ownerDb(), 'settings', 'main').get();
    assert.equal(snap.exists, true);
    assert.equal(snap.data().dayHours, 8);
  });

  test(
    'écriture — payload avec updatedAt (ISO string) → autorisé ' +
      '(répond à la question F-SETTINGS.4 : le champ n\'est pas rejeté)',
    async () => {
      await assertSucceeds(docRef(ownerDb(), 'settings', 'main').set(reasonableWithUpdatedAt()));
    },
  );

  test(
    'écriture — updatedAt de mauvais type (int au lieu de string ISO) → refusé ' +
      '(M5 corrigé : updatedAt arbitre les conflits de réconciliation, un type invalide ' +
      'ferait trancher dans le mauvais sens plutôt que de simplement planter une lecture)',
    async () => {
      await assertFails(
        docRef(ownerDb(), 'settings', 'main').set({ ...reasonableWithUpdatedAt(), updatedAt: 12345 }),
      );
    },
  );

  test('round-trip complet — écriture puis lecture renvoie exactement les mêmes valeurs, y compris updatedAt', async () => {
    const payload = reasonableWithUpdatedAt();
    await docRef(ownerDb(), 'settings', 'main').set(payload);
    const snap = await docRef(ownerDb(), 'settings', 'main').get();
    assert.deepEqual(snap.data(), payload);
  });

  test('écriture — autre utilisateur (uid différent) sur le doc "main" du owner → refusé', async () => {
    await assertFails(docRef(otherDb(), 'settings', 'main').set(reasonableWithUpdatedAt()));
  });
});

// ─────────────────────────────────────────────────────────────
// C-PORTAL — clientPortals/{portalUid}, espace miroir séparé
//
// Arbre top-level distinct de users/{userId}/... : la clé est l'uid du
// CLIENT (portalUid), jamais celui de l'artisan. Quatre identités
// distinctes pour ces tests, aucun chevauchement avec OWNER/OTHER
// utilisés plus haut (qui simulent des artisans dans les collections
// users/{userId}/...).
// ─────────────────────────────────────────────────────────────

const ARTISAN = 'artisan-uid';
const OTHER_ARTISAN = 'other-artisan-uid';
const CLIENT = 'client-portal-uid';
const OTHER_CLIENT = 'other-client-portal-uid';

function artisanDb() {
  return testEnv.authenticatedContext(ARTISAN).firestore();
}
function otherArtisanDb() {
  return testEnv.authenticatedContext(OTHER_ARTISAN).firestore();
}
function clientDb() {
  return testEnv.authenticatedContext(CLIENT).firestore();
}
function otherClientDb() {
  return testEnv.authenticatedContext(OTHER_CLIENT).firestore();
}

async function seedPortal(portalUid, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection('clientPortals')
      .doc(portalUid)
      .set({
        artisanUid: ARTISAN,
        clientId: 'client-doc-1',
        enabled: true,
        createdAt: new Date(),
        ...overrides,
      });
  });
}

async function seedWorkEntry(portalUid, entryId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection(`clientPortals/${portalUid}/workEntries`)
      .doc(entryId)
      .set({
        date: '2026-03-15',
        laborAmountHT: 5000,
        billingMode: 'hourly',
        createdAt: new Date(),
        updatedAt: new Date(),
        ...overrides,
      });
  });
}

async function seedExpense(portalUid, expenseId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx
      .firestore()
      .collection(`clientPortals/${portalUid}/expenses`)
      .doc(expenseId)
      .set({
        date: '2026-03-15',
        amountHT: 2000,
        description: 'Câble 3G2.5',
        isBillable: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        ...overrides,
      });
  });
}

function portalDocRef(db, portalUid) {
  return db.collection('clientPortals').doc(portalUid);
}
function workEntryRef(db, portalUid, entryId) {
  return db.collection(`clientPortals/${portalUid}/workEntries`).doc(entryId);
}
function expenseRef(db, portalUid, expenseId) {
  return db.collection(`clientPortals/${portalUid}/expenses`).doc(expenseId);
}
function commentRef(db, portalUid, entryId, commentId) {
  return db.collection(`clientPortals/${portalUid}/workEntries/${entryId}/portalComments`).doc(commentId);
}

describe('clientPortals/{portalUid} — profil', () => {
  test('create — artisan crée le profil de son propre client → autorisé', async () => {
    await assertSucceeds(
      portalDocRef(artisanDb(), CLIENT).set({
        artisanUid: ARTISAN,
        clientId: 'client-doc-1',
        enabled: true,
        createdAt: new Date(),
      }),
    );
  });

  test('create — artisan tente de créer en revendiquant un autre artisanUid → refusé', async () => {
    await assertFails(
      portalDocRef(artisanDb(), CLIENT).set({
        artisanUid: OTHER_ARTISAN,
        clientId: 'client-doc-1',
        enabled: true,
        createdAt: new Date(),
      }),
    );
  });

  test('create — non authentifié → refusé', async () => {
    await assertFails(
      portalDocRef(anonDb(), CLIENT).set({
        artisanUid: ARTISAN,
        clientId: 'client-doc-1',
        enabled: true,
        createdAt: new Date(),
      }),
    );
  });

  test('read — le client lit son propre profil, enabled=true → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await assertSucceeds(portalDocRef(clientDb(), CLIENT).get());
  });

  test('read — le client lit son propre profil MÊME désactivé → autorisé (doit pouvoir afficher "accès désactivé")', async () => {
    await seedPortal(CLIENT, { enabled: false });
    await assertSucceeds(portalDocRef(clientDb(), CLIENT).get());
  });

  test('read — un autre client ne peut pas lire ce profil → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(otherClientDb(), CLIENT).get());
  });

  test('read — l\'artisan lié lui-même ne peut pas lire le profil via un get() direct (seul list, filtré, lui est ouvert — voir plus bas)', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(artisanDb(), CLIENT).get());
  });

  test('update — artisan lié bascule enabled → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await assertSucceeds(portalDocRef(artisanDb(), CLIENT).update({ enabled: false }));
  });

  test('update — artisan lié tente de changer artisanUid → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(artisanDb(), CLIENT).update({ artisanUid: OTHER_ARTISAN }));
  });

  test('update — artisan lié tente de changer clientId → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(artisanDb(), CLIENT).update({ clientId: 'un-autre-client' }));
  });

  test('update — un artisan NON lié ne peut ni activer/désactiver ni rien changer → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(otherArtisanDb(), CLIENT).update({ enabled: false }));
  });

  test('update — le client modifie un champ à lui (displayName) sans toucher enabled → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true, displayName: 'Ancien nom' });
    await assertSucceeds(portalDocRef(clientDb(), CLIENT).update({ displayName: 'Nouveau nom' }));
  });

  test('update — le client tente de repasser enabled à true tout seul → refusé', async () => {
    await seedPortal(CLIENT, { enabled: false });
    await assertFails(portalDocRef(clientDb(), CLIENT).update({ enabled: true }));
  });

  test(
    'update — le client tente de repasser enabled à true NOYÉ dans un update qui change aussi displayName ' +
      '→ refusé (le contournement précis à bloquer)',
    async () => {
      await seedPortal(CLIENT, { enabled: false, displayName: 'Ancien nom' });
      await assertFails(
        portalDocRef(clientDb(), CLIENT).update({ enabled: true, displayName: 'Nouveau nom' }),
      );
    },
  );

  test('update — le client tente de changer artisanUid seul → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(portalDocRef(clientDb(), CLIENT).update({ artisanUid: OTHER_ARTISAN }));
  });

  test(
    'update — le client tente de changer artisanUid NOYÉ dans un update multi-champs → refusé',
    async () => {
      await seedPortal(CLIENT, { displayName: 'Ancien nom' });
      await assertFails(
        portalDocRef(clientDb(), CLIENT).update({
          artisanUid: OTHER_ARTISAN,
          displayName: 'Nouveau nom',
        }),
      );
    },
  );
});

describe('clientPortals — list() filtré pour l\'artisan (réparation d\'un lien manquant)', () => {
  test('artisan, requête filtrée par where("artisanUid","==",moi) → autorisé, ne renvoie que ses portails', async () => {
    await seedPortal(CLIENT, { artisanUid: ARTISAN });
    await seedPortal(OTHER_CLIENT, { artisanUid: OTHER_ARTISAN });

    const snap = await assertSucceeds(
      artisanDb().collection('clientPortals').where('artisanUid', '==', ARTISAN).get(),
    );

    assert.equal(snap.size, 1);
    assert.equal(snap.docs[0].id, CLIENT);
  });

  test('artisan, requête SANS filtre sur toute la collection → refusé', async () => {
    await seedPortal(CLIENT, { artisanUid: ARTISAN });

    await assertFails(artisanDb().collection('clientPortals').get());
  });

  test('client portail, requête filtrée par where("artisanUid","==",ARTISAN réel) → refusé', async () => {
    await seedPortal(CLIENT, { artisanUid: ARTISAN });

    await assertFails(clientDb().collection('clientPortals').where('artisanUid', '==', ARTISAN).get());
  });

  test('client portail, requête SANS filtre → refusé', async () => {
    await seedPortal(CLIENT, { artisanUid: ARTISAN });

    await assertFails(clientDb().collection('clientPortals').get());
  });

  test(
    'client portail, requête filtrée par where("artisanUid","==",SON PROPRE uid) → AUTORISÉE mais ' +
      'structurellement toujours vide, PAS refusée — trouvaille, pas une preuve d\'étanchéité complète. ' +
      'Firestore ne prouve la règle que contre les CONTRAINTES de la requête (artisanUid == request.auth.uid, ' +
      'ce qui est vrai ici) sans savoir qu\'aucun document réel n\'a jamais artisanUid == un uid de client ' +
      'portail — cette garantie vient de allow create (jamais de allow list qui la referait), pas de cette ' +
      'règle. Zéro donnée réelle n\'est jamais exposée par cette requête (elle ne peut renvoyer qu\'un document ' +
      'que ce client aurait lui-même créé en s\'auto-désignant artisanUid — capacité inhabituelle mais sans '+
      'portée sur les données d\'un autre client ou d\'un artisan), donc jugé non exploitable en l\'état — à ' +
      'rouvrir si le modèle de données change.',
    async () => {
      await seedPortal(CLIENT, { artisanUid: ARTISAN });

      const snap = await assertSucceeds(
        clientDb().collection('clientPortals').where('artisanUid', '==', CLIENT).get(),
      );
      assert.equal(snap.size, 0);
    },
  );
});

describe('clientPortals/{portalUid}/workEntries/{entryId} — miroir', () => {
  test('create — artisan lié → autorisé', async () => {
    await seedPortal(CLIENT);
    await assertSucceeds(
      workEntryRef(artisanDb(), CLIENT, 'entry-1').set({
        date: '2026-03-15',
        laborAmountHT: 5000,
        billingMode: 'hourly',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('create — un artisan NON lié à ce client → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(
      workEntryRef(otherArtisanDb(), CLIENT, 'entry-1').set({
        date: '2026-03-15',
        laborAmountHT: 5000,
        billingMode: 'hourly',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('create — le client lui-même tente d\'écrire dans son miroir (lecture seule) → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(
      workEntryRef(clientDb(), CLIENT, 'entry-1').set({
        date: '2026-03-15',
        laborAmountHT: 5000,
        billingMode: 'hourly',
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('read — client owner, portail activé → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertSucceeds(workEntryRef(clientDb(), CLIENT, 'entry-1').get());
  });

  test('read — client owner, portail désactivé → refusé', async () => {
    await seedPortal(CLIENT, { enabled: false });
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertFails(workEntryRef(clientDb(), CLIENT, 'entry-1').get());
  });

  test('list — client owner, 5 prestations, portail activé, .get() non contraint sur toute la collection → autorisé, les 5 renvoyées', async () => {
    await seedPortal(CLIENT, { enabled: true });
    for (let i = 0; i < 5; i++) {
      await seedWorkEntry(CLIENT, `entry-${i}`);
    }
    const snap = await assertSucceeds(clientDb().collection(`clientPortals/${CLIENT}/workEntries`).get());
    assert.equal(snap.size, 5);
  });

  test(
    'aucune fenêtre de propagation : désactiver le portail retire IMMÉDIATEMENT l\'accès à un document déjà existant, ' +
      'sans réécrire ce document — une seule écriture sur le profil suffit (plus de champ dénormalisé à propager)',
    async () => {
      await seedPortal(CLIENT, { enabled: true });
      await seedWorkEntry(CLIENT, 'entry-1');
      await assertSucceeds(workEntryRef(clientDb(), CLIENT, 'entry-1').get());

      await portalDocRef(artisanDb(), CLIENT).update({ enabled: false });

      await assertFails(workEntryRef(clientDb(), CLIENT, 'entry-1').get());
    },
  );

  test('read — un autre client ne peut pas lire ce miroir → refusé', async () => {
    await seedPortal(CLIENT);
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertFails(workEntryRef(otherClientDb(), CLIENT, 'entry-1').get());
  });

  test('update — artisan lié, createdAt inchangé → autorisé', async () => {
    await seedPortal(CLIENT);
    await seedWorkEntry(CLIENT, 'entry-1');
    // L'artisan n'a pas de allow read sur ce miroir (écriture seule côté
    // rules) : on relit createdAt hors rules, comme les helpers seed().
    let existingCreatedAt;
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const snap = await ctx.firestore().collection(`clientPortals/${CLIENT}/workEntries`).doc('entry-1').get();
      existingCreatedAt = snap.data().createdAt;
    });
    await assertSucceeds(
      workEntryRef(artisanDb(), CLIENT, 'entry-1').set({
        date: '2026-03-16',
        laborAmountHT: 6000,
        billingMode: 'hourly',
        createdAt: existingCreatedAt,
        updatedAt: new Date(),
      }),
    );
  });

  test('update — artisan lié tente de changer createdAt → refusé', async () => {
    await seedPortal(CLIENT);
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertFails(
      workEntryRef(artisanDb(), CLIENT, 'entry-1').set({
        date: '2026-03-16',
        laborAmountHT: 6000,
        billingMode: 'hourly',
        createdAt: new Date('2099-01-01'),
        updatedAt: new Date(),
      }),
    );
  });

  test('delete — artisan lié → autorisé', async () => {
    await seedPortal(CLIENT);
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertSucceeds(workEntryRef(artisanDb(), CLIENT, 'entry-1').delete());
  });

  test('delete — un artisan NON lié → refusé', async () => {
    await seedPortal(CLIENT);
    await seedWorkEntry(CLIENT, 'entry-1');
    await assertFails(workEntryRef(otherArtisanDb(), CLIENT, 'entry-1').delete());
  });
});

describe('clientPortals/{portalUid}/expenses/{expenseId} — miroir (isBillable uniquement)', () => {
  test('create — artisan lié, isBillable true → autorisé', async () => {
    await seedPortal(CLIENT);
    await assertSucceeds(
      expenseRef(artisanDb(), CLIENT, 'exp-1').set({
        date: '2026-03-15',
        amountHT: 2000,
        description: 'Câble 3G2.5',
        isBillable: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test(
    'create — artisan lié, isBillable false → refusé (réaffirmé par la règle, pas seulement par le code Dart)',
    async () => {
      await seedPortal(CLIENT);
      await assertFails(
        expenseRef(artisanDb(), CLIENT, 'exp-1').set({
          date: '2026-03-15',
          amountHT: 2000,
          description: 'Câble 3G2.5',
          isBillable: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );
    },
  );

  test('create — un artisan NON lié → refusé', async () => {
    await seedPortal(CLIENT);
    await assertFails(
      expenseRef(otherArtisanDb(), CLIENT, 'exp-1').set({
        date: '2026-03-15',
        amountHT: 2000,
        description: 'Câble 3G2.5',
        isBillable: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }),
    );
  });

  test('read — client owner, portail activé → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await seedExpense(CLIENT, 'exp-1');
    await assertSucceeds(expenseRef(clientDb(), CLIENT, 'exp-1').get());
  });

  test('read — client owner, portail désactivé → refusé', async () => {
    await seedPortal(CLIENT, { enabled: false });
    await seedExpense(CLIENT, 'exp-1');
    await assertFails(expenseRef(clientDb(), CLIENT, 'exp-1').get());
  });

  test('delete — artisan lié → autorisé', async () => {
    await seedPortal(CLIENT);
    await seedExpense(CLIENT, 'exp-1');
    await assertSucceeds(expenseRef(artisanDb(), CLIENT, 'exp-1').delete());
  });
});

describe('clientPortals/{portalUid}/workEntries/{entryId}/portalComments — écriture cliente, immuables', () => {
  test('create — client owner, portail activé → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await assertSucceeds(
      commentRef(clientDb(), CLIENT, 'entry-1', 'comment-1').set({
        text: 'Question sur cette prestation',
        createdAt: new Date(),
      }),
    );
  });

  test('create — client owner, portail désactivé → refusé (ni lecture ni écriture quand disabled)', async () => {
    await seedPortal(CLIENT, { enabled: false });
    await assertFails(
      commentRef(clientDb(), CLIENT, 'entry-1', 'comment-1').set({
        text: 'Question sur cette prestation',
        createdAt: new Date(),
      }),
    );
  });

  test('create — un autre client tente de créer dans un espace qui n\'est pas le sien → refusé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await assertFails(
      commentRef(otherClientDb(), CLIENT, 'entry-1', 'comment-1').set({
        text: 'Question sur cette prestation',
        createdAt: new Date(),
      }),
    );
  });

  test('read — client owner, portail activé → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection(`clientPortals/${CLIENT}/workEntries/entry-1/portalComments`)
        .doc('comment-1')
        .set({ text: 'Une question', createdAt: new Date() });
    });
    await assertSucceeds(commentRef(clientDb(), CLIENT, 'entry-1', 'comment-1').get());
  });

  test('read — artisan lié peut lire les commentaires de son client → autorisé', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection(`clientPortals/${CLIENT}/workEntries/entry-1/portalComments`)
        .doc('comment-1')
        .set({ text: 'Une question', createdAt: new Date() });
    });
    await assertSucceeds(commentRef(artisanDb(), CLIENT, 'entry-1', 'comment-1').get());
  });

  test('update — le client tente de modifier son propre commentaire → refusé (immuable)', async () => {
    await seedPortal(CLIENT, { enabled: true });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .collection(`clientPortals/${CLIENT}/workEntries/entry-1/portalComments`)
        .doc('comment-1')
        .set({ text: 'Une question', createdAt: new Date() });
    });
    await assertFails(commentRef(clientDb(), CLIENT, 'entry-1', 'comment-1').update({ text: 'Modifié' }));
  });

  test(
    'delete — ni le client NI l\'artisan lié ne peuvent supprimer un commentaire → refusé ' +
      '(M2 : update ET delete bloqués ensemble, sinon delete+recreate contourne l\'immuabilité)',
    async () => {
      await seedPortal(CLIENT, { enabled: true });
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx
          .firestore()
          .collection(`clientPortals/${CLIENT}/workEntries/entry-1/portalComments`)
          .doc('comment-1')
          .set({ text: 'Une question', createdAt: new Date() });
      });
      await assertFails(commentRef(clientDb(), CLIENT, 'entry-1', 'comment-1').delete());
      await assertFails(commentRef(artisanDb(), CLIENT, 'entry-1', 'comment-1').delete());
    },
  );
});
