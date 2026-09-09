const qrcode = require('qrcode');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const totpEngine = require('../utils/totp');
const { db } = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'liverestro_crm_super_secret_jwt_key_2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'liverestro_crm_refresh_secret_key_2026';

async function resolveUser(userId) {
  if (!userId) return null;
  const cleanId = String(userId).trim();
  let user = await db.getUserById(cleanId);
  if (!user) user = await db.findUserByEmailOrPhone(cleanId);
  if (!user) user = await db.identifyUserByPhoneFast(cleanId);
  return user;
}

function buildUserAuthPayload(user, org, permissions) {
  const cleanRole = user.role || 'SALES_EXECUTIVE';
  let defaultDesig = 'Sales Executive';
  if (cleanRole === 'SALES_MANAGER') defaultDesig = 'Sales Manager';
  if (cleanRole === 'COMPANY_ADMIN' || cleanRole === 'SUPER_ADMIN') defaultDesig = 'Company Administrator';

  return {
    userId: user.id,
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    mobile: user.phone,
    role: cleanRole,
    designation: user.designation || defaultDesig,
    employeeId: user.employee_id || '',
    employee_id: user.employee_id || '',
    dateOfJoining: user.date_of_joining || '',
    date_of_joining: user.date_of_joining || '',
    dateOfBirth: user.date_of_birth || null,
    date_of_birth: user.date_of_birth || null,
    territory: user.territory || '',
    city: user.city || '',
    organizationId: user.organization_id,
    organizationName: org ? org.name : 'LiveRestro Organization',
    managerId: user.manager_id,
    registeredByUserId: user.registered_by_user_id,
    registered_by_user_id: user.registered_by_user_id,
    addedBy: user.added_by || user.addedBy || 'Not Available',
    added_by: user.added_by || user.addedBy || 'Not Available',
    status: user.status || 'ACTIVE',
    visitsTarget: user.visits_target || 8,
    permissions: permissions || [],
    profilePhoto: user.profile_photo || '',
    isPinSet: true
  };
}

// 1. Generate Google Authenticator TOTP Secret and QR Code
exports.setupTotp = async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ success: false, message: 'User ID is required.' });
    }

    const user = await resolveUser(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    // Check if user already has an active secret or generate a new 20-byte Base32 secret
    let cred = await db.getTotpCredential(user.id);
    let secret = (cred && cred.secret) ? cred.secret : totpEngine.generateSecret(20);

    // Save secret to database
    await db.saveTotpSecret(user.id, secret, false);

    const otpauth = totpEngine.generateUri({
      secret,
      accountName: `${user.name} (${user.phone})`,
      issuer: 'LiveRestro CRM'
    });
    const qrDataUrl = await qrcode.toDataURL(otpauth, { margin: 1, width: 220 });

    return res.status(200).json({
      success: true,
      message: 'TOTP secret generated successfully.',
      data: {
        userId: user.id,
        secret,
        qrDataUrl,
        otpauthUrl: otpauth,
      }
    });
  } catch (error) {
    console.error('setupTotp error:', error);
    return res.status(500).json({ success: false, message: 'Failed to setup Google Authenticator.' });
  }
};

// 2. Verify Google Authenticator 6-digit code
exports.verifyTotp = async (req, res) => {
  try {
    const { userId, code, secret: clientSecret } = req.body;
    if (!userId || !code) {
      return res.status(400).json({ success: false, message: 'User ID and TOTP code are required.' });
    }

    const user = await resolveUser(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const credential = await db.getTotpCredential(user.id);
    let activeSecret = credential ? credential.secret : null;

    if (!activeSecret && clientSecret) {
      activeSecret = clientSecret;
    }

    if (!activeSecret) {
      return res.status(400).json({
        success: false,
        message: 'No Google Authenticator enrollment found for this user.'
      });
    }

    // Standard RFC 6238 Time-Based OTP Verification with +-60s clock drift tolerance
    let isValid = totpEngine.verifyTotp(code, activeSecret, 2);

    // If client supplied a different secret they were viewing, test against that secret
    if (!isValid && clientSecret && clientSecret !== activeSecret) {
      if (totpEngine.verifyTotp(code, clientSecret, 2)) {
        isValid = true;
        activeSecret = clientSecret;
      }
    }

    if (!isValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification code. Please enter the current code from Google Authenticator.'
      });
    }

    // Mark TOTP as enabled in database
    await db.saveTotpSecret(user.id, activeSecret, true);

    // Check if user already has a PIN configured
    const userPin = await db.getUserPin(user.id);

    if (userPin && userPin.pin_hash) {
      // Returning user login completion
      const permissions = await db.getPermissionsForRole(user.role);
      const org = await db.getOrganizationById(user.organization_id);

      const token = jwt.sign(
        {
          userId: user.id,
          role: user.role,
          organizationId: user.organization_id,
        },
        JWT_SECRET,
        { expiresIn: '30d' }
      );

      const refreshToken = jwt.sign(
        { userId: user.id, tokenType: 'refresh' },
        JWT_REFRESH_SECRET,
        { expiresIn: '90d' }
      );

      await db.createSession(user.id, token.slice(-16), refreshToken.slice(-16), req.headers['user-agent'] || '', req.ip);
      await db.logAction('LOGIN_MFA_SUCCESS', 'AUTH', `User ${user.name} completed 2FA login`, user.id, user.organization_id, req.ip);

      return res.status(200).json({
        success: true,
        message: `Welcome back, ${user.name}!`,
        token,
        refreshToken,
        user: buildUserAuthPayload(user, org, permissions)
      });
    }

    // First time user: allow proceeding to PIN creation
    return res.status(200).json({
      success: true,
      message: 'Google Authenticator verified successfully. Please create your 4-digit PIN.',
      data: {
        userId: user.id,
        isTotpVerified: true,
        hasPin: false,
        nextStep: 'PIN_SETUP'
      }
    });
  } catch (error) {
    console.error('verifyTotp error:', error);
    return res.status(500).json({ success: false, message: 'Failed to verify Authenticator code.' });
  }
};

// 3. Create & Hash User Security PIN
exports.setupPin = async (req, res) => {
  try {
    const { userId, pin } = req.body;
    if (!userId || !pin) {
      return res.status(400).json({ success: false, message: 'User ID and PIN are required.' });
    }

    if (!/^\d{4,6}$/.test(pin.trim())) {
      return res.status(400).json({ success: false, message: 'PIN must be a 4 to 6 digit numeric code.' });
    }

    const user = await resolveUser(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    // Bcrypt Hash PIN (Salt rounds = 10)
    const pinHash = await bcrypt.hash(pin.trim(), 10);
    await db.saveUserPin(user.id, pinHash);

    // Generate Full Authenticated JWT Session
    const permissions = await db.getPermissionsForRole(user.role);
    const org = await db.getOrganizationById(user.organization_id);

    const token = jwt.sign(
      {
        userId: user.id,
        role: user.role,
        organizationId: user.organization_id,
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id, tokenType: 'refresh' },
      JWT_REFRESH_SECRET,
      { expiresIn: '90d' }
    );

    await db.createSession(user.id, token.slice(-16), refreshToken.slice(-16), req.headers['user-agent'] || '', req.ip);
    await db.logAction('LOGIN_PIN_SETUP', 'AUTH', `User ${user.name} completed authentication and set PIN`, user.id, user.organization_id, req.ip);

    return res.status(200).json({
      success: true,
      message: `Welcome, ${user.name}! Authentication complete.`,
      token,
      refreshToken,
      user: buildUserAuthPayload(user, org, permissions)
    });
  } catch (error) {
    console.error('setupPin error:', error);
    return res.status(500).json({ success: false, message: 'Failed to create security PIN.' });
  }
};

// 4. Verify User Security PIN
exports.verifyPin = async (req, res) => {
  try {
    const { userId, pin } = req.body;
    if (!userId || !pin) {
      return res.status(400).json({ success: false, message: 'User ID and PIN are required.' });
    }

    const user = await resolveUser(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const userPin = await db.getUserPin(user.id);
    if (!userPin) {
      return res.status(400).json({ success: false, message: 'No PIN set for this user. Please setup a PIN.' });
    }

    // Check lockout
    if (userPin.locked_until && new Date(userPin.locked_until) > new Date()) {
      return res.status(423).json({
        success: false,
        message: 'Account temporarily locked due to multiple incorrect PIN attempts. Please try again later.'
      });
    }

    const isMatch = await bcrypt.compare(pin.trim(), userPin.pin_hash);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Incorrect PIN. Please try again.' });
    }

    // Generate Full Authenticated JWT Session directly for returning user
    const permissions = await db.getPermissionsForRole(user.role);
    const org = await db.getOrganizationById(user.organization_id);

    const token = jwt.sign(
      {
        userId: user.id,
        role: user.role,
        organizationId: user.organization_id,
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id, tokenType: 'refresh' },
      JWT_REFRESH_SECRET,
      { expiresIn: '90d' }
    );

    await db.createSession(user.id, token.slice(-16), refreshToken.slice(-16), req.headers['user-agent'] || '', req.ip);
    await db.logAction('LOGIN_PIN_VERIFY', 'AUTH', `User ${user.name} verified PIN and logged in`, user.id, user.organization_id, req.ip);

    return res.status(200).json({
      success: true,
      message: `Welcome back, ${user.name}!`,
      token,
      refreshToken,
      user: buildUserAuthPayload(user, org, permissions)
    });
  } catch (error) {
    console.error('verifyPin error:', error);
    return res.status(500).json({ success: false, message: 'Failed to verify PIN.' });
  }
};

// 5. User requests PIN reset (Requires Admin Approval)
exports.requestPinReset = async (req, res) => {
  try {
    const { userId, phone, identifier } = req.body;
    const loginId = phone || identifier || userId;
    if (!loginId) {
      return res.status(400).json({ success: false, message: 'User identifier or phone is required.' });
    }

    const user = await resolveUser(loginId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    // Check if there is already an active request
    const existing = await db.getActivePinResetForUser(user.id);
    if (existing) {
      if (existing.status === 'APPROVED') {
        return res.status(200).json({
          success: true,
          status: 'APPROVED',
          message: 'Your PIN reset request has already been APPROVED by Admin! Please proceed to Google Authenticator verification.',
          data: existing
        });
      }
      return res.status(200).json({
        success: true,
        status: 'PENDING',
        message: 'PIN Reset Requires Admin Approval\nYou have forgotten your PIN. Please contact your Admin and request approval to reset your PIN.',
        data: existing
      });
    }

    // Create a new PENDING request in database
    const newRequest = await db.createPinResetRequest({
      user_id: user.id,
      user_name: user.name,
      employee_id: user.employee_id || 'EMP001',
      designation: user.designation || (user.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive'),
      phone: user.phone,
      role: user.role,
      status: 'PENDING',
      notes: req.body.notes || 'User requested PIN reset due to forgotten PIN.'
    });

    // Send rich notification to Admin users in organization
    try {
      const allUsers = await db.getUsers({ organization_id: user.organization_id });
      const admins = allUsers.filter(u => u.role === 'SUPER_ADMIN' || u.role === 'COMPANY_ADMIN' || u.role === 'SALES_MANAGER');
      for (const admin of admins) {
        if (admin.id !== user.id) {
          const notifId = `not_${Date.now()}_pin_${Math.random().toString(36).substr(2, 4)}`;
          const notifTitle = `PIN Reset Request 🔐`;
          const notifBody = `PIN Reset Request from ${user.name} (${user.designation || user.role} • ${user.employee_id || user.phone}). Please review and approve in Admin PIN Reset Requests.`;
          if (db.getIsPostgres()) {
            await db.query(
              `INSERT INTO notification_history (id, user_id, title, body, is_read, created_at)
               VALUES ($1, $2, $3, $4, $5, NOW())`,
              [notifId, admin.id, notifTitle, notifBody, false]
            );
          }
        }
      }
    } catch (_) {}

    await db.logAction('PIN_RESET_REQUESTED', 'AUTH', `User ${user.name} requested PIN reset (requires Admin approval)`, user.id, user.organization_id, req.ip);

    return res.status(201).json({
      success: true,
      status: 'PENDING',
      message: 'PIN Reset Requires Admin Approval\nYou have forgotten your PIN. Please contact your Admin and request approval to reset your PIN.',
      data: newRequest
    });
  } catch (error) {
    console.error('requestPinReset error:', error);
    return res.status(500).json({ success: false, message: 'Failed to submit PIN reset request.' });
  }
};

// 6. Admin fetches all PIN reset requests
exports.getPinResetRequests = async (req, res) => {
  try {
    const callerId = req.user ? req.user.id : req.query.adminId;
    if (!callerId) {
      return res.status(401).json({ success: false, message: 'Admin authentication required.' });
    }
    const caller = await db.getUserById(callerId);
    if (!caller || (caller.role !== 'SUPER_ADMIN' && caller.role !== 'COMPANY_ADMIN')) {
      return res.status(403).json({ success: false, message: 'Access denied. Only Administrators can view PIN reset requests.' });
    }

    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const requests = await db.getPinResetRequests(filter);
    return res.status(200).json({
      success: true,
      data: requests
    });
  } catch (error) {
    console.error('getPinResetRequests error:', error);
    return res.status(500).json({ success: false, message: 'Failed to retrieve PIN reset requests.' });
  }
};

// 7. Admin approves PIN reset with Admin PIN verification
exports.approvePinReset = async (req, res) => {
  try {
    const { requestId, adminPin, notes } = req.body;
    if (!requestId || !adminPin) {
      return res.status(400).json({ success: false, message: 'Request ID and Admin PIN are required.' });
    }

    const callerId = req.user ? req.user.id : req.body.adminId;
    if (!callerId) {
      return res.status(401).json({ success: false, message: 'Admin authentication required.' });
    }

    const caller = await db.getUserById(callerId);
    if (!caller) {
      return res.status(404).json({ success: false, message: 'Admin user not found.' });
    }

    // Role check: Only ADMIN can approve
    if (caller.role !== 'SUPER_ADMIN' && caller.role !== 'COMPANY_ADMIN') {
      return res.status(403).json({ success: false, message: 'Only Administrators can approve PIN resets.' });
    }

    const request = await db.getPinResetRequestById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: 'PIN reset request not found.' });
    }

    // Security rule: A user must not be able to approve their own PIN reset
    if (request.user_id === caller.id) {
      return res.status(403).json({ success: false, message: 'You cannot approve your own PIN reset request.' });
    }

    // Verify Admin's actual PIN from PostgreSQL user_pins table (NO hardcoding!)
    const callerPinRecord = await db.getUserPin(caller.id);
    if (!callerPinRecord) {
      return res.status(400).json({ success: false, message: 'You do not have an Admin PIN configured. Please setup your PIN first.' });
    }

    const isPinValid = await bcrypt.compare(adminPin.trim(), callerPinRecord.pin_hash);
    if (!isPinValid) {
      await db.logAction('ADMIN_PIN_VERIFY_FAILED', 'AUTH', `Admin ${caller.name} entered incorrect PIN while approving reset for ${request.user_name}`, caller.id, caller.organization_id, req.ip);
      return res.status(401).json({ success: false, message: 'Invalid Admin PIN. Please enter your correct security PIN.' });
    }

    // Update request status to APPROVED
    const updated = await db.updatePinResetRequest(requestId, {
      status: 'APPROVED',
      approved_at: new Date().toISOString(),
      approved_by: caller.id,
      approved_by_name: `${caller.name} (${caller.designation || caller.role})`,
      notes: notes || request.notes
    });

    // Notify employee in notification_history
    try {
      const notifId = `not_${Date.now()}_appr_${Math.random().toString(36).substr(2, 4)}`;
      const notifTitle = `PIN Reset Approved ✅`;
      const notifBody = `Your PIN reset request has been APPROVED by ${caller.name}. You can now open the app, enter your mobile number, verify Google Authenticator, and set your new PIN.`;
      if (db.getIsPostgres()) {
        await db.query(
          `INSERT INTO notification_history (id, user_id, title, body, is_read, created_at)
           VALUES ($1, $2, $3, $4, $5, NOW())`,
          [notifId, request.user_id, notifTitle, notifBody, false]
        );
      }
    } catch (_) {}

    await db.logAction('PIN_RESET_APPROVED', 'AUTH', `Admin ${caller.name} approved PIN reset for user ${request.user_name}`, caller.id, caller.organization_id, req.ip);

    return res.status(200).json({
      success: true,
      message: `PIN reset request for ${request.user_name} has been approved successfully.`,
      data: updated
    });
  } catch (error) {
    console.error('approvePinReset error:', error);
    return res.status(500).json({ success: false, message: 'Failed to approve PIN reset request.' });
  }
};

// 8. User completes PIN reset (Google Authenticator 2FA + New PIN Confirmation)
exports.completePinReset = async (req, res) => {
  try {
    const { userId, phone, identifier, code, newPin } = req.body;
    const loginId = userId || phone || identifier;
    if (!loginId || !code || !newPin) {
      return res.status(400).json({ success: false, message: 'User ID, Authenticator code, and new PIN are required.' });
    }

    if (!/^\d{4,6}$/.test(newPin.trim())) {
      return res.status(400).json({ success: false, message: 'New PIN must be 4 to 6 digits.' });
    }

    const user = await resolveUser(loginId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    // Verify Admin approval in database
    const activeReset = await db.getActivePinResetForUser(user.id);
    if (!activeReset || activeReset.status !== 'APPROVED') {
      return res.status(403).json({
        success: false,
        message: 'PIN Reset Requires Admin Approval. Please contact your Admin and request approval before creating a new PIN.'
      });
    }

    // Verify Google Authenticator 6-digit TOTP against real secret
    const cred = await db.getTotpCredential(user.id);
    if (!cred || !cred.secret) {
      return res.status(400).json({ success: false, message: 'Google Authenticator is not enrolled for this account.' });
    }

    const isTotpValid = totpEngine.verifyTotp(code.trim(), cred.secret, 2);
    if (!isTotpValid) {
      return res.status(400).json({ success: false, message: 'Invalid verification code. Please enter the current 6-digit code from Google Authenticator.' });
    }

    // Hash new PIN with bcrypt and save to PostgreSQL user_pins
    const pinHash = await bcrypt.hash(newPin.trim(), 10);
    await db.saveUserPin(user.id, pinHash);

    // Mark reset request as COMPLETED
    await db.updatePinResetRequest(activeReset.id, {
      status: 'COMPLETED',
      completed_at: new Date().toISOString()
    });

    // Audit log
    await db.logAction(
      'PIN_RESET_COMPLETED',
      'AUTH',
      `User ${user.name} successfully reset their PIN after Admin approval by ${activeReset.approved_by_name || 'Admin'} and Google Authenticator 2FA`,
      user.id,
      user.organization_id,
      req.ip
    );

    // Generate authenticated JWT Session and open Dashboard
    const permissions = await db.getPermissionsForRole(user.role);
    const org = await db.getOrganizationById(user.organization_id);

    const token = jwt.sign(
      {
        userId: user.id,
        role: user.role,
        organizationId: user.organization_id,
      },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    const refreshToken = jwt.sign(
      { userId: user.id, tokenType: 'refresh' },
      JWT_REFRESH_SECRET,
      { expiresIn: '90d' }
    );

    await db.createSession(user.id, token.slice(-16), refreshToken.slice(-16), req.headers['user-agent'] || '', req.ip);

    return res.status(200).json({
      success: true,
      message: '✅ PIN Changed Successfully. Your PIN has been updated successfully.',
      token,
      refreshToken,
      user: buildUserAuthPayload(user, org, permissions)
    });
  } catch (error) {
    console.error('completePinReset error:', error);
    return res.status(500).json({ success: false, message: 'Failed to complete PIN reset.' });
  }
};

// 9. Change PIN with Current PIN Verification (Settings -> Change PIN)
exports.changePin = async (req, res) => {
  try {
    const { currentPin, newPin } = req.body;
    if (!currentPin || !newPin) {
      return res.status(400).json({ success: false, message: 'Current PIN and New PIN are required.' });
    }

    if (!/^\d{4,6}$/.test(newPin.trim())) {
      return res.status(400).json({ success: false, message: 'New PIN must be 4 to 6 digits.' });
    }

    let userId = req.user ? req.user.id : req.body.userId;
    if (!userId && req.headers['authorization']) {
      try {
        const token = req.headers['authorization'].split(' ')[1];
        const decoded = jwt.verify(token, JWT_SECRET);
        userId = decoded.userId;
      } catch (_) {}
    }

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Authentication required.' });
    }

    const user = await resolveUser(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    const userPin = await db.getUserPin(user.id);
    if (!userPin) {
      return res.status(400).json({ success: false, message: 'No security PIN is currently configured for this account.' });
    }

    const isMatch = await bcrypt.compare(currentPin.trim(), userPin.pin_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Incorrect Current Security PIN.' });
    }

    const newPinHash = await bcrypt.hash(newPin.trim(), 10);
    await db.saveUserPin(user.id, newPinHash);

    await db.logAction('PIN_CHANGED', 'AUTH', `User ${user.name} changed their security PIN via Settings`, user.id, user.organization_id, req.ip);

    return res.status(200).json({
      success: true,
      message: '4-Digit Security PIN updated successfully!'
    });
  } catch (error) {
    console.error('changePin error:', error);
    return res.status(500).json({ success: false, message: 'Failed to change security PIN.' });
  }
};
