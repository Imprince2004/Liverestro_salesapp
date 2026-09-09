const { db } = require('../config/database');

const visitController = {
  // GET /api/visits
  async getVisits(req, res) {
    try {
      const filter = {};
      if (req.query.executiveId) filter.executive_id = req.query.executiveId;

      const visits = await db.getVisits(filter);
      const role = req.user.role;
      let filteredVisits = visits;

      if (role === 'SALES_EXECUTIVE') {
        filteredVisits = visits.filter(v => v.executive_id === req.user.id);
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        filteredVisits = visits.filter(v => execIds.has(v.executive_id));
      }

      res.status(200).json(filteredVisits);
    } catch (err) {
      console.error('getVisits error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/visits/check-conflict
  async checkTerritoryConflict(req, res) {
    try {
      const restaurantName = (req.query.restaurantName || req.body?.restaurantName || '').trim();
      const currentUserId = req.query.currentUserId || req.body?.currentUserId || req.user?.id || '';

      if (!restaurantName) {
        return res.status(400).json({ success: false, message: 'restaurantName is required' });
      }

      const cleanName = restaurantName.toLowerCase();

      // 1. Check Tasks / Beat Schedule in Database
      const tasks = await db.getTasks();
      const conflictingTask = tasks.find(t => {
        const taskRestName = (t.restaurant_name || t.restaurantName || '').trim().toLowerCase();
        const assignedId = t.assigned_to_id || t.assignedToId;
        const status = (t.status || '').toUpperCase();
        return taskRestName === cleanName && assignedId !== currentUserId && status !== 'COMPLETED' && status !== 'CANCELLED';
      });

      if (conflictingTask) {
        const assignedUser = await db.getUserById(conflictingTask.assigned_to_id || conflictingTask.assignedToId);
        return res.status(200).json({
          success: true,
          hasConflict: true,
          data: {
            restaurantName: conflictingTask.restaurant_name || conflictingTask.restaurantName || restaurantName,
            assignedExecutive: {
              id: assignedUser?.id || conflictingTask.assigned_to_id,
              name: assignedUser?.name || conflictingTask.assigned_to_name || 'Not Assigned',
              employeeId: assignedUser?.employee_id || 'N/A',
              phone: assignedUser?.phone || '',
              territory: assignedUser?.territory || 'Not Available',
            },
            scheduledTime: conflictingTask.due_date ? `Scheduled: ${conflictingTask.due_date}` : 'Today',
            status: conflictingTask.status || 'Scheduled',
            taskTitle: conflictingTask.title || 'LiveRestro POS Pitch',
          }
        });
      }

      // 2. Check Visits in Database
      const visits = await db.getVisits();
      const conflictingVisit = visits.find(v => {
        const vRestName = (v.restaurant_name || v.restaurantName || '').trim().toLowerCase();
        const execId = v.executive_id || v.executiveId;
        return vRestName === cleanName && execId !== currentUserId;
      });

      if (conflictingVisit) {
        const execUser = await db.getUserById(conflictingVisit.executive_id || conflictingVisit.executiveId);
        return res.status(200).json({
          success: true,
          hasConflict: true,
          data: {
            restaurantName: conflictingVisit.restaurant_name || conflictingVisit.restaurantName || restaurantName,
            assignedExecutive: {
              id: execUser?.id || conflictingVisit.executive_id || 'Unknown',
              name: execUser?.name || 'Not Assigned',
              employeeId: execUser?.employee_id || 'N/A',
              phone: execUser?.phone || '',
              territory: execUser?.territory || 'Not Available',
            },
            scheduledTime: conflictingVisit.start_time || 'Recently Checked In',
            status: conflictingVisit.status || 'Active Visit',
            taskTitle: 'Outlet Visit & POS Pitch',
          }
        });
      }

      return res.status(200).json({
        success: true,
        hasConflict: false,
        data: null
      });
    } catch (err) {
      console.error('checkTerritoryConflict error:', err);
      return res.status(500).json({ success: false, message: err.message });
    }
  },

  // GET /api/visits/:id
  async getVisitById(req, res) {
    try {
      const visit = await db.getVisitById(req.params.id);
      if (!visit) {
        return res.status(404).json({ success: false, message: 'Visit not found' });
      }

      const role = req.user.role;
      if (role === 'SALES_EXECUTIVE') {
        if (visit.executive_id !== req.user.id) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this visit.' });
        }
      } else if (role === 'SALES_MANAGER') {
        const execs = await db.getUsers({ manager_id: req.user.id });
        const execIds = new Set(execs.map(e => e.id));
        execIds.add(req.user.id);
        if (!execIds.has(visit.executive_id)) {
          return res.status(403).json({ success: false, message: 'Forbidden. You do not have access to this visit.' });
        }
      }

      res.status(200).json({ success: true, data: visit });
    } catch (err) {
      console.error('getVisitById error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  },

  // POST /api/visits
  async createVisit(req, res) {
    try {
      const visitData = req.body;
      const restName = (visitData.restaurantName || visitData.restaurant_name || '').trim();
      if (!restName) {
        return res.status(400).json({ success: false, message: 'Restaurant name is required' });
      }

      // Automatically bind executive_id to logged in user if executive
      if (req.user.role === 'SALES_EXECUTIVE') {
        visitData.executive_id = req.user.id;
        visitData.executive_name = req.user.name;
      }

      // Backend conflict validation
      const currentUserId = visitData.executive_id || visitData.executiveId || '';
      const tasks = await db.getTasks();
      const conflict = tasks.find(t => {
        const tName = (t.restaurant_name || t.restaurantName || '').trim().toLowerCase();
        const assignedId = t.assigned_to_id || t.assignedToId;
        const status = (t.status || '').toUpperCase();
        return tName === restName.toLowerCase() && assignedId !== currentUserId && status !== 'COMPLETED' && status !== 'CANCELLED';
      });

      if (conflict) {
        const assignedUser = await db.getUserById(conflict.assigned_to_id || conflict.assignedToId);
        return res.status(409).json({
          success: false,
          conflict: true,
          message: `Territory Conflict: ${restName} is already assigned to ${assignedUser?.name || 'another executive'}. Duplicate pitching is blocked.`,
          data: {
            restaurantName: restName,
            assignedExecutiveName: assignedUser?.name || 'Not Assigned',
            status: conflict.status
          }
        });
      }

      // Geofence & Location Distance Calculation (Anti-Fraud Check)
      let isGeoFenceVerified = true;
      let distanceKm = 0.0;

      if (visitData.latitude && visitData.longitude) {
        const repLat = parseFloat(visitData.latitude);
        const repLng = parseFloat(visitData.longitude);

        // Check if matching lead has target coordinates
        const leads = await db.getLeads();
        const targetLead = leads.find(l => {
          const lName = (l.restaurant_name || l.restaurantName || '').trim().toLowerCase();
          return lName === restName.toLowerCase();
        });

        if (targetLead && targetLead.latitude && targetLead.longitude) {
          const targetLat = parseFloat(targetLead.latitude);
          const targetLng = parseFloat(targetLead.longitude);

          // Haversine formula
          const R = 6371; // Earth radius in km
          const dLat = (targetLat - repLat) * (Math.PI / 180);
          const dLng = (targetLng - repLng) * (Math.PI / 180);
          const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(repLat * (Math.PI / 180)) *
              Math.cos(targetLat * (Math.PI / 180)) *
              Math.sin(dLng / 2) *
              Math.sin(dLng / 2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          distanceKm = Math.round(R * c * 100) / 100; // Round to 2 decimals

          // Flag as unverified if distance exceeds 100 meters (0.1 km)
          if (distanceKm > 0.1) {
            isGeoFenceVerified = false;
          }
        }
      }

      visitData.is_geo_fence_verified = isGeoFenceVerified;
      visitData.distance_km = distanceKm;

      const created = await db.createVisit(visitData);
      res.status(201).json({
        success: true,
        message: isGeoFenceVerified ? 'Visit logged and geofence verified on-premise' : `Visit logged (${Math.round(distanceKm * 1000)}m away from target outlet)`,
        data: created,
        geofence: {
          verified: isGeoFenceVerified,
          distanceMeters: Math.round(distanceKm * 1000),
        }
      });
    } catch (err) {
      console.error('createVisit error:', err);
      res.status(500).json({ success: false, message: err.message });
    }
  }
};

module.exports = visitController;
