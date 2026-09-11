const express = require('express');
const multer = require('multer');
const path = require('path');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();
const upload = multer({ dest: process.env.UPLOAD_DIR || './uploads' });

router.get('/', async (req, res) => {
  const { rows } = await pool.query('select * from products order by created_at');
  res.json(rows);
});

router.post('/', requireAdmin, upload.single('image'), async (req, res) => {
  const { name, price, categoryId, tag } = req.body;
  const imagePath = req.file ? path.basename(req.file.path) : null;
  const { rows } = await pool.query(
    'insert into products (name, price, category_id, tag, image_path) values ($1, $2, $3, $4, $5) returning *',
    [name, price, categoryId || null, tag || null, imagePath]
  );
  res.status(201).json(rows[0]);
});

router.put('/:id', requireAdmin, upload.single('image'), async (req, res) => {
  const { name, price, categoryId, tag } = req.body;
  const imagePath = req.file ? path.basename(req.file.path) : req.body.imagePath || null;
  const { rows } = await pool.query(
    'update products set name = $1, price = $2, category_id = $3, tag = $4, image_path = $5 where id = $6 returning *',
    [name, price, categoryId || null, tag || null, imagePath, req.params.id]
  );
  res.json(rows[0]);
});

router.delete('/:id', requireAdmin, async (req, res) => {
  await pool.query('delete from products where id = $1', [req.params.id]);
  res.status(204).end();
});

module.exports = router;
