const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const c = require('../controllers/workshopListController');

// Daftar bengkel untuk pengguna (mencari bengkel & melihat slot)
router.use(auth, authorizeRole('pengguna'));

router.get('/', c.list);
router.get('/:id', c.detail);
router.get('/:id/slots', c.slots);

module.exports = router;
