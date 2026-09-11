const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

router.get('/', async (req, res) => {
  const { rows: orders } = await pool.query('select * from orders order by created_at desc');
  const { rows: items } = await pool.query('select * from order_items');
  const itemsByOrder = new Map();
  for (const item of items) {
    if (!itemsByOrder.has(item.order_id)) itemsByOrder.set(item.order_id, []);
    itemsByOrder.get(item.order_id).push(item);
  }
  res.json(orders.map((o) => ({ ...o, items: itemsByOrder.get(o.id) ?? [] })));
});

// Checkout: verifikasi PIN pegawai lalu insert orders+order_items dalam satu transaction (atomic)
router.post('/checkout', async (req, res) => {
  const { items, method, cashierPin } = req.body;
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'items kosong' });
  }
  if (!['qris', 'cash'].includes(method)) {
    return res.status(400).json({ error: 'method tidak valid' });
  }

  const { rows: employees } = await pool.query('select id, name, pin_hash from employees');
  const cashier = await findByPin(employees, cashierPin);
  if (!cashier) {
    return res.status(401).json({ error: 'PIN pegawai tidak valid' });
  }

  const total = items.reduce((sum, i) => sum + i.price * i.quantity, 0);

  const client = await pool.connect();
  try {
    await client.query('begin');
    const { rows } = await client.query(
      'insert into orders (total, method, cashier_id, cashier_name) values ($1, $2, $3, $4) returning *',
      [total, method, cashier.id, cashier.name]
    );
    const order = rows[0];
    for (const item of items) {
      await client.query(
        'insert into order_items (order_id, product_id, product_name, price, quantity) values ($1, $2, $3, $4, $5)',
        [order.id, item.productId || null, item.productName, item.price, item.quantity]
      );
    }
    await client.query('commit');
    res.status(201).json({ ...order, items });
  } catch (err) {
    await client.query('rollback');
    throw err;
  } finally {
    client.release();
  }
});

router.delete('/:id', requireAdmin, async (req, res) => {
  await pool.query('delete from orders where id = $1', [req.params.id]);
  res.status(204).end();
});

async function findByPin(employees, pin) {
  for (const e of employees) {
    if (await bcrypt.compare(pin, e.pin_hash)) return e;
  }
  return null;
}

module.exports = router;
