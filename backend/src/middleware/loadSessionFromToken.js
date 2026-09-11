// Fallback session lookup untuk client yang tidak bisa membaca header Set-Cookie
// (browser JS, cross-origin). Client kirim balik sessionID mentah dari body login
// lewat header X-Session-Token; di sini kita pinjam data admin dari session store
// Postgres yang sama tanpa perlu rekonstruksi cookie/signature.
module.exports = function loadSessionFromToken(req, res, next) {
  const token = req.headers['x-session-token'];
  if (!token || req.session.adminId) {
    return next();
  }
  req.sessionStore.get(token, (err, data) => {
    if (!err && data && data.adminId) {
      req.session.adminId = data.adminId;
    }
    next();
  });
};
