const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const { authenticateToken, requireRole } = require('../middleware/auth');

router.use(authenticateToken);
router.get('/', taskController.getTasks);
router.post('/check-conflict', taskController.checkConflict);
router.post('/', requireRole('SUPER_ADMIN', 'COMPANY_ADMIN', 'SALES_MANAGER'), taskController.createTask);
router.patch('/:id', taskController.updateTask);

module.exports = router;
