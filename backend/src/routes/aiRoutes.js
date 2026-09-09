const express = require('express');
const router = express.Router();
const aiController = require('../controllers/aiController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.post('/copilot', aiController.getAiCopilotResponse);
router.post('/summarize-voice', aiController.summarizeVoiceNote);
router.get('/hardware', aiController.getHardwareCatalog);
router.get('/faqs', aiController.getFaqs);
router.get('/tutorials', aiController.getVideoTutorials);
router.post('/quotation', aiController.saveQuotation);
router.post('/objection-battlecard', aiController.generateObjectionBattlecard);
router.post('/scan-visiting-card', aiController.scanVisitingCard);
router.get('/notifications', aiController.getNotifications);

module.exports = router;
