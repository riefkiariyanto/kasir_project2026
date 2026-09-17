// Express 4 tidak menangkap promise yang reject dari handler async;
// tanpa ini, error DB (mis. uuid tidak valid) jadi unhandled rejection
// dan mematikan seluruh proses Node, bukan cuma request itu.
module.exports = (fn) => (req, res, next) => fn(req, res, next).catch(next);
