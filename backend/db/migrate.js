// Jalankan schema.sql, lalu (opsional, sekali saja) seed.sql + admin/employee bcrypt seed.
// Usage: node db/migrate.js [--seed]
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function seedAuthData(client) {
  const employees = [
    { id: '00000000-0000-0000-0000-000000000201', name: 'Siti Aminah', phone: '081234567890', pin: '123456' },
    { id: '00000000-0000-0000-0000-000000000202', name: 'Budi Santoso', phone: '081298765432', pin: '654321' },
  ];
  for (const e of employees) {
    const pinHash = await bcrypt.hash(e.pin, 10);
    await client.query(
      `insert into employees (id, name, phone, pin_hash) values ($1, $2, $3, $4) on conflict (id) do nothing`,
      [e.id, e.name, e.phone, pinHash]
    );
  }

  const adminUsername = process.env.SEED_ADMIN_USERNAME || 'admin';
  const adminPassword = process.env.SEED_ADMIN_PASSWORD || 'admin';
  const passwordHash = await bcrypt.hash(adminPassword, 10);
  await client.query(
    `insert into admins (username, password_hash) values ($1, $2) on conflict (username) do nothing`,
    [adminUsername, passwordHash]
  );
}

async function main() {
  const client = await pool.connect();
  try {
    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await client.query(schema);
    console.log('schema.sql applied');

    if (process.argv.includes('--seed')) {
      await seedAuthData(client);
      const seed = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
      await client.query(seed);
      console.log('seed.sql + auth seed applied');
    }
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
