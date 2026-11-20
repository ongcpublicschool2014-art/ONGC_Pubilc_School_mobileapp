import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const local = new Pool({
  host: process.env.LOCAL_DB_HOST,
  port: parseInt(process.env.LOCAL_DB_PORT),
  database: process.env.LOCAL_DB_NAME,
  user: process.env.LOCAL_DB_USER,
  password: process.env.LOCAL_DB_PASSWORD,
});

const supa = new Pool({
  host: process.env.SUPABASE_DB_HOST,
  port: parseInt(process.env.SUPABASE_DB_PORT),
  database: process.env.SUPABASE_DB_NAME,
  user: process.env.SUPABASE_DB_USER,
  password: process.env.SUPABASE_DB_PASSWORD,
  ssl: { rejectUnauthorized: false },
});

const tables = [
  'currency', 'institutiontype', 'year', 'concessioncategory',
  'paymentgateway', 'bank', 'payment', 'shoppingcart', 'modules',
  'institutionyear', 'country', 'state', 'city', 'institution',
  'custuserroles', 'staffdesignation', 'institutionusers',
  'activitytype', 'sequence', 'feegroup', 'feetype',
  'parents', 'students', 'parentdetail', 'challan',
  'feedemand', 'shoppingcartdetails', 'userlogin',
];

console.log('='.repeat(60));
console.log('  Krishnasamy Institution - Sync Status Check');
console.log('='.repeat(60));
console.log('');
console.log('Table'.padEnd(25) + 'Local'.padEnd(10) + 'Supabase'.padEnd(10) + 'Status');
console.log('-'.repeat(60));

let totalLocal = 0;
let totalSupa = 0;
let mismatch = 0;

for (const t of tables) {
  let localCount = 0;
  let supaCount = 0;
  let status = '';

  try {
    const lr = await local.query(`SELECT COUNT(*) as c FROM public.${t}`);
    localCount = parseInt(lr.rows[0].c);
  } catch (e) {
    status = 'MISSING LOCAL';
  }

  try {
    const sr = await supa.query(`SELECT COUNT(*) as c FROM public.${t}`);
    supaCount = parseInt(sr.rows[0].c);
  } catch (e) {
    status = status ? 'MISSING BOTH' : 'MISSING SUPABASE';
  }

  if (!status) {
    if (localCount === supaCount) {
      status = 'OK';
    } else {
      status = `DIFF (${localCount - supaCount > 0 ? '+' : ''}${localCount - supaCount})`;
      mismatch++;
    }
  }

  totalLocal += localCount;
  totalSupa += supaCount;

  console.log(
    t.padEnd(25) +
    String(localCount).padEnd(10) +
    String(supaCount).padEnd(10) +
    status
  );
}

console.log('-'.repeat(60));
console.log(
  'TOTAL'.padEnd(25) +
  String(totalLocal).padEnd(10) +
  String(totalSupa).padEnd(10) +
  (mismatch === 0 ? 'ALL SYNCED' : `${mismatch} table(s) out of sync`)
);
console.log('='.repeat(60));

await local.end();
await supa.end();
