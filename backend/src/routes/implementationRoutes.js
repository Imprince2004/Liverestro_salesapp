const express = require('express');
const router = express.Router();
const targetController = require('../controllers/targetController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

// Lead Implementation Process & Tasks
router.get('/my-tasks', targetController.getMyImplementationTasks);
router.get('/all', targetController.getAllImplementations);
router.post('/create', targetController.createImplementation);
router.put('/:id/assign-stage', targetController.assignStage);
router.put('/:id/update-stage-status', targetController.updateStageStatus);

module.exports = router;
