const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');

router.use('/auth', require('./authRoutes'));
router.use('/vehicles', require('./vehicleRoutes'));
router.use('/services', require('./serviceRoutes'));
router.use('/notifications', require('./notificationRoutes'));
router.use('/workshop', require('./workshopRoutes'));
router.use('/workshops', require('./workshopListRoutes'));
router.use('/bookings', require('./bookingRoutes'));

// Rute contoh untuk menguji pembatasan role (hapus saat fitur asli sudah ada)
router.get('/test/pengguna', auth, authorizeRole('pengguna'), (req, res) =>
  res.json({ success: true, message: 'Halo pengguna' }));
router.get('/test/bengkel', auth, authorizeRole('bengkel'), (req, res) =>
  res.json({ success: true, message: 'Halo bengkel' }));

module.exports = router;
