const express = require('express');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  const { rows } = await pool.query('select * from categories order by created_at');
  res.json(rows);
}));

router.post('/', requireAdmin, asyncHandler(async (req, res) => {
  const { name, iconKey } = req.body;
  const { rows } = await pool.query(
    'insert into categories (name, icon_key) values ($1, $2) on conflict (name) do nothing returning *',
    [name, iconKey]
  );
  res.status(201).json(rows[0] ?? null);
}));

router.delete('/:id', requireAdmin, asyncHandler(async (req, res) => {
  await pool.query('delete from categories where id = $1', [req.params.id]);
  res.status(204).end();
}));

module.exports = router;
