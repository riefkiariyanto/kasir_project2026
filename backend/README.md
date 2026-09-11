# Backend — Kasir 2026 (Railway)

Express + PostgreSQL, deploy ke Railway. Tidak ada dependensi ke `lib/` — app Flutter tidak diubah sama sekali.

**Live:** `https://backend-production-b58c.up.railway.app` — sudah deployed + seeded. Ganti password admin default (`admin`/`admin`) lewat `POST /api/auth/change-password`.

## Struktur

```
backend/
├── db/
│   ├── schema.sql     # semua tabel + trigger invoice_no
│   ├── seed.sql       # data dummy (1:1 dari repository Dart)
│   └── migrate.js      # jalankan schema (+ seed opsional dengan bcrypt)
├── src/
│   ├── db.js           # pg Pool
│   ├── server.js        # entry point Express
│   ├── middleware/requireAdmin.js
│   └── routes/          # auth, store, categories, products, employees, orders, finance, reports
├── uploads/             # foto produk (mount sebagai Railway Volume)
├── railway.json
└── package.json
```

## 1. Setup di Railway

1. Buat project baru di Railway, tambahkan service **PostgreSQL** (dari template) di project yang sama.
2. Tambahkan service baru dari folder `backend/` ini (root directory = `backend`).
3. Set environment variables di service Express (Railway → Variables):
   - `DATABASE_URL` → reference ke `${{Postgres.DATABASE_URL}}`
   - `SESSION_SECRET` → string acak panjang
   - `UPLOAD_DIR` → `/data/uploads` (kalau pakai Volume, lihat langkah 4)
   - `CORS_ORIGIN` → origin app Flutter (atau `*` untuk dev)
   - `SEED_ADMIN_USERNAME` / `SEED_ADMIN_PASSWORD` → kredensial admin awal
4. Tambahkan **Volume** di service Express, mount path `/data/uploads`, lalu set `UPLOAD_DIR=/data/uploads` — supaya foto produk tidak hilang tiap redeploy (disk container Railway ephemeral tanpa Volume).
5. Deploy. `railway.json` sudah set start command `npm run migrate && npm start` — schema otomatis di-apply tiap deploy (idempotent, aman dijalankan berkali-kali karena semua `create table if not exists`).

## 2. Seed data dummy (sekali saja, manual)

Setelah deploy pertama berhasil, jalankan sekali dari lokal (dengan `DATABASE_URL` diarahkan ke Postgres Railway) atau lewat Railway shell:

```
npm run migrate:seed
```

Ini insert 12 produk, 9 kategori, 2 pegawai (PIN di-hash bcrypt), 5 order contoh, dan 1 admin (`SEED_ADMIN_USERNAME`/`SEED_ADMIN_PASSWORD`, default `admin`/`admin` — **ganti password ini setelah seed** lewat `POST /api/auth/change-password`).

## 3. Development lokal

```
cd backend
cp .env.example .env   # isi DATABASE_URL ke Postgres lokal/Railway
npm install
npm run migrate:seed
npm start
```

## 4. API

Semua endpoint di-prefix `/api`. Auth admin pakai **session cookie** (`express-session` + `connect-pg-simple`, session disimpan di tabel `session`) — bukan JWT.

| Method | Path | Auth | Keterangan |
|---|---|---|---|
| POST | `/api/auth/login` | - | `{ username, password }` → set cookie session |
| POST | `/api/auth/logout` | - | hapus session |
| GET | `/api/auth/me` | session | cek status login |
| POST | `/api/auth/change-password` | session | `{ currentPassword, newPassword }` |
| GET | `/api/store` | - | ambil info toko |
| PUT | `/api/store` | admin | update info toko |
| GET | `/api/categories` | - | list kategori |
| POST | `/api/categories` | admin | `{ name, iconKey }` |
| DELETE | `/api/categories/:id` | admin | |
| GET | `/api/products` | - | list produk |
| POST | `/api/products` | admin | multipart: `name, price, categoryId, tag, image` |
| PUT | `/api/products/:id` | admin | multipart, sama seperti POST |
| DELETE | `/api/products/:id` | admin | |
| GET | `/api/employees` | admin | list pegawai |
| POST | `/api/employees` | admin | `{ name, phone, pin }` |
| PUT | `/api/employees/:id` | admin | `{ name, phone, pin? }` |
| DELETE | `/api/employees/:id` | admin | |
| GET | `/api/orders` | - | list order + items |
| POST | `/api/orders/checkout` | - | `{ items: [{productId,productName,price,quantity}], method, cashierPin }` — verifikasi PIN + insert atomic (transaction) |
| DELETE | `/api/orders/:id` | admin | |
| GET | `/api/finance` | - | list catatan kas |
| POST | `/api/finance` | - | `{ employeeId, employeeName, type: 'loan'|'transfer', amount }` |
| GET | `/api/reports/summary?from=YYYY-MM-DD&to=YYYY-MM-DD` | admin | total omzet, jumlah order, breakdown per kategori |

Foto produk dilayani statis di `/uploads/<filename>` (path yang sama disimpan di `products.image_path`).

## 5. Env vars untuk integrasi Flutter (nanti, di luar scope task ini)

- `API_BASE_URL` → URL publik service Railway (domain generate otomatis atau custom domain)
- Request yang butuh admin (`requireAdmin`) harus kirim cookie session — di Flutter pakai `http`/`dio` dengan cookie jar, bukan Bearer token.
