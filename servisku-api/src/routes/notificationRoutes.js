const router = require('express').Router();
const auth = require('../middleware/auth');
const authorizeRole = require('../middleware/role');
const c = require('../controllers/notificationController');

// Saat ini notifikasi hanya untuk role pengguna
router.use(auth, authorizeRole('pengguna'));

router.get('/', c.list);
router.patch('/read-all', c.markAllRead);
router.patch('/:id/read', c.markRead);

module.exports = router;
