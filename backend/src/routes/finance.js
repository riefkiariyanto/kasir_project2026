const express = require('express');
const pool = require('../db');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.get('/', asyncHandler(async (req, res) => {
  const { rows } = await pool.query('select * from finance_entries order by created_at desc');
  res.json(rows);
}));

router.post('/', asyncHandler(async (req, res) => {
  const { employeeId, employeeName, type, amount } = req.body;
  if (!['loan', 'transfer'].includes(type)) {
    return res.status(400).json({ error: 'type tidak valid' });
  }
  const { rows } = await pool.query(
    'insert into finance_entries (employee_id, employee_name, type, amount) values ($1, $2, $3, $4) returning *',
    [employeeId || null, employeeName, type, amount]
  );
  res.status(201).json(rows[0]);
}));

module.exports = router;
