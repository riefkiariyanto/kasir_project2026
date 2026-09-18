const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  const { rows } = await pool.query(
    'select name, address, phone, print_pin_hash is not null as has_print_pin from store_settings where id = 1'
  );
  res.json(rows[0]);
}));

router.put('/', requireAdmin, asyncHandler(async (req, res) => {
  const { name, address, phone } = req.body;
  const { rows } = await pool.query(
    'update store_settings set name = $1, address = $2, phone = $3, updated_at = now() where id = 1 returning name, address, phone',
    [name, address, phone]
  );
  res.json(rows[0]);
}));

// PIN cetak ulang struk: hanya admin yang boleh mengatur, pin kosong = matikan kunci.
router.put('/print-pin', requireAdmin, asyncHandler(async (req, res) => {
  const pin = String(req.body.pin ?? '').trim();
  if (pin && !/^\d{6}$/.test(pin)) {
    return res.status(400).json({ error: 'PIN harus 6 angka' });
  }
  const hash = pin ? await bcrypt.hash(pin, 10) : null;
  await pool.query('update store_settings set print_pin_hash = $1, updated_at = now() where id = 1', [hash]);
  res.json({ has_print_pin: hash !== null });
}));

router.post('/verify-print-pin', asyncHandler(async (req, res) => {
  const { rows } = await pool.query('select print_pin_hash from store_settings where id = 1');
  const hash = rows[0] && rows[0].print_pin_hash;
  if (!hash) {
    return res.json({ ok: true });
  }
  if (!(await bcrypt.compare(String(req.body.pin ?? ''), hash))) {
    return res.status(401).json({ error: 'PIN cetak salah' });
  }
  res.json({ ok: true });
}));

module.exports = router;
