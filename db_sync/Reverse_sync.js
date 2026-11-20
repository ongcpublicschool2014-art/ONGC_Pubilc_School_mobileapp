import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// Supabase PostgreSQL connection (SOURCE - via Transaction Pooler)
const supabasePool = new Pool({
  host: process.env.SUPABASE_DB_HOST,
  port: parseInt(process.env.SUPABASE_DB_PORT),
  database: process.env.SUPABASE_DB_NAME,
  user: process.env.SUPABASE_DB_USER,
  password: process.env.SUPABASE_DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
});

// Local PostgreSQL connection (DESTINATION)
const localPool = new Pool({
  host: process.env.LOCAL_DB_HOST,
  port: parseInt(process.env.LOCAL_DB_PORT),
  database: process.env.LOCAL_DB_NAME,
  user: process.env.LOCAL_DB_USER,
  password: process.env.LOCAL_DB_PASSWORD,
});

// Batch size for bulk inserts (adjust based on your needs)
const BATCH_SIZE = 100;

// Tables in order of dependencies (tables with no FK first)
const TABLES_ORDER = [
  // Base tables (no FK)
  'currency',
  'institutiontype',
  'year',
  'concessioncategory',
  'paymentgateway',
  'bank',
  'payment',
  'paymentdetails',
  'modules',
  'institutionyear',
  // Location hierarchy
  'country',
  'state',
  'city',
  // Institution and related
  'institution',
  'custuserroles',
  'staffdesignation',
  'institutionusers',
  // Activity and sequence
  'activitytype',
  'sequence',
  // Fee structure (depends on institution, year)
  'feegroup',
  'feetype',
  // Parents and students
  'parents',
  'students',
  // Junction table (depends on parents and students)
  'parentdetail',
  // Fee related (depends on students, year, feetype)
  'challan',
  'feedemand',
  // Login tracking
  'userlogin',
];

// Identity columns for sequence reset
// Note: concessioncategory, userlogin, bank, feegroup, feetype do NOT have identity columns
const identityColumns = {
  currency: 'cur_id',
  institutiontype: 'it_id',
  year: 'yr_id',
  paymentgateway: 'gw_id',
  payment: 'pay_id',
  paymentdetails: 'pyd_id',
  modules: 'mod_id',
  institutionyear: 'iyr_id',
  country: 'cou_id',
  state: 'sta_id',
  city: 'cit_id',
  institution: 'ins_id',
  custuserroles: 'ur_id',
  staffdesignation: 'des_id',
  institutionusers: 'use_id',
  activitytype: 'act_id',
  sequence: 'seq_id',
  parents: 'par_id',
  students: 'stu_id',
  parentdetail: 'pd_id',
  challan: 'cha_id',
  feedemand: 'dem_id',
  // userlogin has ul_id but it's NOT an identity column
};

const isDryRun = process.argv.includes('--dry-run');
const clearFirst = process.argv.includes('--clear');

// Tables that should always be cleared before sync to prevent duplicates
const TABLES_ALWAYS_CLEAR = [];

// Tables that need UPSERT (ON CONFLICT DO UPDATE) instead of just INSERT
// Key = table name, Value = primary key column for conflict detection
// These tables may be updated from the app (e.g., feedemand after payment)
const TABLES_UPSERT = {
  feedemand: 'dem_id',
  payment: 'pay_id',
  paymentdetails: 'pyd_id',
  sequence: 'seq_id',
  institution: 'ins_id',
  students: 'stu_id',
};

// Tables that use trigger-based auto-increment (not GENERATED ALWAYS AS IDENTITY)
// Triggers must be disabled during sync so they don't override the incoming IDs
const TABLES_WITH_TRIGGERS = ['payment', 'paymentdetails'];

/**
 * Get all data from Supabase table (SOURCE)
 */
async function getTableData(tableName) {
  try {
    const result = await supabasePool.query(`SELECT * FROM public.${tableName}`);
    return result.rows;
  } catch (error) {
    console.error(`  [ERROR] Reading ${tableName}: ${error.message}`);
    return [];
  }
}

/**
 * Clear table in Local DB before sync
 */
async function clearTable(tableName) {
  try {
    await localPool.query(`TRUNCATE TABLE public.${tableName} CASCADE`);
    return true;
  } catch (error) {
    console.warn(`  [WARN] Could not clear ${tableName}: ${error.message}`);
    return false;
  }
}

/**
 * Build batch INSERT query with multiple value sets
 * For UPSERT tables: ON CONFLICT (pk) DO UPDATE SET all columns
 * For other tables: ON CONFLICT DO NOTHING
 */
function buildBatchInsertQuery(tableName, columns, batch) {
  const columnList = columns.map(c => `"${c}"`).join(', ');

  let paramIndex = 1;
  const valueSets = [];
  const allValues = [];

  for (const row of batch) {
    const placeholders = columns.map(() => `$${paramIndex++}`).join(', ');
    valueSets.push(`(${placeholders})`);
    columns.forEach(col => allValues.push(row[col]));
  }

  let conflictClause;
  const upsertPk = TABLES_UPSERT[tableName];

  if (upsertPk) {
    // UPSERT: update all columns except the primary key on conflict
    const updateCols = columns
      .filter(c => c !== upsertPk)
      .map(c => `"${c}" = EXCLUDED."${c}"`)
      .join(', ');
    conflictClause = `ON CONFLICT ("${upsertPk}") DO UPDATE SET ${updateCols}`;
  } else {
    conflictClause = 'ON CONFLICT DO NOTHING';
  }

  const query = `INSERT INTO public.${tableName} (${columnList}) OVERRIDING SYSTEM VALUE VALUES ${valueSets.join(', ')} ${conflictClause}`;

  return { query, values: allValues };
}

/**
 * Sync table using batch inserts for speed
 */
async function syncTable(tableName, data) {
  if (data.length === 0) {
    console.log(`  [SKIP] ${tableName}: No data to sync`);
    return { success: true, count: 0 };
  }

  if (isDryRun) {
    console.log(`  [DRY-RUN] ${tableName}: Would sync ${data.length} rows`);
    return { success: true, count: data.length };
  }

  try {
    const columns = Object.keys(data[0]);
    let totalInserted = 0;
    const startTime = Date.now();

    // Process in batches
    for (let i = 0; i < data.length; i += BATCH_SIZE) {
      const batch = data.slice(i, i + BATCH_SIZE);
      const { query, values } = buildBatchInsertQuery(tableName, columns, batch);

      try {
        const result = await localPool.query(query, values);
        totalInserted += result.rowCount || 0;
      } catch (batchError) {
        // If batch fails, try row by row for this batch
        console.log(`    [WARN] Batch failed, trying row-by-row for batch ${Math.floor(i/BATCH_SIZE) + 1}`);
        for (const row of batch) {
          try {
            let singleConflict;
            const upsertPk = TABLES_UPSERT[tableName];
            if (upsertPk) {
              const updateCols = columns
                .filter(c => c !== upsertPk)
                .map(c => `"${c}" = EXCLUDED."${c}"`)
                .join(', ');
              singleConflict = `ON CONFLICT ("${upsertPk}") DO UPDATE SET ${updateCols}`;
            } else {
              singleConflict = 'ON CONFLICT DO NOTHING';
            }
            const singleQuery = `INSERT INTO public.${tableName} (${columns.map(c => `"${c}"`).join(', ')}) OVERRIDING SYSTEM VALUE VALUES (${columns.map((_, idx) => `$${idx + 1}`).join(', ')}) ${singleConflict}`;
            const result = await localPool.query(singleQuery, columns.map(col => row[col]));
            totalInserted += result.rowCount || 0;
          } catch (rowError) {
            console.log(`      [FAIL] Row with ${columns[0]}=${row[columns[0]]}: ${rowError.message}`);
          }
        }
      }
    }

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`  [OK] ${tableName}: Synced ${totalInserted}/${data.length} rows in ${duration}s`);
    return { success: true, count: totalInserted };
  } catch (error) {
    console.error(`  [ERROR] ${tableName}: ${error.message}`);
    return { success: false, count: 0, error: error.message };
  }
}

/**
 * Reset sequence to max ID + 1
 */
async function resetSequence(tableName, idColumn) {
  try {
    const result = await localPool.query(
      `SELECT COALESCE(MAX("${idColumn}"), 0) + 1 as next_val FROM public.${tableName}`
    );
    const nextVal = result.rows[0].next_val;

    const seqResult = await localPool.query(`
      SELECT pg_get_serial_sequence('public.${tableName}', '${idColumn}') as seq_name
    `);

    if (seqResult.rows[0]?.seq_name) {
      await localPool.query(`SELECT setval('${seqResult.rows[0].seq_name}', ${nextVal}, false)`);
      console.log(`    Sequence reset to ${nextVal}`);
    }
  } catch (error) {
    // Ignore sequence reset errors
  }
}

/**
 * Main sync function
 */
async function main() {
  const startTime = Date.now();

  console.log('='.repeat(60));
  console.log('  Krishnasamy Institution Database REVERSE Sync Tool');
  console.log('  (Supabase -> Local PostgreSQL)');
  console.log('='.repeat(60));
  console.log(`Mode: ${isDryRun ? 'DRY RUN' : 'LIVE SYNC'}${clearFirst ? ' (CLEAR FIRST)' : ''}`);
  console.log(`Batch Size: ${BATCH_SIZE} rows`);
  console.log('');
  console.log('SOURCE - Supabase DB:');
  console.log(`  Host: ${process.env.SUPABASE_DB_HOST}:${process.env.SUPABASE_DB_PORT}`);
  console.log(`  Database: ${process.env.SUPABASE_DB_NAME}`);
  console.log('');
  console.log('DESTINATION - Local DB:');
  console.log(`  Host: ${process.env.LOCAL_DB_HOST}:${process.env.LOCAL_DB_PORT}`);
  console.log(`  Database: ${process.env.LOCAL_DB_NAME}`);
  console.log('='.repeat(60));

  // Test connections
  try {
    await supabasePool.query('SELECT 1');
    console.log('[OK] Connected to Supabase PostgreSQL (SOURCE)');
  } catch (error) {
    console.error('[ERROR] Cannot connect to Supabase:', error.message);
    process.exit(1);
  }

  try {
    await localPool.query('SELECT 1');
    console.log('[OK] Connected to Local PostgreSQL (DESTINATION)');
  } catch (error) {
    console.error('[ERROR] Cannot connect to Local PostgreSQL:', error.message);
    process.exit(1);
  }

  console.log('\n--- Starting Reverse Sync (Supabase -> Local) ---\n');

  const results = {
    success: [],
    failed: [],
    skipped: [],
  };

  // Clear tables first if --clear flag is set (reverse order)
  if (clearFirst && !isDryRun) {
    console.log('Clearing existing data in Local DB...\n');
    for (const tableName of [...TABLES_ORDER].reverse()) {
      await clearTable(tableName);
    }
    console.log('');
  }

  // Sync each table
  for (const tableName of TABLES_ORDER) {
    console.log(`Syncing: ${tableName}`);

    // Always clear specified tables to prevent duplicates
    if (!isDryRun && TABLES_ALWAYS_CLEAR.includes(tableName)) {
      console.log(`  [CLEAR] ${tableName}: Clearing to prevent duplicates`);
      await clearTable(tableName);
    }

    // Disable triggers for tables with trigger-based auto-increment
    // so the incoming IDs from Supabase are preserved as-is
    const hasTrigger = TABLES_WITH_TRIGGERS.includes(tableName);
    if (!isDryRun && hasTrigger) {
      await localPool.query(`ALTER TABLE public.${tableName} DISABLE TRIGGER ALL`);
      console.log(`  [TRIGGER] Disabled triggers for ${tableName}`);
    }

    const data = await getTableData(tableName);
    const result = await syncTable(tableName, data);

    // Re-enable triggers after sync
    if (!isDryRun && hasTrigger) {
      await localPool.query(`ALTER TABLE public.${tableName} ENABLE TRIGGER ALL`);
      console.log(`  [TRIGGER] Re-enabled triggers for ${tableName}`);
    }

    // Delete stale local rows not present in Supabase (for UPSERT tables)
    const upsertPk = TABLES_UPSERT[tableName];
    if (!isDryRun && upsertPk && data.length > 0) {
      try {
        const sourceIds = data.map(row => row[upsertPk]);
        const placeholders = sourceIds.map((_, i) => `$${i + 1}`).join(', ');
        const delResult = await localPool.query(
          `DELETE FROM public.${tableName} WHERE "${upsertPk}" NOT IN (${placeholders})`,
          sourceIds
        );
        if (delResult.rowCount > 0) {
          console.log(`  [CLEANUP] Deleted ${delResult.rowCount} stale rows from ${tableName}`);
        }
      } catch (delError) {
        console.warn(`  [WARN] Cleanup failed for ${tableName}: ${delError.message}`);
      }
    }

    if (result.count === 0) {
      results.skipped.push(tableName);
    } else if (result.success) {
      results.success.push({ table: tableName, count: result.count });

      // Reset sequence after successful sync
      if (!isDryRun && identityColumns[tableName]) {
        await resetSequence(tableName, identityColumns[tableName]);
      }
    } else {
      results.failed.push({ table: tableName, error: result.error });
    }
  }

  const totalDuration = ((Date.now() - startTime) / 1000).toFixed(2);

  // Summary
  console.log('\n' + '='.repeat(60));
  console.log('  REVERSE SYNC SUMMARY');
  console.log('='.repeat(60));

  console.log(`\nSuccessful: ${results.success.length} tables`);
  results.success.forEach(r => console.log(`  - ${r.table}: ${r.count} rows`));

  console.log(`\nSkipped (no data): ${results.skipped.length} tables`);
  results.skipped.forEach(t => console.log(`  - ${t}`));

  if (results.failed.length > 0) {
    console.log(`\nFailed: ${results.failed.length} tables`);
    results.failed.forEach(r => console.log(`  - ${r.table}: ${r.error}`));
  }

  const totalRows = results.success.reduce((sum, r) => sum + r.count, 0);
  console.log('\n' + '='.repeat(60));
  console.log(`  Total rows synced: ${totalRows}`);
  console.log(`  Total time: ${totalDuration}s`);
  console.log('  Reverse Sync completed!');
  console.log('='.repeat(60));

  await supabasePool.end();
  await localPool.end();
  process.exit(0);
}

// Error handlers
process.on('unhandledRejection', (error) => {
  console.error('\n[X] Unhandled error:', error);
  process.exit(1);
});

process.on('SIGINT', () => {
  console.log('\n\nSync interrupted by user.\n');
  process.exit(1);
});

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
