require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const session = require('express-session');
const pgSession = require('connect-pg-simple')(session);
const pool = require('./db');
const migrate = require('../db/migrate');

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN || '*', credentials: true }));
app.use(express.json());
app.use(
  session({
    store: new pgSession({ pool, tableName: 'session' }),
    secret: process.env.SESSION_SECRET || 'change-me',
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 1000 * 60 * 60 * 24 * 7 },
  })
);
app.use(require('./middleware/loadSessionFromToken'));
app.use('/uploads', express.static(path.resolve(process.env.UPLOAD_DIR || './uploads')));

app.use('/api/auth', require('./routes/auth'));
app.use('/api/store', require('./routes/store'));
app.use('/api/categories', require('./routes/categories'));
app.use('/api/products', require('./routes/products'));
app.use('/api/employees', require('./routes/employees'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/finance', require('./routes/finance'));
app.use('/api/reports', require('./routes/reports'));

app.get('/health', (req, res) => res.json({ ok: true }));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

// Listen dulu supaya healthcheck Railway lolos walau database belum siap, lalu
// migrasi dicoba ulang alih-alih exit (exit = crash-loop sampai batas restart).
async function migrateWithRetry(attempt = 1) {
  try {
    await migrate(pool);
  } catch (err) {
    const delayMs = Math.min(30_000, 2_000 * attempt);
    console.error(`migrasi gagal (percobaan ${attempt}), ulang dalam ${delayMs / 1000}s:`, err.message);
    setTimeout(() => migrateWithRetry(attempt + 1), delayMs);
  }
}

// Error di luar rute (callback library) dicatat saja, jangan matikan server.
process.on('unhandledRejection', (err) => console.error('unhandledRejection', err));

const port = process.env.PORT || 3000;
const server = app.listen(port, () => {
  console.log(`kasir-2026 backend listening on ${port}`);
  migrateWithRetry();
});

// Railway mengirim SIGTERM saat redeploy: selesaikan request yang berjalan dulu.
process.on('SIGTERM', () => {
  server.close(() => pool.end().finally(() => process.exit(0)));
});
