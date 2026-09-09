const express = require('express');
const router = express.Router();
const visitController = require('../controllers/visitController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/check-conflict', visitController.checkTerritoryConflict);
router.post('/check-conflict', visitController.checkTerritoryConflict);
router.get('/', visitController.getVisits);
router.get('/:id', visitController.getVisitById);
router.post('/', visitController.createVisit);

module.exports = router;
