const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const c = require('../controllers/vehicleController');

// Semua endpoint kendaraan hanya untuk role pengguna
router.use(auth, authorizeRole('pengguna'));

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.detail);
router.put('/:id', c.update);
router.delete('/:id', c.remove);
router.patch('/:id/odometer', c.updateOdometer);
router.patch('/:id/utama', c.setUtama);

module.exports = router;
