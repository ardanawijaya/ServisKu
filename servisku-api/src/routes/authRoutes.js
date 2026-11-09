const router = require('express').Router();
const auth = require('../middleware/auth');
const c = require('../controllers/authController');

router.post('/register', c.register);
router.post('/login', c.login);
// Logout dilakukan di Flutter dengan menghapus token dari secure storage
router.get('/me', auth, c.me);
router.put('/profile', auth, c.updateProfile);
router.put('/password', auth, c.changePassword);

module.exports = router;
