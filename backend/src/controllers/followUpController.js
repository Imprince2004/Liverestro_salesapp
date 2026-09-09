const { db } = require('../config/database');

const followUpController = {
  // GET /api/follow-ups
  async getFollowUps(req, res) {
    try {
      const user = req.user;
      let targetUserId = req.query.userId || req.query.user_id || (user ? user.id : 'usr_salesexecutive_prince');

      const role = user?.role;
      if (role === 'SALES_EXECUTIVE') {
        targetUserId = user.id;
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(user.id);
        if (!execIds.has(targetUserId)) {
          return res.status(403).json({ success: false, message: 'Access denied. You do not have permission to view this user\'s follow-ups.' });
        }
      }

      const allUserFollowUps = await db.getFollowUps({ user_id: targetUserId });

      const now = new Date();
      const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

      // Real-time calculation of status categories
      let todayCount = 0;
      let upcomingCount = 0;
      let overdueCount = 0;
      let completedCount = 0;

      for (const item of allUserFollowUps) {
        const itemStatus = (item.status || 'PENDING').toUpperCase();
        if (itemStatus === 'COMPLETED') {
          completedCount++;
        } else {
          const itemTime = new Date(item.scheduled_time);
          if (itemTime >= startOfToday && itemTime <= endOfToday) {
            todayCount++;
          } else if (itemTime > endOfToday) {
            upcomingCount++;
          } else if (itemTime < startOfToday) {
            overdueCount++;
          }
        }
      }

      const counts = {
        today: todayCount,
        upcoming: upcomingCount,
        overdue: overdueCount,
        completed: completedCount
      };

      // Filter by requested tab
      const tab = (req.query.tab || req.query.status || 'all').toLowerCase();
      let filtered = allUserFollowUps.filter(item => {
        const itemStatus = (item.status || 'PENDING').toUpperCase();
        const itemTime = new Date(item.scheduled_time);

        if (tab === 'today') {
          return itemStatus !== 'COMPLETED' && itemTime >= startOfToday && itemTime <= endOfToday;
        } else if (tab === 'upcoming') {
          return itemStatus !== 'COMPLETED' && itemTime > endOfToday;
        } else if (tab === 'overdue') {
          return itemStatus !== 'COMPLETED' && itemTime < startOfToday;
        } else if (tab === 'completed') {
          return itemStatus === 'COMPLETED';
        }
        return true;
      });

      // Filter by search query
      const searchQuery = (req.query.search || req.query.q || '').trim().toLowerCase();
      if (searchQuery) {
        filtered = filtered.filter(item => {
          return (item.restaurant_name && item.restaurant_name.toLowerCase().includes(searchQuery)) ||
                 (item.contact_person && item.contact_person.toLowerCase().includes(searchQuery)) ||
                 (item.address && item.address.toLowerCase().includes(searchQuery)) ||
                 (item.follow_up_type && item.follow_up_type.toLowerCase().includes(searchQuery)) ||
                 (item.notes && item.notes.toLowerCase().includes(searchQuery));
        });
      }

      res.status(200).json({
        success: true,
        counts,
        data: filtered
      });
    } catch (err) {
      console.error('getFollowUps error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/follow-ups/:id
  async getFollowUpById(req, res) {
    try {
      const item = await db.getFollowUpById(req.params.id);
      if (!item) {
        return res.status(404).json({ success: false, message: 'Follow-up not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE' && item.user_id !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Access denied to this follow-up record' });
      }

      if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(item.user_id)) {
          return res.status(403).json({ success: false, message: 'Access denied to this follow-up record' });
        }
      }

      res.status(200).json({ success: true, data: item });
    } catch (err) {
      console.error('getFollowUpById error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // POST /api/follow-ups
  async createFollowUp(req, res) {
    try {
      const {
        lead_id,
        leadId,
        restaurant_name,
        restaurantName,
        contact_person,
        contactPerson,
        phone,
        address,
        follow_up_type,
        followUpType,
        type,
        priority,
        status,
        scheduled_time,
        scheduledTime,
        notes
      } = req.body;

      const resName = restaurant_name || restaurantName;
      if (!resName) {
        return res.status(400).json({ success: false, message: 'Restaurant name is required' });
      }

      const assignedUserId = (req.user.role !== 'SALES_EXECUTIVE' && (req.body.user_id || req.body.userId))
        ? (req.body.user_id || req.body.userId)
        : req.user.id;

      if (req.user.role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(assignedUserId)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You can only assign follow-ups to your own Sales Executives.' });
        }
      }

      const created = await db.createFollowUp({
        lead_id: lead_id || leadId || null,
        user_id: assignedUserId,
        restaurant_name: resName,
        contact_person: contact_person || contactPerson || 'Owner',
        phone: phone || '',
        address: address || '',
        follow_up_type: follow_up_type || followUpType || type || 'POS Upgrade & Quotation',
        priority: priority || 'Medium',
        status: status || 'PENDING',
        scheduled_time: scheduled_time || scheduledTime || new Date().toISOString(),
        notes: notes || ''
      });

      res.status(201).json({
        success: true,
        message: 'Follow-up scheduled successfully',
        data: created
      });
    } catch (err) {
      console.error('createFollowUp error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // PUT /api/follow-ups/:id
  async updateFollowUp(req, res) {
    try {
      const existing = await db.getFollowUpById(req.params.id);
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Follow-up not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE' && existing.user_id !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }

      if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(existing.user_id)) {
          return res.status(403).json({ success: false, message: 'Access denied' });
        }
      }

      const updated = await db.updateFollowUp(req.params.id, req.body);
      res.status(200).json({
        success: true,
        message: 'Follow-up updated successfully',
        data: updated
      });
    } catch (err) {
      console.error('updateFollowUp error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // DELETE /api/follow-ups/:id
  async deleteFollowUp(req, res) {
    try {
      const existing = await db.getFollowUpById(req.params.id);
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Follow-up not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE' && existing.user_id !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }

      if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(existing.user_id)) {
          return res.status(403).json({ success: false, message: 'Access denied' });
        }
      }

      await db.deleteFollowUp(req.params.id);
      res.status(200).json({
        success: true,
        message: 'Follow-up deleted successfully'
      });
    } catch (err) {
      console.error('deleteFollowUp error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  }
};

module.exports = followUpController;
