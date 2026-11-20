const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const profile = require('../controllers/workshopController');
const services = require('../controllers/workshopServiceController');

// Semua endpoint di sini hanya untuk role bengkel
router.use(auth, authorizeRole('bengkel'));

router.get('/profile', profile.getProfile);
router.put('/profile', profile.updateProfile);

router.get('/services', services.list);
router.post('/services', services.create);
router.put('/services/:id', services.update);
router.patch('/services/:id/aktif', services.setAktif);
router.delete('/services/:id', services.remove);

module.exports = router;
