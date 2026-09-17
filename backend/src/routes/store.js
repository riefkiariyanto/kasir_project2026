const express = require('express');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  const { rows } = await pool.query('select name, address, phone from store_settings where id = 1');
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

module.exports = router;
