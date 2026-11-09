const { ZodError } = require('zod');

module.exports = function errorHandler(err, req, res, next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      success: false,
      message: 'Validasi gagal',
      errors: err.errors.map((e) => ({ field: e.path.join('.'), message: e.message })),
    });
  }
  console.error(err);
  res.status(err.status || 500).json({
    success: false,
    message: err.status ? err.message : 'Terjadi kesalahan pada server',
  });
};
