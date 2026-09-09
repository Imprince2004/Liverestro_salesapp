const express = require('express');
const router = express.Router();
const targetController = require('../controllers/targetController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

// Monthly Targets
router.get('/my-target', targetController.getMyTarget);
router.get('/team', targetController.getTeamTargets);
router.post('/assign', targetController.assignTarget);

module.exports = router;
