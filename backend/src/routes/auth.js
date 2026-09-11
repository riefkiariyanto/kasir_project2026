const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');

const router = express.Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const { rows } = await pool.query('select * from admins where username = $1', [username]);
  const admin = rows[0];
  if (!admin || !(await bcrypt.compare(password, admin.password_hash))) {
    return res.status(401).json({ error: 'Username atau password salah' });
  }
  req.session.adminId = admin.id;
  // token = raw session id, dikirim balik di body juga (bukan cuma Set-Cookie) supaya
  // client yang tidak bisa baca Set-Cookie (browser JS) tetap bisa kirim ulang via header.
  res.json({ id: admin.id, username: admin.username, token: req.sessionID });
});

router.post('/logout', (req, res) => {
  req.session.destroy(() => res.status(204).end());
});

router.get('/me', (req, res) => {
  if (!req.session.adminId) return res.status(401).json({ error: 'Belum login' });
  res.json({ id: req.session.adminId });
});

router.post('/change-password', async (req, res) => {
  if (!req.session.adminId) return res.status(401).json({ error: 'Belum login' });
  const { currentPassword, newPassword } = req.body;
  const { rows } = await pool.query('select * from admins where id = $1', [req.session.adminId]);
  const admin = rows[0];
  if (!admin || !(await bcrypt.compare(currentPassword, admin.password_hash))) {
    return res.status(401).json({ error: 'Password saat ini salah' });
  }
  const newHash = await bcrypt.hash(newPassword, 10);
  await pool.query('update admins set password_hash = $1 where id = $2', [newHash, admin.id]);
  res.status(204).end();
});

module.exports = router;
