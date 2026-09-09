const { db } = require('../config/database');

const leadController = {
  // GET /api/leads
  async getLeads(req, res) {
    try {
      const filter = {};
      if (req.query.assignedSalespersonId) filter.assigned_salesperson_id = req.query.assignedSalespersonId;
      if (req.query.status) filter.status = req.query.status;

      const leads = await db.getLeads(filter);
      const role = req.user.role;
      let filteredLeads = leads;

      if (role === 'SALES_EXECUTIVE') {
        // Match by user ID, employee_id, or created_by_id
        const myIds = new Set([req.user.id, req.user.employee_id].filter(Boolean));
        filteredLeads = leads.filter(l =>
          myIds.has(l.assigned_salesperson_id) ||
          myIds.has(l.created_by_id)
        );
      } else if (role === 'SALES_MANAGER') {
        // Get all executives under this manager
        const execs = await db.getUsers({ manager_id: req.user.id });

        // Build a Set of ALL valid IDs (user IDs + employee IDs) for manager + their team
        const execIds = new Set();
        execIds.add(req.user.id);
        if (req.user.employee_id) execIds.add(req.user.employee_id);

        for (const exec of execs) {
          if (exec.id) execIds.add(exec.id);
          if (exec.employee_id) execIds.add(exec.employee_id);
        }

        filteredLeads = leads.filter(l =>
          execIds.has(l.assigned_salesperson_id) ||
          execIds.has(l.created_by_id) ||
          // Also show leads where assigned salesperson name matches manager name (fallback)
          (l.created_by && l.created_by === req.user.name)
        );
      }
      // COMPANY_ADMIN sees all leads — no filter applied

      res.status(200).json(filteredLeads);
    } catch (err) {
      console.error('getLeads error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/leads/:id
  async getLeadById(req, res) {
    try {
      const lead = await db.getLeadById(req.params.id);
      if (!lead) {
        return res.status(404).json({ success: false, message: 'Lead not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE') {
        if (lead.assigned_salesperson_id !== req.user.id && lead.created_by_id !== req.user.id) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this lead.' });
        }
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(lead.assigned_salesperson_id) && !execIds.has(lead.created_by_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this lead.' });
        }
      }

      res.status(200).json({ success: true, data: lead });
    } catch (err) {
      console.error('getLeadById error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // POST /api/leads
  async createLead(req, res) {
    try {
      const leadData = req.body;
      if (!leadData.restaurantName && !leadData.restaurant_name) {
        return res.status(400).json({ success: false, message: 'Restaurant name is required' });
      }

      // Always set creator details
      leadData.created_by_id = req.user.id;
      leadData.created_by = req.user.name;

      // Automatically assign to self if Executive and not explicitly assigned
      if (req.user.role === 'SALES_EXECUTIVE') {
        leadData.assigned_salesperson_id = leadData.assigned_salesperson_id || req.user.id;
        leadData.assigned_salesperson = leadData.assigned_salesperson || req.user.name;
      }

      const created = await db.createLead(leadData);
      res.status(201).json({ success: true, message: 'Lead created successfully', data: created });
    } catch (err) {
      console.error('createLead error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // PUT /api/leads/:id
  async updateLead(req, res) {
    try {
      const existingLead = await db.getLeadById(req.params.id);
      if (!existingLead) {
        return res.status(404).json({ success: false, message: 'Lead not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE') {
        if (existingLead.assigned_salesperson_id !== req.user.id && existingLead.created_by_id !== req.user.id) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have permission to modify this lead.' });
        }
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(existingLead.assigned_salesperson_id) && !execIds.has(existingLead.created_by_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have permission to modify this lead.' });
        }
      }

      const updated = await db.updateLead(req.params.id, req.body);
      res.status(200).json({ success: true, message: 'Lead updated successfully', data: updated });
    } catch (err) {
      console.error('updateLead error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  }
};

module.exports = leadController;
