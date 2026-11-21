const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const profile = require('../controllers/workshopController');
const services = require('../controllers/workshopServiceController');
const bookings = require('../controllers/workshopBookingController');

// Semua endpoint di sini hanya untuk role bengkel
router.use(auth, authorizeRole('bengkel'));

router.get('/profile', profile.getProfile);
router.put('/profile', profile.updateProfile);

router.get('/services', services.list);
router.post('/services', services.create);
router.put('/services/:id', services.update);
router.patch('/services/:id/aktif', services.setAktif);
router.delete('/services/:id', services.remove);

router.get('/bookings', bookings.list);
router.patch('/bookings/:id/terima', bookings.terima);
router.patch('/bookings/:id/tolak', bookings.tolak);
router.patch('/bookings/:id/mulai', bookings.mulai);
router.patch('/bookings/:id/selesai', bookings.selesai);

module.exports = router;
