const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const c = require('../controllers/serviceController');

// Catatan servis hanya untuk role pengguna
router.use(auth, authorizeRole('pengguna'));

router.get('/', c.list);
router.post('/', c.create);
router.get('/:id', c.detail);
router.put('/:id', c.update);
router.delete('/:id', c.remove);

module.exports = router;
