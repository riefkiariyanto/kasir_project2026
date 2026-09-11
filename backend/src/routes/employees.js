const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.post('/verify-pin', async (req, res) => {
  const { pin } = req.body;
  const { rows: employees } = await pool.query('select id, name, pin_hash from employees');
  for (const e of employees) {
    if (await bcrypt.compare(pin || '', e.pin_hash)) {
      return res.json({ id: e.id, name: e.name });
    }
  }
  res.status(401).json({ error: 'PIN salah' });
});

// Public: hanya id+name, dipakai dropdown filter kasir yang belum login admin
router.get('/names', async (req, res) => {
  const { rows } = await pool.query('select id, name from employees order by name');
  res.json(rows);
});

router.get('/', requireAdmin, async (req, res) => {
  const { rows } = await pool.query('select id, name, phone, created_at from employees order by created_at');
  res.json(rows);
});

router.post('/', requireAdmin, async (req, res) => {
  const { name, phone, pin } = req.body;
  const pinHash = await bcrypt.hash(pin, 10);
  const { rows } = await pool.query(
    'insert into employees (name, phone, pin_hash) values ($1, $2, $3) returning id, name, phone, created_at',
    [name, phone || null, pinHash]
  );
  res.status(201).json(rows[0]);
});

router.put('/:id', requireAdmin, async (req, res) => {
  const { name, phone, pin } = req.body;
  if (pin) {
    const pinHash = await bcrypt.hash(pin, 10);
    const { rows } = await pool.query(
      'update employees set name = $1, phone = $2, pin_hash = $3 where id = $4 returning id, name, phone, created_at',
      [name, phone || null, pinHash, req.params.id]
    );
    return res.json(rows[0]);
  }
  const { rows } = await pool.query(
    'update employees set name = $1, phone = $2 where id = $3 returning id, name, phone, created_at',
    [name, phone || null, req.params.id]
  );
  res.json(rows[0]);
});

router.delete('/:id', requireAdmin, async (req, res) => {
  await pool.query('delete from employees where id = $1', [req.params.id]);
  res.status(204).end();
});

module.exports = router;
