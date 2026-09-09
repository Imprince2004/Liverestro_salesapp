const express = require('express');
const router = express.Router();
const followUpController = require('../controllers/followUpController');
const { authenticateToken } = require('../middleware/auth');

// All follow-up routes require authentication
router.use(authenticateToken);

// GET /api/follow-ups
router.get('/', followUpController.getFollowUps);

// GET /api/follow-ups/:id
router.get('/:id', followUpController.getFollowUpById);

// POST /api/follow-ups
router.post('/', followUpController.createFollowUp);

// PUT /api/follow-ups/:id
router.put('/:id', followUpController.updateFollowUp);

// DELETE /api/follow-ups/:id
router.delete('/:id', followUpController.deleteFollowUp);

module.exports = router;
