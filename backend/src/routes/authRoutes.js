const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const mfaController = require('../controllers/mfaController');
const { authenticateToken } = require('../middleware/auth');

router.post('/login', authController.login);
router.post('/identify', authController.identifyUser);
router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);
router.post('/totp/setup', mfaController.setupTotp);
router.post('/totp/verify', mfaController.verifyTotp);
router.post('/pin/setup', mfaController.setupPin);
router.post('/pin/verify', mfaController.verifyPin);
router.post('/pin/forgot-request', mfaController.requestPinReset);
router.get('/pin/reset-requests', authenticateToken, mfaController.getPinResetRequests);
router.post('/pin/approve-reset', authenticateToken, mfaController.approvePinReset);
router.post('/pin/reset-complete', mfaController.completePinReset);
router.post('/pin/change', authenticateToken, mfaController.changePin);
router.get('/me', authenticateToken, authController.getMe);

module.exports = router;
