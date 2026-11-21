const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const c = require('../controllers/bookingController');

// Booking dari sisi pengguna
router.use(auth, authorizeRole('pengguna'));

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.detail);
router.patch('/:id/cancel', c.cancel);

module.exports = router;
