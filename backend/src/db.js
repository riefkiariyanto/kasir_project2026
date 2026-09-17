const { Pool } = require('pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// Koneksi idle yang diputus database memancarkan 'error'; tanpa listener, Node mematikan proses.
pool.on('error', (err) => console.error('pg pool error', err));

module.exports = pool;
