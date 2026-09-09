const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { authenticateToken } = require('../middleware/auth');

router.post('/check-in', authenticateToken, attendanceController.checkIn);
router.post('/check-out', authenticateToken, attendanceController.checkOut);
router.get('/active', authenticateToken, attendanceController.getActive);
router.get('/history', authenticateToken, attendanceController.getHistory);

module.exports = router;
