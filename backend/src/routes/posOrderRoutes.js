const express = require('express');
const router = express.Router();
const posOrderController = require('../controllers/posOrderController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/', posOrderController.getPosOrders);
router.get('/:id', posOrderController.getPosOrderById);
router.post('/', posOrderController.createPosOrder);
router.put('/:id', posOrderController.updatePosOrder);
router.get('/:id/post-sale-followup', posOrderController.getPostSaleFollowup);
router.post('/:id/post-sale-followup', posOrderController.savePostSaleFollowup);
router.put('/:id/post-sale-followup', posOrderController.savePostSaleFollowup);
router.get('/verify-gstin/:gstin', posOrderController.verifyGstin);
router.delete('/:id', posOrderController.deletePosOrder);

module.exports = router;
