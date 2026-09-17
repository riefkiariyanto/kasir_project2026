const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  // Tanpa batas, request menggantung selamanya saat database tidak bisa dijangkau.
  connectionTimeoutMillis: 10_000,
});

// Koneksi idle yang diputus database memancarkan 'error'; tanpa listener, Node mematikan proses.
pool.on('error', (err) => console.error('pg pool error', err));

module.exports = pool;
