const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateToken } = require('../middleware/auth');

// Public / Authenticated user registration
router.post('/', userController.createUser);
router.post('/register', userController.createUser);

// Profile endpoints (with optional or token auth)
router.get('/me', authenticateToken, userController.getMyProfile);
router.put('/me', authenticateToken, userController.updateProfile);
router.patch('/me', authenticateToken, userController.updateProfile);
router.put('/profile', authenticateToken, userController.updateProfile);
router.patch('/profile', authenticateToken, userController.updateProfile);
router.put('/me/dob', authenticateToken, userController.updateDob);
router.patch('/me/dob', authenticateToken, userController.updateDob);
router.put('/dob', authenticateToken, userController.updateDob);

// Team endpoints for Sales Manager
router.get('/team', authenticateToken, userController.getMyTeam);
router.get('/leaderboard', authenticateToken, userController.getLeaderboard);

// Assignable users for Tasks & Leads (Admin & Sales Manager)
router.get('/assignable', authenticateToken, userController.getAssignableUsers);

// Available territories / areas
router.get('/territories', userController.getTerritories);

// Single User by ID
router.get('/:id', userController.getUserById);
router.put('/:id', userController.updateProfile);
router.patch('/:id', userController.updateProfile);
router.delete('/:id', userController.deleteUser);

// All users (filtered by role / org)
router.get('/', userController.getUsers);

module.exports = router;
