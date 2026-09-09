const bcrypt = require('bcryptjs');
const { db } = require('../config/database');

// 1. Get All Users (with RBAC isolation & permitted fields)
exports.getUsers = async (req, res) => {
  try {
    const { role } = req.query;
    const filter = {};

    // RBAC Isolation:
    // SUPER_ADMIN sees all users across organizations
    // COMPANY_ADMIN sees all users in their own organization
    // SALES_MANAGER sees executives assigned to them or in their org
    // SALES_EXECUTIVE only sees teammates/manager in their org
    if (req.user && req.user.role !== 'SUPER_ADMIN') {
      filter.organization_id = req.user.organizationId;
    }

    if (role) {
      filter.role = role;
    }

    let users = await db.getUsers(filter);

    // Enforce role-based team visibility containment
    if (req.user && req.user.role === 'SALES_EXECUTIVE') {
      const mgrId = req.user.managerId;
      users = users.filter(u => u.id === req.user.id || (mgrId && (u.id === mgrId || u.manager_id === mgrId)));
    } else if (req.user && req.user.role === 'SALES_MANAGER') {
      users = users.filter(u => u.id === req.user.id || u.manager_id === req.user.id || u.registered_by_user_id === req.user.id);
    }

    // Return complete permitted fields
    const safeUsers = users.map(u => ({
      id: u.id,
      organization_id: u.organization_id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      status: u.status || 'ACTIVE',
      manager_id: u.manager_id,
      employee_id: u.employee_id || 'EMP001',
      date_of_joining: u.date_of_joining || '2024-01-01',
      date_of_birth: u.date_of_birth || null,
      designation: u.designation || (u.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive'),
      profile_photo: u.profile_photo || '',
      territory: u.territory || 'Ahmedabad North',
      city: u.city || 'Ahmedabad',
      visits_target: u.visits_target || 8,
      registered_by_user_id: u.registered_by_user_id || null,
      added_by: u.added_by || 'Not Available',
      addedBy: u.added_by || 'Not Available',
      created_at: u.created_at
    }));

    return res.status(200).json({
      success: true,
      data: safeUsers
    });
  } catch (error) {
    console.error('getUsers error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve users.'
    });
  }
};

// 2. Get Authenticated User Profile with Populated Assigned Manager
exports.getMyProfile = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }

    const userWithManager = await db.getUserWithManager(userId);
    if (!userWithManager) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const isAdmin = userWithManager.role === 'SUPER_ADMIN' || userWithManager.role === 'COMPANY_ADMIN';
    const isManager = userWithManager.role === 'SALES_MANAGER';

    const safeProfile = {
      id: userWithManager.id,
      name: userWithManager.name,
      email: userWithManager.email,
      phone: userWithManager.phone,
      role: userWithManager.role,
      status: userWithManager.status || 'ACTIVE',
      employee_id: isAdmin ? '' : (userWithManager.employee_id || (isManager ? 'EMP001' : 'EMP006')),
      date_of_joining: userWithManager.date_of_joining || '2024-03-15',
      date_of_birth: userWithManager.date_of_birth || null,
      designation: userWithManager.designation || (isAdmin ? 'Company Administrator' : (isManager ? 'Regional Sales Manager' : 'Sales Executive')),
      profile_photo: userWithManager.profile_photo || '',
      territory: userWithManager.territory || (isAdmin ? 'Gujarat Headquarters' : (isManager ? 'Gujarat Region Command' : 'Ahmedabad North')),
      city: userWithManager.city || 'Ahmedabad',
      organization_id: userWithManager.organization_id,
      manager_id: isAdmin ? null : userWithManager.manager_id,
      assigned_manager: isAdmin ? null : (userWithManager.assigned_manager || null),
      registered_by_user_id: userWithManager.registered_by_user_id || null,
      added_by: userWithManager.added_by || 'Not Available',
      addedBy: userWithManager.added_by || 'Not Available',
      created_at: userWithManager.created_at
    };

    return res.status(200).json({
      success: true,
      data: safeProfile
    });
  } catch (error) {
    console.error('getMyProfile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve user profile.'
    });
  }
};

// 3. Update User Date of Birth (DOB)
exports.updateDob = async (req, res) => {
  try {
    const userId = req.user ? req.user.id : req.body.userId;
    const { dob } = req.body;

    if (!userId || !dob) {
      return res.status(400).json({ success: false, message: 'User ID and Date of Birth are required.' });
    }

    const updatedUser = await db.updateUserDob(userId, String(dob).trim());
    if (!updatedUser) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.status(200).json({
      success: true,
      message: 'Date of Birth updated successfully in PostgreSQL.',
      data: {
        id: updatedUser.id,
        date_of_birth: updatedUser.date_of_birth
      }
    });
  } catch (error) {
    console.error('updateDob error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to update Date of Birth.'
    });
  }
};

// 3b. Update Full User Profile (Real Database Persistence)
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.body.userId || req.body.id || (req.user ? req.user.id : null) || req.params.id || req.query.userId;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }

    const {
      name,
      email,
      phone,
      date_of_birth,
      dateOfBirth,
      dob,
      date_of_joining,
      dateOfJoining,
      designation,
      territory,
      city,
      state,
      address,
      pincode,
      emergency_contact_name,
      emergencyContactName,
      emergency_contact_phone,
      emergencyContactPhone,
      emergency_contact_relationship,
      emergencyContactRelationship,
      profile_photo,
      profilePhoto,
      status
    } = req.body;

    const updates = {};
    if (name) updates.name = String(name).trim();
    if (email) updates.email = String(email).trim().toLowerCase();
    if (phone) updates.phone = String(phone).trim();
    if (date_of_birth || dateOfBirth || dob) updates.date_of_birth = String(date_of_birth || dateOfBirth || dob).trim();
    if (date_of_joining || dateOfJoining) updates.date_of_joining = String(date_of_joining || dateOfJoining).trim();
    if (designation) updates.designation = String(designation).trim();
    if (territory) updates.territory = String(territory).trim();
    if (city) updates.city = String(city).trim();
    if (state) updates.state = String(state).trim();
    if (address) updates.address = String(address).trim();
    if (pincode) updates.pincode = String(pincode).trim();
    if (emergency_contact_name || emergencyContactName) updates.emergency_contact_name = String(emergency_contact_name || emergencyContactName).trim();
    if (emergency_contact_phone || emergencyContactPhone) updates.emergency_contact_phone = String(emergency_contact_phone || emergencyContactPhone).trim();
    if (emergency_contact_relationship || emergencyContactRelationship) updates.emergency_contact_relationship = String(emergency_contact_relationship || emergencyContactRelationship).trim();
    if (profile_photo !== undefined || profilePhoto !== undefined) updates.profile_photo = String(profile_photo || profilePhoto || '').trim();
    if (status) updates.status = String(status).trim().toUpperCase();

    const updatedUser = await db.updateUser(userId, updates);
    if (!updatedUser) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const userWithManager = await db.getUserWithManager(updatedUser.id || userId);

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully.',
      data: userWithManager || updatedUser
    });
  } catch (error) {
    console.error('updateProfile error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to update profile in database.'
    });
  }
};

// 4. Get Team of Sales Executives for a Sales Manager
exports.getMyTeam = async (req, res) => {
  try {
    const managerId = (req.query.managerId || req.query.manager_id) || (req.user ? req.user.id : null);
    const callerRole = (req.user && req.user.role) ? req.user.role : (req.query.role || 'SALES_MANAGER');
    const isSuperOrCompanyAdmin = callerRole === 'SUPER_ADMIN' || callerRole === 'COMPANY_ADMIN' || (req.user && req.user.name && req.user.name.toLowerCase().includes('admin'));

    const filter = { role: 'SALES_EXECUTIVE' };
    if (!isSuperOrCompanyAdmin && managerId) {
      filter.manager_id = managerId;
    }

    const team = await db.getUsers(filter);
    const allLeads = await db.getLeads();

    const todayStr = new Date().toISOString().split('T')[0];

    const safeTeam = await Promise.all(team.map(async u => {
      const userLeads = (allLeads || []).filter(l => l.assigned_salesperson_id === u.id || l.created_by_id === u.id);
      const closedDeals = userLeads.filter(l => l.status === 'Won' || l.status === 'CLOSED_WON');
      const activeLeads = userLeads.filter(l => l.status !== 'Won' && l.status !== 'Lost' && l.status !== 'CLOSED_WON' && l.status !== 'CLOSED_LOST');
      
      const visitsToday = u.visits_today || (userLeads.filter(l => (l.created_at || '').startsWith(todayStr)).length);
      const visitsTarget = parseInt(u.visits_target, 10) || 8;
      const isActive = (u.status || 'ACTIVE').toUpperCase() === 'ACTIVE';
      const isOnField = isActive && (visitsToday > 0 || u.current_status === 'On Visit' || u.current_status === 'Traveling');

      // Resolve manager name dynamically
      let managerName = 'Not Assigned';
      if (u.manager_id) {
        const mgr = await db.getUserById(u.manager_id);
        if (mgr) managerName = mgr.name;
      }

      return {
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: u.role,
        status: u.status || 'ACTIVE',
        employee_id: u.employee_id,
        date_of_joining: u.date_of_joining || todayStr,
        date_of_birth: u.date_of_birth || null,
        designation: u.designation || 'Sales Executive',
        profile_photo: u.profile_photo || '',
        territory: u.territory || 'Ahmedabad',
        city: u.city || 'Ahmedabad',
        visits_target: visitsTarget,
        visits_today: visitsToday,
        active_leads_count: activeLeads.length,
        closed_deals_count: closedDeals.length,
        total_revenue_generated: closedDeals.reduce((sum, l) => sum + (parseFloat(l.estimated_deal_value) || 25000), 0),
        current_status: isOnField ? 'On Visit' : (isActive ? 'Active' : 'Inactive'),
        battery_percent: u.battery_percent || 95,
        live_location: `${u.territory || 'Ahmedabad'}, ${u.city || 'Ahmedabad'}`,
        registered_by_user_id: u.registered_by_user_id || null,
        registeredByUserId: u.registered_by_user_id || null,
        added_by: u.added_by || 'Not Available',
        addedBy: u.added_by || 'Not Available',
        manager_id: u.manager_id,
        assigned_manager: managerName
      };
    }));

    return res.status(200).json({
      success: true,
      data: safeTeam
    });
  } catch (error) {
    console.error('getMyTeam error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve team members.'
    });
  }
};

// 4b. Delete User
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }
    await db.deleteUser(id);
    return res.status(200).json({
      success: true,
      message: 'User deleted successfully from database.'
    });
  } catch (error) {
    console.error('deleteUser error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to delete user.'
    });
  }
};

// 5. Get User by ID
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;
    const userWithManager = await db.getUserWithManager(id);
    if (!userWithManager) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.status(200).json({
      success: true,
      data: {
        id: userWithManager.id,
        name: userWithManager.name,
        email: userWithManager.email,
        phone: userWithManager.phone,
        role: userWithManager.role,
        status: userWithManager.status || 'ACTIVE',
        employee_id: userWithManager.employee_id,
        date_of_joining: userWithManager.date_of_joining,
        date_of_birth: userWithManager.date_of_birth,
        designation: userWithManager.designation,
        profile_photo: userWithManager.profile_photo || '',
        territory: userWithManager.territory,
        city: userWithManager.city,
        visits_target: userWithManager.visits_target,
        assigned_manager: userWithManager.assigned_manager,
        registered_by_user_id: userWithManager.registered_by_user_id || null,
        added_by: userWithManager.added_by || 'Not Available',
        addedBy: userWithManager.added_by || 'Not Available'
      }
    });
  } catch (error) {
    console.error('getUserById error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve user.' });
  }
};

// 5b. Get Available Territories / Areas from Database
exports.getTerritories = async (req, res) => {
  try {
    const territories = await db.getAvailableTerritories();
    return res.status(200).json({
      success: true,
      data: territories
    });
  } catch (error) {
    console.error('getTerritories error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve territories.'
    });
  }
};

// 6. Create / Register New User with Automatic Sequential EMP ID
exports.createUser = async (req, res) => {
  try {
    let { name, email, phone, password, role, managerId, organizationId, territory, city, visitsTarget, designation } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Full name is required.' });
    }

    if (!email || !email.trim()) {
      return res.status(400).json({ success: false, message: 'Work email is required.' });
    }

    if (!phone || !phone.trim()) {
      return res.status(400).json({ success: false, message: 'Mobile number is required.' });
    }

    const cleanPhone = phone.trim().replace(/[^0-9]/g, '');
    if (cleanPhone.length !== 10) {
      return res.status(400).json({ success: false, message: 'Please enter a valid 10-digit mobile number.' });
    }

    const cleanEmail = email.trim().toLowerCase();

    // Check duplicate mobile number in database
    const existingPhone = await db.identifyUserByPhoneFast(cleanPhone) || await db.findUserByEmailOrPhone(cleanPhone);
    if (existingPhone) {
      return res.status(409).json({
        success: false,
        message: 'This mobile number already exists. Please use a different number.'
      });
    }

    // Check duplicate email in database
    const existingEmail = await db.findUserByEmailOrPhone(cleanEmail);
    if (existingEmail) {
      return res.status(409).json({
        success: false,
        message: 'This email address is already registered.'
      });
    }

    // Resolve Role & Designation
    if (designation) {
      if (designation.toLowerCase().includes('manager')) {
        role = 'SALES_MANAGER';
        designation = 'Sales Manager';
      } else {
        role = 'SALES_EXECUTIVE';
        designation = 'Sales Executive';
      }
    } else if (role) {
      if (role === 'SALES_MANAGER') {
        designation = 'Sales Manager';
      } else {
        role = 'SALES_EXECUTIVE';
        designation = 'Sales Executive';
      }
    } else {
      role = 'SALES_EXECUTIVE';
      designation = 'Sales Executive';
    }

    // Role-Based Registration Permissions:
    // Admin can register Sales Manager and Sales Executive
    // Sales Manager can ONLY register Sales Executive
    // Sales Executive cannot register users
    const callerRole = (req.user && req.user.role) ? req.user.role : 'SUPER_ADMIN';
    const isCallerAdmin = callerRole === 'SUPER_ADMIN' || callerRole === 'COMPANY_ADMIN' || callerRole.includes('ADMIN');
    const isCallerManager = callerRole === 'SALES_MANAGER';

    if (!isCallerAdmin && !isCallerManager) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You do not have permission to register new users.'
      });
    }

    if (isCallerManager && role === 'SALES_MANAGER') {
      return res.status(403).json({
        success: false,
        message: 'Sales Managers are only permitted to register Sales Executives.'
      });
    }

    // Determine Organization & Sequential Employee ID
    let targetOrgId = (req.user && req.user.organizationId) || organizationId || 'org_demo_001';
    const employeeId = await db.generateNextEmployeeId();
    const dateOfJoining = new Date().toISOString().split('T')[0];
    
    // Determine creator ID dynamically from token/session
    const creatorId = (req.user && req.user.id) ? req.user.id : (managerId || 'usr_companyadmin_002');
    const creatorUser = await db.getUserById(creatorId);
    
    let addedByName = 'Not Available';
    if (creatorUser && creatorUser.name) {
      const isCreatorAdmin = creatorUser.role === 'SUPER_ADMIN' || creatorUser.role === 'COMPANY_ADMIN' || creatorUser.name.toLowerCase().includes('admin');
      if (isCreatorAdmin) {
        addedByName = 'LiveRestro Admin - LiveRestro Admin';
      } else {
        let desig = creatorUser.designation && creatorUser.designation.trim() ? creatorUser.designation.trim() : (creatorUser.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
        if (desig.toLowerCase().includes('manager')) {
          desig = 'Sales Manager';
        }
        let cleanName = creatorUser.name.trim();
        if (cleanName === 'Sales Manager Demo') {
          cleanName = 'Prince Chandarana';
        }
        addedByName = `${desig} - ${cleanName}`;
      }
    } else if (creatorId === 'usr_superadmin_001' || creatorId === 'usr_companyadmin_002' || creatorId.includes('admin')) {
      addedByName = 'LiveRestro Admin - LiveRestro Admin';
    }

    // Internal secure hash placeholder for password (users authenticate via TOTP & PIN on first login)
    const effectivePassword = password || `LiveRestro@${cleanPhone}`;
    const passwordHash = await bcrypt.hash(effectivePassword, 10);
    const userId = `usr_${role.toLowerCase()}_${Date.now()}`;

    const newUser = await db.createUser({
      id: userId,
      organization_id: targetOrgId,
      name: name.trim(),
      email: cleanEmail,
      phone: cleanPhone,
      password_hash: passwordHash,
      role: role,
      manager_id: role === 'SALES_MANAGER' ? null : (req.user && req.user.role === 'SALES_MANAGER' ? req.user.id : managerId || 'usr_companyadmin_002'),
      employee_id: employeeId,
      date_of_joining: dateOfJoining,
      date_of_birth: null,
      designation: designation,
      profile_photo: req.body.profile_photo || req.body.profilePhoto || '',
      status: 'ACTIVE',
      territory: territory || 'Ahmedabad North (Gota & Jagatpur)',
      city: city || 'Ahmedabad',
      visits_target: visitsTarget ? parseInt(visitsTarget, 10) : 8,
      registered_by_user_id: creatorId
    });

    try {
      const performedById = (req.user && req.user.id) ? req.user.id : newUser.id;
      await db.logAction('CREATE_USER', 'USER', `Created ${designation} user: ${name} (${employeeId}) by ${addedByName}`, performedById, targetOrgId, req.ip);
    } catch (_) {}

    return res.status(201).json({
      success: true,
      message: 'User added successfully',
      data: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email,
        phone: newUser.phone,
        role: newUser.role,
        employeeId: newUser.employee_id,
        employee_id: newUser.employee_id,
        dateOfJoining: newUser.date_of_joining,
        date_of_joining: newUser.date_of_joining,
        designation: newUser.designation,
        organizationId: newUser.organization_id,
        managerId: newUser.manager_id,
        territory: newUser.territory,
        city: newUser.city,
        visitsTarget: newUser.visits_target,
        visits_target: newUser.visits_target,
        registered_by_user_id: creatorId,
        registeredByUserId: creatorId,
        added_by: addedByName,
        addedBy: addedByName
      }
    });
  } catch (error) {
    console.error('createUser error:', error);
    if (error.code === '23505') {
      if (error.detail && error.detail.includes('phone')) {
        return res.status(409).json({
          success: false,
          message: 'This mobile number already exists. Please use a different number.'
        });
      }
      if (error.detail && error.detail.includes('email')) {
        return res.status(409).json({
          success: false,
          message: 'This email address is already registered.'
        });
      }
      return res.status(409).json({
        success: false,
        message: 'A user with this email, phone number, or employee ID already exists.'
      });
    }
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to create user in database.'
    });
  }
};

// 7. Get Assignable Users with Live Workload & Availability Badges (for Admin & Sales Manager)
exports.getAssignableUsers = async (req, res) => {
  try {
    const callerRole = req.user ? req.user.role : 'SUPER_ADMIN';
    const callerId = req.user ? req.user.id : null;
    const orgId = req.user ? req.user.organizationId : null;

    const allUsers = await db.getUsers(orgId && callerRole !== 'SUPER_ADMIN' ? { organization_id: orgId } : {});
    const allTasks = await db.getTasks(orgId && callerRole !== 'SUPER_ADMIN' ? { organization_id: orgId } : {});

    // Active tasks: PENDING or IN_PROGRESS
    const activeTasks = allTasks.filter(t => t.status === 'PENDING' || t.status === 'IN_PROGRESS' || t.status === 'ASSIGNED');

    const enrichUser = (u) => {
      const userActiveTasks = activeTasks.filter(t => t.assigned_to_id === u.id);
      const isAvailable = userActiveTasks.length === 0;
      let currentActivity = null;

      if (!isAvailable) {
        const topTask = userActiveTasks[0];
        const typeMap = {
          DEMO: 'Demo',
          SETUP: 'Setup',
          SOFTWARE_SETUP: 'Setup',
          TRAINING: 'Training',
          RESTAURANT_VISIT: 'Visit',
          KYC_DOCUMENTATION: 'KYC',
          FOLLOW_UP: 'Follow-up'
        };
        const actName = typeMap[String(topTask.task_type).toUpperCase()] || topTask.task_type || 'Activity';
        if (topTask.restaurant_name && topTask.restaurant_name.trim().length > 0) {
          currentActivity = `${topTask.restaurant_name} — ${actName}`;
        } else {
          currentActivity = topTask.title || actName;
        }
      }

      return {
        id: u.id,
        name: u.name,
        email: u.email,
        phone: u.phone,
        role: u.role,
        designation: u.designation || (u.role === 'SALES_MANAGER' ? 'Regional Sales Manager' : 'Sales Executive'),
        profile_photo: u.profile_photo || '',
        employee_id: u.employee_id || 'EMP001',
        territory: u.territory || 'Ahmedabad North',
        city: u.city || 'Ahmedabad',
        manager_id: u.manager_id,
        is_available: isAvailable,
        availability: isAvailable ? 'AVAILABLE' : 'ASSIGNED',
        badge_text: isAvailable ? 'Available' : `Assigned: ${currentActivity}`,
        badge_color: isAvailable ? '#10B981' : '#F59E0B',
        active_tasks_count: userActiveTasks.length,
        current_activity: currentActivity,
        active_tasks: userActiveTasks.map(t => ({
          id: t.id,
          title: t.title,
          task_type: t.task_type,
          restaurant_name: t.restaurant_name,
          due_date: t.due_date,
          priority: t.priority
        }))
      };
    };

    let salesManagers = [];
    let salesExecutives = [];

    if (callerRole === 'SUPER_ADMIN' || callerRole === 'COMPANY_ADMIN') {
      // Admins see all Sales Managers and all Sales Executives
      salesManagers = allUsers.filter(u => u.role === 'SALES_MANAGER').map(enrichUser);
      salesExecutives = allUsers.filter(u => u.role === 'SALES_EXECUTIVE').map(enrichUser);
    } else if (callerRole === 'SALES_MANAGER') {
      // Sales Manager only sees Executives assigned to their team
      salesManagers = allUsers.filter(u => u.id === callerId).map(enrichUser);
      salesExecutives = allUsers
        .filter(u => u.role === 'SALES_EXECUTIVE' && u.manager_id === callerId)
        .map(enrichUser);
    } else {
      // Sales Executive sees peers
      salesExecutives = allUsers.filter(u => u.role === 'SALES_EXECUTIVE' && u.organization_id === orgId).map(enrichUser);
    }

    return res.status(200).json({
      success: true,
      data: {
        sales_managers: salesManagers,
        sales_executives: salesExecutives,
        all_assignees: [...salesManagers, ...salesExecutives]
      }
    });
  } catch (error) {
    console.error('getAssignableUsers error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve assignable users.'
    });
  }
};

// 12. Get Sales Leaderboard of Sales Managers
exports.getLeaderboard = async (req, res) => {
  try {
    const timeframe = req.query.timeframe || 'month';
    const leaderboard = await db.getSalesManagerLeaderboard(timeframe);

    return res.status(200).json({
      success: true,
      data: leaderboard
    });
  } catch (error) {
    console.error('getLeaderboard error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to retrieve leaderboard rankings.'
    });
  }
};
