const express = require('express');
const pool = require('../db');
const requireAdmin = require('../middleware/requireAdmin');

const router = express.Router();

// Ringkasan omzet + breakdown per kategori untuk rentang tanggal
router.get('/summary', requireAdmin, async (req, res) => {
  const { from, to } = req.query;
  const { rows } = await pool.query(
    `select
       coalesce(c.name, 'Tanpa Kategori') as category_name,
       sum(oi.price * oi.quantity)::bigint as category_revenue
     from orders o
     join order_items oi on oi.order_id = o.id
     left join products p on p.id = oi.product_id
     left join categories c on c.id = p.category_id
     where o.created_at::date between $1 and $2
     group by c.name`,
    [from, to]
  );
  const { rows: totals } = await pool.query(
    `select coalesce(sum(total), 0)::bigint as total_revenue, count(*)::bigint as total_orders
     from orders where created_at::date between $1 and $2`,
    [from, to]
  );
  res.json({ ...totals[0], categories: rows });
});

module.exports = router;
