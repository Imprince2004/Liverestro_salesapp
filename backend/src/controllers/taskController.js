const { db } = require('../config/database');

exports.getTasks = async (req, res) => {
  try {
    const { status, assigned_to_id } = req.query;
    const filter = {};

    // RBAC Task Access Rules:
    // SUPER_ADMIN: Can view all tasks in system
    // COMPANY_ADMIN: Can view all tasks in organization
    // SALES_MANAGER: Can view all tasks in organization or assigned by them
    // SALES_EXECUTIVE: Can only view tasks assigned to them
    if (req.user.role !== 'SUPER_ADMIN') {
      filter.organization_id = req.user.organizationId;
    }

    if (req.user.role === 'SALES_EXECUTIVE') {
      filter.assigned_to_id = req.user.id;
    } else if (assigned_to_id) {
      filter.assigned_to_id = assigned_to_id;
    }

    if (status) {
      filter.status = status;
    }

    const tasks = await db.getTasks(filter);

    // Enrich with assignee and manager names
    const allUsers = await db.getUsers({ organization_id: req.user.organizationId });
    const userMap = {};
    allUsers.forEach(u => { userMap[u.id] = u.name; });

    const enriched = tasks.map(t => ({
      ...t,
      assigned_to_name: userMap[t.assigned_to_id] || 'Sales Executive',
      manager_name: userMap[t.manager_id] || 'Sales Manager'
    }));

    let filteredTasks = enriched;
    if (req.user.role === 'SALES_EXECUTIVE') {
      filteredTasks = enriched.filter(t => t.assigned_to_id === req.user.id);
    } else if (req.user.role === 'SALES_MANAGER') {
      const execs = await db.getUsers({ manager_id: req.user.id });
      const execIds = new Set(execs.map(e => e.id));
      execIds.add(req.user.id);
      filteredTasks = enriched.filter(t => execIds.has(t.assigned_to_id) || t.manager_id === req.user.id);
    }

    return res.status(200).json({
      success: true,
      data: filteredTasks
    });
  } catch (error) {
    console.error('getTasks error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve tasks.'
    });
  }
};

exports.createTask = async (req, res) => {
  try {
    const {
      assigned_to_id,
      assigned_to_ids,
      title,
      description,
      task_type,
      priority,
      restaurant_name,
      lead_id,
      leadId,
      location,
      latitude,
      longitude,
      due_date,
      notes,
      reassign
    } = req.body;

    if (req.user && req.user.role === 'SALES_EXECUTIVE') {
      return res.status(403).json({
        success: false,
        message: 'Sales Executives are not authorized to assign tasks.'
      });
    }

    const rawAssigneeIds = Array.isArray(assigned_to_ids) && assigned_to_ids.length > 0
      ? assigned_to_ids
      : (assigned_to_id ? [assigned_to_id] : []);

    const effectiveTaskType = (task_type || 'DEMO').toUpperCase();
    const effectivePriority = (priority || 'HIGH').toUpperCase();
    const finalLeadId = lead_id || leadId || '';

    let finalTitle = title;
    if (!finalTitle || finalTitle.trim().length === 0) {
      const typeLabelMap = {
        DEMO: 'Software Demo',
        SETUP: 'Software Setup',
        SOFTWARE_SETUP: 'Software Setup',
        TRAINING: 'Staff Training',
        RESTAURANT_VISIT: 'Visit & Pitch',
        KYC_DOCUMENTATION: 'KYC Collect',
        FOLLOW_UP: 'Follow-up'
      };
      const typeLabel = typeLabelMap[effectiveTaskType] || effectiveTaskType;
      finalTitle = `${typeLabel} at ${restaurant_name || 'Assigned Restaurant'}`;
    }

    if (rawAssigneeIds.length === 0 || !due_date) {
      return res.status(400).json({
        success: false,
        message: 'At least one assignee and target completion date are required.'
      });
    }

    const existingTasks = await db.getTasks({});
    const createdTasks = [];

    for (const targetId of rawAssigneeIds) {
      let assignee = await db.getUserById(targetId) || await db.findUserByEmailOrPhone(targetId);
      if (!assignee) {
        const allUsers = await db.getUsers();
        assignee = allUsers.find(e => e.id === targetId || e.employee_id === targetId);
      }

      const assigneeName = assignee ? assignee.name : 'Team Member';
      const assigneeOrgId = (assignee && assignee.organization_id) || (req.user && req.user.organizationId) || 'org_demo_001';
      const finalAssigneeId = assignee ? assignee.id : targetId;

      // Sequential Implementation Stage Validation
      if (restaurant_name && restaurant_name.trim().length > 0) {
        const implList = await db.getLeadImplementations({});
        const targetImpl = implList.find(i => 
          (finalLeadId && i.lead_id === finalLeadId) ||
          (i.restaurant_name && i.restaurant_name.toLowerCase().trim() === restaurant_name.toLowerCase().trim())
        );

        const demoDone = targetImpl ? (targetImpl.demo_status === 'COMPLETED') : false;
        const setupDone = targetImpl ? (targetImpl.setup_status === 'COMPLETED') : false;

        if ((effectiveTaskType === 'SETUP' || effectiveTaskType === 'SOFTWARE_SETUP') && !demoDone) {
          return res.status(400).json({
            success: false,
            message: `Software Demo is pending for "${restaurant_name}". Please complete the Software Demo stage before assigning Software Setup.`
          });
        }
        if (effectiveTaskType === 'TRAINING' && !setupDone) {
          return res.status(400).json({
            success: false,
            message: `Software Setup & Installation is pending for "${restaurant_name}". Please complete Software Setup before assigning Staff Training.`
          });
        }
      }

      // Duplicate Check
      if (!reassign && restaurant_name && restaurant_name.trim().length > 0) {
        const hasDuplicate = existingTasks.some(t =>
          t.assigned_to_id === finalAssigneeId &&
          (t.status === 'PENDING' || t.status === 'IN_PROGRESS' || t.status === 'ASSIGNED') &&
          t.restaurant_name && t.restaurant_name.toLowerCase().trim() === restaurant_name.toLowerCase().trim() &&
          t.task_type && t.task_type.toUpperCase() === effectiveTaskType
        );
        if (hasDuplicate) {
          return res.status(409).json({
            success: false,
            message: `${assigneeName} is already assigned to this activity for "${restaurant_name}". Duplicate assignment prevented.`,
            duplicate: true
          });
        }
      }

      const taskId = `tsk_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`;

      const newTask = await db.createTask({
        id: taskId,
        organization_id: (req.user && req.user.organizationId) || assigneeOrgId,
        manager_id: (req.user && req.user.id) || 'usr_salesmanager_003',
        assigned_to_id: finalAssigneeId,
        title: finalTitle,
        description: description || '',
        task_type: effectiveTaskType,
        priority: effectivePriority,
        status: 'PENDING',
        restaurant_name: restaurant_name || '',
        lead_id: finalLeadId,
        location: location || '',
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        due_date,
        notes: notes || ''
      });

      // Notification Dispatch
      try {
        const typeLabelMap = {
          DEMO: 'Demo',
          SETUP: 'Setup',
          SOFTWARE_SETUP: 'Software Setup',
          TRAINING: 'Training',
          RESTAURANT_VISIT: 'Restaurant Visit',
          KYC_DOCUMENTATION: 'KYC Documentation',
          FOLLOW_UP: 'Follow-Up'
        };
        const activityLabel = typeLabelMap[effectiveTaskType] || effectiveTaskType;
        const managerName = (req.user && req.user.name) || 'Sales Manager';
        const managerDesignation = (req.user && req.user.designation) || (req.user && req.user.role === 'SUPER_ADMIN' ? 'Administrator' : 'Sales Manager');

        const notifId = `not_${Date.now()}_task_${Math.random().toString(36).substr(2, 4)}`;
        const notifTitle = `New Activity Assigned 📋`;
        const notifBody = `New Activity Assigned\n🏪 Restaurant: ${restaurant_name || 'Assigned Restaurant'}\n🆔 Lead ID: ${finalLeadId || 'N/A'}\n📍 Location: ${location || 'On-site'}\n📋 Activity: ${activityLabel}\n📅 Completion Date: ${due_date}\n👤 Assigned By: ${managerName} — ${managerDesignation}\n\nPlease complete the assigned activity before the target completion date.`;

        if (db.getIsPostgres()) {
          await db.query(
            `INSERT INTO notification_history (id, user_id, title, body, is_read, created_at)
             VALUES ($1, $2, $3, $4, $5, NOW())`,
            [notifId, finalAssigneeId, notifTitle, notifBody, false]
          );
        }
      } catch (_) {}

      createdTasks.push({
        ...newTask,
        assigned_to_name: assigneeName,
        manager_name: (req.user && req.user.name) || 'Sales Manager'
      });
    }

    const performerId = (req.user && req.user.id) || 'usr_admin_001';
    const performerOrgId = (req.user && req.user.organizationId) || 'org_demo_001';
    await db.logAction(
      'CREATE_TASK',
      'TASK',
      `Dispatched activity "${finalTitle}" to ${createdTasks.length} member(s)`,
      performerId,
      performerOrgId,
      req.ip
    );

    return res.status(201).json({
      success: true,
      message: `Activity successfully assigned to ${createdTasks.length} user(s).`,
      data: createdTasks.length === 1 ? createdTasks[0] : createdTasks,
      tasks: createdTasks
    });
  } catch (error) {
    console.error('createTask error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to assign activity in database.'
    });
  }
};

// Check for Task / Schedule Conflicts
exports.checkConflict = async (req, res) => {
  try {
    const { user_id, date, restaurant_name } = req.body;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'User ID is required' });
    }

    const user = await db.getUserById(user_id) || await db.findUserByEmailOrPhone(user_id);
    const targetUserId = user ? user.id : user_id;

    const allTasks = await db.getTasks({ assigned_to_id: targetUserId });
    const activeTasks = allTasks.filter(t => t.status === 'PENDING' || t.status === 'IN_PROGRESS' || t.status === 'ASSIGNED');

    let conflict = null;
    if (date) {
      const sameDate = activeTasks.find(t => {
        const dStr = t.due_date instanceof Date ? t.due_date.toISOString().split('T')[0] : String(t.due_date || '');
        return dStr.startsWith(date);
      });
      if (sameDate) conflict = sameDate;
    }

    if (!conflict && restaurant_name && restaurant_name.trim().length > 0) {
      const sameRest = activeTasks.find(t => t.restaurant_name && t.restaurant_name.trim().toLowerCase() === restaurant_name.trim().toLowerCase());
      if (sameRest) conflict = sameRest;
    }

    return res.status(200).json({
      success: true,
      has_conflict: !!conflict,
      active_count: activeTasks.length,
      user: {
        id: targetUserId,
        name: user ? user.name : 'Team Member',
        designation: user ? user.designation : 'Sales Executive'
      },
      conflict_details: conflict ? {
        id: conflict.id,
        title: conflict.title,
        restaurant_name: conflict.restaurant_name,
        due_date: conflict.due_date,
        task_type: conflict.task_type
      } : null
    });
  } catch (err) {
    console.error('checkConflict error:', err);
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    const existingTask = await db.getTaskById(id);
    if (!existingTask) {
      return res.status(404).json({
        success: false,
        message: 'Task not found.'
      });
    }

    if (req.user && req.user.role === 'SALES_EXECUTIVE' && existingTask.assigned_to_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You are only authorized to update tasks assigned directly to you.'
      });
    }

    if (req.user && req.user.role === 'SALES_MANAGER') {
      const execs = await db.getUsers({ manager_id: req.user.id });
      const execIds = new Set(execs.map(e => e.id));
      execIds.add(req.user.id);
      if (!execIds.has(existingTask.assigned_to_id) && existingTask.manager_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          message: 'You are only authorized to update tasks for your assigned Sales Executives.'
        });
      }
    }

    const updates = {};
    if (status) updates.status = status.toUpperCase();
    if (notes) updates.notes = notes;

    const updated = await db.updateTask(id, updates);
    return res.status(200).json({
      success: true,
      message: 'Task updated successfully.',
      data: updated
    });
  } catch (error) {
    console.error('updateTask error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update task.'
    });
  }
};
