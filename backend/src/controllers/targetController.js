const { db } = require('../config/database');

const targetController = {
  // GET /api/targets/my-target?month=&year=&user_id=
  async getMyTarget(req, res) {
    try {
      let userId = req.query.user_id || req.query.userId || req.user?.id || 'usr_demo';
      const month = req.query.month || (new Date().getMonth() + 1);
      const year = req.query.year || new Date().getFullYear();

      const role = req.user?.role;
      if (role === 'SALES_EXECUTIVE') {
        userId = req.user.id;
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(userId)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this user\'s target.' });
        }
      }

      const target = await db.getMonthlyTarget(userId, month, year);
      return res.status(200).json({
        success: true,
        data: target
      });
    } catch (err) {
      console.error('getMyTarget error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/targets/team?month=&year=
  async getTeamTargets(req, res) {
    try {
      if (req.user?.role === 'SALES_EXECUTIVE') {
        return res.status(403).json({ success: false, message: 'Forbidden. Sales Executives are not authorized to view team targets.' });
      }

      const month = req.query.month || (new Date().getMonth() + 1);
      const year = req.query.year || new Date().getFullYear();
      const orgId = req.user?.organizationId || null;

      const teamTargets = await db.getAllMonthlyTargets(month, year, orgId, req.user);
      return res.status(200).json({
        success: true,
        data: teamTargets
      });
    } catch (err) {
      console.error('getTeamTargets error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // POST /api/targets/assign
  async assignTarget(req, res) {
    try {
      if (req.user?.role === 'SALES_EXECUTIVE') {
        return res.status(403).json({ success: false, message: 'Forbidden. Sales Executives cannot assign targets.' });
      }

      const { user_id, month, year, target_leads, target_visits, target_revenue, notes } = req.body;
      if (!user_id) {
        return res.status(400).json({ success: false, message: 'User ID is required' });
      }

      if (req.user?.role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        if (!execIds.has(user_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You can only assign targets to your own Sales Executives.' });
        }
      }

      const assignedById = req.user?.id || 'usr_manager';
      const assignedByName = req.user?.name || 'Sales Manager';

      const saved = await db.saveMonthlyTarget({
        user_id,
        month: month || (new Date().getMonth() + 1),
        year: year || new Date().getFullYear(),
        target_leads: target_leads || 20,
        target_visits: target_visits || 50,
        target_revenue: target_revenue || 0,
        assigned_by_id: assignedById,
        assigned_by_name: assignedByName,
        notes: notes || '',
        organization_id: req.user?.organizationId || null
      });

      return res.status(200).json({
        success: true,
        message: 'Monthly target saved successfully',
        data: saved
      });
    } catch (err) {
      console.error('assignTarget error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/implementations/my-tasks
  async getMyImplementationTasks(req, res) {
    try {
      const userId = req.user?.id || 'usr_demo';
      const role = req.user?.role || 'SALES_EXECUTIVE';

      const all = await db.getLeadImplementations({ userId, role });
      return res.status(200).json({
        success: true,
        data: all
      });
    } catch (err) {
      console.error('getMyImplementationTasks error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/implementations/all?stage=&status=&search=
  async getAllImplementations(req, res) {
    try {
      const { stage, status, search } = req.query;
      const role = req.user?.role || 'SUPER_ADMIN';
      const userId = req.user?.id || 'usr_manager';

      const list = await db.getLeadImplementations({
        userId,
        role,
        stage: stage || 'ALL',
        status: status || 'ALL',
        search: search || ''
      });

      let filteredList = list;
      if (role === 'SALES_EXECUTIVE') {
        filteredList = list.filter(i =>
          i.lead_owner_id === req.user.id ||
          i.demo_assigned_to_id === req.user.id ||
          i.setup_assigned_to_id === req.user.id ||
          i.training_assigned_to_id === req.user.id
        );
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        filteredList = list.filter(i =>
          execIds.has(i.lead_owner_id) ||
          execIds.has(i.demo_assigned_to_id) ||
          execIds.has(i.setup_assigned_to_id) ||
          execIds.has(i.training_assigned_to_id)
        );
      }

      return res.status(200).json({
        success: true,
        data: filteredList
      });
    } catch (err) {
      console.error('getAllImplementations error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // POST /api/implementations/create
  async createImplementation(req, res) {
    try {
      const data = req.body;
      if (!data.restaurant_name && !data.restaurantName) {
        return res.status(400).json({ success: false, message: 'Restaurant name is required' });
      }

      // Authorize and force scoping for Sales Executives
      if (req.user?.role === 'SALES_EXECUTIVE') {
        data.lead_owner_id = req.user.id;
        data.lead_owner_name = req.user.name;
      }

      const created = await db.createLeadImplementation({
        ...data,
        lead_owner_id: data.lead_owner_id || req.user?.id,
        lead_owner_name: data.lead_owner_name || req.user?.name,
        organization_id: req.user?.organizationId || null
      });

      return res.status(201).json({
        success: true,
        message: 'Implementation pipeline created',
        data: created
      });
    } catch (err) {
      console.error('createImplementation error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // PUT /api/implementations/:id/assign-stage
  async assignStage(req, res) {
    try {
      if (req.user?.role === 'SALES_EXECUTIVE') {
        return res.status(403).json({ success: false, message: 'Forbidden. Sales Executives cannot assign implementation stages.' });
      }

      const { id } = req.params;
      const { stage, assigned_to_id, assigned_to_name, assigned_to_designation, assigned_date, notes } = req.body;

      if (!stage || !assigned_to_id) {
        return res.status(400).json({ success: false, message: 'Stage and assigned person are required' });
      }

      if (req.user?.role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(assigned_to_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You can only assign implementation stages to your own Sales Executives.' });
        }
      }

      let assignee = await db.getUserById(assigned_to_id) || await db.findUserByEmailOrPhone(assigned_to_id);
      if (!assignee) {
        const allUsers = await db.getUsers();
        assignee = allUsers.find(u => u.id === assigned_to_id || u.employee_id === assigned_to_id);
      }

      const finalAssigneeId = assignee ? assignee.id : assigned_to_id;
      const finalName = assignee ? assignee.name : (assigned_to_name || 'Assigned Representative');
      const finalDesignation = assignee ? (assignee.designation || 'Sales Executive') : (assigned_to_designation || 'Sales Executive');

      const existingImpl = await db.getLeadImplementationById(id);
      const restaurantName = existingImpl ? existingImpl.restaurant_name : 'Restaurant Outlet';

      const updates = {};
      const stageKey = stage.toLowerCase();
      const assignedDate = assigned_date || new Date().toISOString().split('T')[0];

      if (stageKey === 'demo') {
        updates.demo_status = 'ASSIGNED';
        updates.demo_assigned_to_id = finalAssigneeId;
        updates.demo_assigned_to_name = finalName;
        updates.demo_assigned_to_designation = finalDesignation;
        updates.demo_assigned_date = assignedDate;
        if (notes) updates.demo_notes = notes;
      } else if (stageKey === 'setup' || stageKey === 'software_setup') {
        updates.setup_status = 'ASSIGNED';
        updates.setup_assigned_to_id = finalAssigneeId;
        updates.setup_assigned_to_name = finalName;
        updates.setup_assigned_to_designation = finalDesignation;
        updates.setup_assigned_date = assignedDate;
        if (notes) updates.setup_notes = notes;
      } else if (stageKey === 'training') {
        updates.training_status = 'ASSIGNED';
        updates.training_assigned_to_id = finalAssigneeId;
        updates.training_assigned_to_name = finalName;
        updates.training_assigned_to_designation = finalDesignation;
        updates.training_assigned_date = assignedDate;
        if (notes) updates.training_notes = notes;
      }

      const updated = await db.updateLeadImplementation(id, updates);

      // Create a synced task in tasks table for the assigned executive
      try {
        const taskId = `tsk_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`;
        await db.createTask({
          id: taskId,
          organization_id: (req.user && req.user.organizationId) || 'org_demo_001',
          manager_id: (req.user && req.user.id) || 'usr_salesmanager_003',
          assigned_to_id: finalAssigneeId,
          title: `${stage.toUpperCase()}: ${restaurantName}`,
          description: notes || `Lead implementation ${stage} stage for ${restaurantName}. Assigned to ${finalName} (${finalDesignation}).`,
          task_type: stageKey === 'demo' ? 'DEMO' : (stageKey.includes('setup') ? 'SOFTWARE_SETUP' : 'TRAINING'),
          priority: 'HIGH',
          status: 'PENDING',
          restaurant_name: restaurantName,
          due_date: assignedDate,
          notes: notes || ''
        });
      } catch (taskErr) {
        console.error('Failed to sync implementation task:', taskErr);
      }

      return res.status(200).json({
        success: true,
        message: `Assigned ${stage} stage to ${finalName} (${finalDesignation}) successfully`,
        data: updated
      });
    } catch (err) {
      console.error('assignStage error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // PUT /api/implementations/:id/update-stage-status
  async updateStageStatus(req, res) {
    try {
      const { id } = req.params;
      const { stage, status, completed_date, notes } = req.body;

      if (!stage || !status) {
        return res.status(400).json({ success: false, message: 'Stage and status are required' });
      }

      const existing = await db.getLeadImplementationById(id);
      if (!existing) {
        return res.status(404).json({ success: false, message: 'Implementation not found' });
      }

      const role = req.user?.role;
      if (role === 'SALES_EXECUTIVE') {
        const stageKey = stage.toLowerCase();
        let isAssigned = false;
        if (stageKey === 'demo' && existing.demo_assigned_to_id === req.user.id) isAssigned = true;
        if ((stageKey === 'setup' || stageKey === 'software_setup') && existing.setup_assigned_to_id === req.user.id) isAssigned = true;
        if (stageKey === 'training' && existing.training_assigned_to_id === req.user.id) isAssigned = true;

        if (!isAssigned && existing.lead_owner_id !== req.user.id) {
          return res.status(403).json({ success: false, message: 'Forbidden. You are not authorized to update this implementation stage.' });
        }
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(existing.lead_owner_id) && 
            !execIds.has(existing.demo_assigned_to_id) && 
            !execIds.has(existing.setup_assigned_to_id) && 
            !execIds.has(existing.training_assigned_to_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this implementation record.' });
        }
      }

      const updates = {};
      const stageKey = stage.toLowerCase();
      const upperStatus = status.toUpperCase();
      const todayDate = completed_date || new Date().toISOString().split('T')[0];

      if (stageKey === 'demo') {
        updates.demo_status = upperStatus;
        if (upperStatus === 'COMPLETED') {
          updates.demo_completed_date = todayDate;
          if (!existing.setup_status || existing.setup_status === 'NOT_STARTED' || existing.setup_status === 'PENDING') {
            updates.setup_status = 'ASSIGNED';
          }
        }
        if (notes) updates.demo_notes = notes;
      } else if (stageKey === 'setup' || stageKey === 'software_setup') {
        updates.setup_status = upperStatus;
        // Sequential Stage Rule: Setting Setup to IN_PROGRESS or COMPLETED auto-completes Demo
        if (upperStatus === 'COMPLETED' || upperStatus === 'IN_PROGRESS') {
          if (existing.demo_status !== 'COMPLETED') {
            updates.demo_status = 'COMPLETED';
            updates.demo_completed_date = existing.demo_completed_date || todayDate;
            if (!existing.demo_notes) updates.demo_notes = 'Software demo completed prior to software installation.';
          }
        }
        if (upperStatus === 'COMPLETED') {
          updates.setup_completed_date = todayDate;
          if (!existing.training_status || existing.training_status === 'NOT_STARTED' || existing.training_status === 'PENDING') {
            updates.training_status = 'ASSIGNED';
          }
        }
        if (notes) updates.setup_notes = notes;
      } else if (stageKey === 'training') {
        updates.training_status = upperStatus;
        // Sequential Stage Rule: Setting Training to IN_PROGRESS or COMPLETED auto-completes Demo and Setup
        if (upperStatus === 'COMPLETED' || upperStatus === 'IN_PROGRESS') {
          if (existing.demo_status !== 'COMPLETED') {
            updates.demo_status = 'COMPLETED';
            updates.demo_completed_date = existing.demo_completed_date || todayDate;
            if (!existing.demo_notes) updates.demo_notes = 'Software demo completed prior to staff training.';
          }
          if (existing.setup_status !== 'COMPLETED') {
            updates.setup_status = 'COMPLETED';
            updates.setup_completed_date = existing.setup_completed_date || todayDate;
            if (!existing.setup_notes) updates.setup_notes = 'Software setup completed prior to staff training.';
          }
        }
        if (upperStatus === 'COMPLETED') {
          updates.training_completed_date = todayDate;
          updates.overall_stage = 'COMPLETED';
          updates.overall_status = 'COMPLETED';

          // Auto-trigger 1-Month Post-Sale Follow-up in database
          try {
            const orders = await db.getPosSoftwareOrders();
            const matchingOrder = orders.find(o => 
              (existing.lead_id && o.lead_id === existing.lead_id) || 
              (o.restaurant_name && o.restaurant_name.toLowerCase() === existing.restaurant_name.toLowerCase())
            );

            if (matchingOrder) {
              const existingReview = await db.getPostSaleFollowupByOrderId(matchingOrder.id);
              if (!existingReview) {
                await db.createPostSaleFollowup({
                  order_id: matchingOrder.id,
                  lead_id: existing.lead_id || matchingOrder.lead_id || '',
                  restaurant_name: existing.restaurant_name || matchingOrder.restaurant_name,
                  executive_id: matchingOrder.assigned_executive_id || req.user.id,
                  executive_name: matchingOrder.assigned_executive_name || req.user.name,
                  manager_id: matchingOrder.assigned_manager_id || '',
                  status: 'PENDING',
                  scheduled_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                });
              }
            }
          } catch (e) {
            console.error('Auto post-sale follow-up schedule error:', e);
          }
        }
        if (notes) updates.training_notes = notes;
      }

      const updated = await db.updateLeadImplementation(id, updates);
      return res.status(200).json({
        success: true,
        message: 'Stage status updated successfully',
        data: updated
      });
    } catch (err) {
      console.error('updateStageStatus error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  }
};

module.exports = targetController;
