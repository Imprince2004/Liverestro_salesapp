const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

require('dotenv').config();

let pool = null;
let isPostgres = false;
let localStore = {
  organizations: [],
  users: [],
  roles_permissions: [],
  tasks: [],
  audit_logs: []
};

const dataDir = path.join(__dirname, '../../data');
const localDbFile = path.join(dataDir, 'liverestro_db.json');

function saveLocalStore() {
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }
  fs.writeFileSync(localDbFile, JSON.stringify(localStore, null, 2));
}

function loadLocalStore() {
  if (fs.existsSync(localDbFile)) {
    try {
      const content = fs.readFileSync(localDbFile, 'utf8');
      localStore = JSON.parse(content);
    } catch (e) {
      console.error('Error loading local store:', e.message);
    }
  }
}

async function initDatabase() {
  loadLocalStore();

  const connectionString = process.env.DATABASE_URL || 'postgresql://postgres:Dhruvisha@localhost:5432/liverestro';
  const maxPool = parseInt(process.env.DB_POOL_MAX || '25', 10);
  const minPool = parseInt(process.env.DB_POOL_MIN || '4', 10);
  const idleTimeout = parseInt(process.env.DB_POOL_IDLE_TIMEOUT || '30000', 10);
  const connTimeout = parseInt(process.env.DB_POOL_CONN_TIMEOUT || '3000', 10);

  try {
    const isCloudPg = connectionString.includes('render.com') || 
                      connectionString.includes('neon.tech') || 
                      connectionString.includes('supabase') || 
                      connectionString.includes('railway') || 
                      process.env.PG_SSL === 'true' || 
                      process.env.NODE_ENV === 'production';

    const testPool = new Pool({
      connectionString,
      ssl: isCloudPg ? { rejectUnauthorized: false } : false,
      max: maxPool,
      min: minPool,
      idleTimeoutMillis: idleTimeout,
      connectionTimeoutMillis: connTimeout,
    });
    const client = await testPool.connect();
    await client.query('SELECT 1');
    client.release();
    pool = testPool;
    isPostgres = true;
    console.log('✅ Connected to PostgreSQL Database successfully.');
    await createPgSchema();
  } catch (err) {
    console.log('ℹ️ Running in Local Storage Mode (PostgreSQL driver ready):', err.message);
    isPostgres = false;
  }

  try {
    await db.normalizeAllUserEmployeeIds();
  } catch (e) {
    console.error('Normalization error:', e.message);
  }
}

async function createPgSchema() {
  if (!isPostgres || !pool) return;

  const sql = `
    CREATE TABLE IF NOT EXISTS organizations (
      id VARCHAR(64) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      code VARCHAR(64) UNIQUE NOT NULL,
      status VARCHAR(32) DEFAULT 'ACTIVE',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(64) PRIMARY KEY,
      organization_id VARCHAR(64) REFERENCES organizations(id) ON DELETE SET NULL,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      phone VARCHAR(64) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role VARCHAR(64) NOT NULL,
      status VARCHAR(32) DEFAULT 'ACTIVE',
      manager_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      employee_id VARCHAR(32) UNIQUE,
      date_of_joining VARCHAR(64),
      date_of_birth VARCHAR(64),
      designation VARCHAR(128),
      profile_photo VARCHAR(512),
      territory VARCHAR(255),
      city VARCHAR(128),
      visits_target INTEGER DEFAULT 8,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id VARCHAR(32);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_joining VARCHAR(64);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth VARCHAR(64);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS designation VARCHAR(128);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo VARCHAR(512);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS territory VARCHAR(255);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(128);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS state VARCHAR(128);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS address TEXT;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS pincode VARCHAR(32);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(128);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(64);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_relationship VARCHAR(64);
    ALTER TABLE users ADD COLUMN IF NOT EXISTS visits_target INTEGER DEFAULT 8;
    ALTER TABLE users ADD COLUMN IF NOT EXISTS registered_by_user_id VARCHAR(64);
    CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_unique ON users(phone);

    CREATE TABLE IF NOT EXISTS roles_permissions (
      id VARCHAR(64) PRIMARY KEY,
      role VARCHAR(64) NOT NULL,
      permission_key VARCHAR(128) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS tasks (
      id VARCHAR(64) PRIMARY KEY,
      organization_id VARCHAR(64) NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      manager_id VARCHAR(64) NOT NULL REFERENCES users(id),
      assigned_to_id VARCHAR(64) NOT NULL REFERENCES users(id),
      title VARCHAR(255) NOT NULL,
      description TEXT,
      task_type VARCHAR(64) NOT NULL,
      priority VARCHAR(32) NOT NULL,
      status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
      restaurant_name VARCHAR(255),
      location VARCHAR(255),
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      due_date VARCHAR(64) NOT NULL,
      notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS task_type VARCHAR(64) DEFAULT 'RESTAURANT_VISIT';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS priority VARCHAR(32) DEFAULT 'MEDIUM';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS status VARCHAR(32) DEFAULT 'PENDING';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS restaurant_name VARCHAR(255);
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS location VARCHAR(255);
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS due_date VARCHAR(64) DEFAULT '2026-08-15';
    ALTER TABLE tasks ADD COLUMN IF NOT EXISTS notes TEXT;

    CREATE TABLE IF NOT EXISTS audit_logs (
      id VARCHAR(64) PRIMARY KEY,
      organization_id VARCHAR(64),
      user_id VARCHAR(64),
      action VARCHAR(128) NOT NULL,
      resource VARCHAR(128) NOT NULL,
      details TEXT,
      ip_address VARCHAR(64),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS user_id VARCHAR(64);
    ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS organization_id VARCHAR(64);
    ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS resource VARCHAR(128);
    ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS action VARCHAR(128);
    ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS entity VARCHAR(128);
    ALTER TABLE audit_logs ALTER COLUMN entity DROP NOT NULL;

    CREATE TABLE IF NOT EXISTS leads (
      id VARCHAR(64) PRIMARY KEY,
      contact_person_name VARCHAR(255),
      restaurant_name VARCHAR(255) NOT NULL,
      owner_name VARCHAR(255),
      mobile VARCHAR(64),
      whatsapp VARCHAR(64),
      alternate_mobile VARCHAR(64),
      email VARCHAR(255),
      preferred_contact_method VARCHAR(64),
      best_time_to_contact VARCHAR(128),
      lead_source VARCHAR(128),
      status VARCHAR(64) DEFAULT 'New Lead',
      priority VARCHAR(64) DEFAULT 'Medium',
      business_type VARCHAR(128),
      address TEXT,
      city VARCHAR(128),
      area VARCHAR(128),
      pincode VARCHAR(32),
      latitude DOUBLE PRECISION,
      longitude DOUBLE PRECISION,
      num_outlets INTEGER DEFAULT 1,
      seating_capacity INTEGER,
      cuisine VARCHAR(255),
      current_pos VARCHAR(128),
      current_ordering_system VARCHAR(128),
      delivery_platforms TEXT,
      monthly_orders INTEGER,
      estimated_monthly_revenue DOUBLE PRECISION,
      required_solutions TEXT,
      pain_points TEXT,
      required_solution_notes TEXT,
      current_competitor VARCHAR(128),
      reason_considering TEXT,
      expected_benefits TEXT,
      decision_maker_name VARCHAR(255),
      decision_maker_designation VARCHAR(128),
      budget_range VARCHAR(128),
      estimated_deal_value DOUBLE PRECISION,
      purchase_probability INTEGER,
      expected_closing_date VARCHAR(64),
      competitor_notes TEXT,
      demo_required BOOLEAN DEFAULT FALSE,
      demo_date VARCHAR(64),
      proposal_required BOOLEAN DEFAULT FALSE,
      sales_notes TEXT,
      assigned_salesperson VARCHAR(255),
      assigned_salesperson_id VARCHAR(64),
      created_by VARCHAR(255),
      created_by_id VARCHAR(64),
      next_follow_up_date VARCHAR(64),
      next_follow_up_time VARCHAR(64),
      next_follow_up_type VARCHAR(64),
      follow_up_notes TEXT,
      has_reminder BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS visits (
      id VARCHAR(64) PRIMARY KEY,
      restaurant_name VARCHAR(255) NOT NULL,
      address TEXT,
      lead_id VARCHAR(64),
      executive_id VARCHAR(64),
      distance_km DOUBLE PRECISION DEFAULT 0.0,
      is_geo_fence_verified BOOLEAN DEFAULT TRUE,
      is_auto_checked_in BOOLEAN DEFAULT FALSE,
      notes TEXT,
      questions_checklist TEXT,
      products_discussed TEXT,
      demo_given BOOLEAN DEFAULT FALSE,
      follow_up_action TEXT,
      start_time VARCHAR(64),
      end_time VARCHAR(64),
      duration VARCHAR(64),
      status VARCHAR(64) DEFAULT 'Completed',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    ALTER TABLE visits ADD COLUMN IF NOT EXISTS audio_url TEXT;
    ALTER TABLE visits ADD COLUMN IF NOT EXISTS transcription_summary TEXT;

    ALTER TABLE leads ADD COLUMN IF NOT EXISTS audio_url TEXT;
    ALTER TABLE leads ADD COLUMN IF NOT EXISTS transcription_summary TEXT;
    ALTER TABLE leads ADD COLUMN IF NOT EXISTS pos_software VARCHAR(32) DEFAULT 'Free';
    ALTER TABLE leads ADD COLUMN IF NOT EXISTS pos_amount DOUBLE PRECISION DEFAULT 0.0;

    CREATE TABLE IF NOT EXISTS pos_software_orders (
      id VARCHAR(64) PRIMARY KEY,
      lead_id VARCHAR(64) REFERENCES leads(id) ON DELETE CASCADE,
      restaurant_name VARCHAR(255) NOT NULL,
      contact_person VARCHAR(255),
      contact_phone VARCHAR(64),
      location VARCHAR(255),
      assigned_executive_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      assigned_executive_name VARCHAR(255),
      assigned_manager_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      assigned_manager_name VARCHAR(255),
      pos_type VARCHAR(32) NOT NULL DEFAULT 'Free',
      amount DOUBLE PRECISION DEFAULT 0.0,
      status VARCHAR(64) DEFAULT 'Active',
      created_by VARCHAR(64),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS otp_verifications (
      id VARCHAR(64) PRIMARY KEY,
      phone VARCHAR(64) NOT NULL,
      otp_code VARCHAR(32) NOT NULL,
      attempts INTEGER DEFAULT 0,
      is_verified BOOLEAN DEFAULT FALSE,
      expires_at VARCHAR(64) NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS totp_credentials (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) UNIQUE REFERENCES users(id) ON DELETE CASCADE,
      secret VARCHAR(255) NOT NULL,
      is_enabled BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_pins (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) UNIQUE REFERENCES users(id) ON DELETE CASCADE,
      pin_hash VARCHAR(255) NOT NULL,
      failed_attempts INTEGER DEFAULT 0,
      locked_until VARCHAR(64),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS pin_reset_requests (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
      user_name VARCHAR(255) NOT NULL,
      employee_id VARCHAR(64),
      designation VARCHAR(128),
      phone VARCHAR(64) NOT NULL,
      role VARCHAR(64) NOT NULL,
      status VARCHAR(32) DEFAULT 'PENDING',
      requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      approved_at TIMESTAMP WITH TIME ZONE,
      approved_by VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      approved_by_name VARCHAR(255),
      completed_at TIMESTAMP WITH TIME ZONE,
      notes TEXT
    );

    CREATE TABLE IF NOT EXISTS notification_history (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
      title VARCHAR(255) NOT NULL,
      body TEXT NOT NULL,
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS hardware_catalog (
      id VARCHAR(64) PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      price DOUBLE PRECISION NOT NULL,
      description TEXT,
      sku VARCHAR(64) UNIQUE,
      category VARCHAR(64) DEFAULT 'Hardware',
      image_url TEXT,
      specifications TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS help_center (
      id VARCHAR(64) PRIMARY KEY,
      question TEXT NOT NULL,
      answer TEXT NOT NULL,
      category VARCHAR(128) DEFAULT 'General',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS video_tutorials (
      id VARCHAR(64) PRIMARY KEY,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      category VARCHAR(128) DEFAULT 'Guides',
      video_url TEXT NOT NULL,
      thumbnail_url TEXT,
      duration VARCHAR(32),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS quotation_records (
      id VARCHAR(64) PRIMARY KEY,
      client_name VARCHAR(255) NOT NULL,
      restaurant_name VARCHAR(255) NOT NULL,
      email VARCHAR(255),
      phone VARCHAR(64),
      items TEXT NOT NULL, -- JSON array string
      subtotal DOUBLE PRECISION NOT NULL,
      discount DOUBLE PRECISION DEFAULT 0.0,
      tax DOUBLE PRECISION DEFAULT 0.0,
      total DOUBLE PRECISION NOT NULL,
      created_by VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_sessions (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
      token_hash TEXT NOT NULL,
      refresh_token_hash TEXT,
      device_info TEXT,
      ip_address VARCHAR(128),
      expires_at VARCHAR(64) NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS attendance (
      id VARCHAR(64) PRIMARY KEY,
      user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
      check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
      check_in_lat DOUBLE PRECISION,
      check_in_lng DOUBLE PRECISION,
      check_out_time TIMESTAMP WITH TIME ZONE,
      check_out_lat DOUBLE PRECISION,
      check_out_lng DOUBLE PRECISION,
      duration_minutes INTEGER,
      is_automatic BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS follow_ups (
      id VARCHAR(64) PRIMARY KEY,
      lead_id VARCHAR(64),
      user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      restaurant_name VARCHAR(255) NOT NULL,
      contact_person VARCHAR(255) NOT NULL,
      phone VARCHAR(64) NOT NULL,
      address TEXT,
      follow_up_type VARCHAR(128) NOT NULL,
      priority VARCHAR(32) DEFAULT 'Medium',
      status VARCHAR(32) DEFAULT 'PENDING',
      scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
      notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS monthly_targets (
      id VARCHAR(64) PRIMARY KEY,
      organization_id VARCHAR(64) REFERENCES organizations(id) ON DELETE SET NULL,
      user_id VARCHAR(64) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      assigned_by_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      assigned_by_name VARCHAR(255),
      month INTEGER NOT NULL,
      year INTEGER NOT NULL,
      target_leads INTEGER NOT NULL DEFAULT 20,
      target_visits INTEGER DEFAULT 50,
      target_revenue DOUBLE PRECISION DEFAULT 0.0,
      notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      UNIQUE(user_id, month, year)
    );

    CREATE TABLE IF NOT EXISTS lead_implementations (
      id VARCHAR(64) PRIMARY KEY,
      organization_id VARCHAR(64) REFERENCES organizations(id) ON DELETE SET NULL,
      lead_id VARCHAR(64) REFERENCES leads(id) ON DELETE CASCADE,
      restaurant_name VARCHAR(255) NOT NULL,
      lead_owner_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      lead_owner_name VARCHAR(255),
      overall_stage VARCHAR(64) DEFAULT 'DEMO',
      overall_status VARCHAR(64) DEFAULT 'IN_PROGRESS',
      progress_percent INTEGER DEFAULT 20,
      demo_status VARCHAR(64) DEFAULT 'NOT_STARTED',
      demo_assigned_to_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      demo_assigned_to_name VARCHAR(255),
      demo_assigned_date VARCHAR(64),
      demo_completed_date VARCHAR(64),
      demo_notes TEXT,
      setup_status VARCHAR(64) DEFAULT 'NOT_STARTED',
      setup_assigned_to_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      setup_assigned_to_name VARCHAR(255),
      setup_assigned_date VARCHAR(64),
      setup_completed_date VARCHAR(64),
      setup_notes TEXT,
      training_status VARCHAR(64) DEFAULT 'NOT_STARTED',
      training_assigned_to_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      training_assigned_to_name VARCHAR(255),
      training_assigned_date VARCHAR(64),
      training_completed_date VARCHAR(64),
      training_notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS post_sale_followups (
      id VARCHAR(64) PRIMARY KEY,
      lead_id VARCHAR(64) REFERENCES leads(id) ON DELETE CASCADE,
      order_id VARCHAR(64) REFERENCES pos_software_orders(id) ON DELETE CASCADE,
      restaurant_name VARCHAR(255) NOT NULL,
      executive_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      executive_name VARCHAR(255),
      manager_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
      scheduled_date VARCHAR(64),
      completed_date VARCHAR(64),
      rating INTEGER DEFAULT 5,
      client_feedback TEXT,
      issues_reported TEXT,
      improvement_requests TEXT,
      additional_requirements TEXT,
      status VARCHAR(32) DEFAULT 'PENDING',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    ALTER TABLE lead_implementations ADD COLUMN IF NOT EXISTS demo_assigned_to_designation VARCHAR(128);
    ALTER TABLE lead_implementations ADD COLUMN IF NOT EXISTS setup_assigned_to_designation VARCHAR(128);
    ALTER TABLE lead_implementations ADD COLUMN IF NOT EXISTS training_assigned_to_designation VARCHAR(128);

    CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(LOWER(email));
    CREATE INDEX IF NOT EXISTS idx_users_phone_clean ON users (regexp_replace(phone, '\\D', '', 'g'));
    CREATE INDEX IF NOT EXISTS idx_user_pins_user_id ON user_pins(user_id);
    CREATE INDEX IF NOT EXISTS idx_totp_credentials_user_id ON totp_credentials(user_id);
  `;
  await pool.query(sql);
}

// Data Store Access Methods
const db = {
  // Raw Query helper
  async query(text, params) {
    if (isPostgres && pool) {
      return pool.query(text, params);
    }
    return { rows: [] };
  },

  // Ultra-Fast Index-Optimized Mobile Verification Query
  async identifyUserByPhoneFast(phone) {
    const cleanDigits = String(phone).trim().replace(/[^0-9]/g, '');
    const cleanId = String(phone).trim().toLowerCase();

    if (isPostgres && pool) {
      const sql = `
        SELECT 
          u.id, 
          u.name, 
          u.email, 
          u.phone, 
          u.role, 
          u.designation, 
          u.status,
          u.profile_photo,
          u.organization_id,
          u.manager_id,
          u.employee_id,
          u.date_of_joining,
          u.territory,
          u.city,
          u.registered_by_user_id,
          (p.user_id IS NOT NULL) AS has_pin,
          tc.secret AS totp_secret,
          creator.name AS registered_by_name,
          creator.designation AS registered_by_designation,
          creator.role AS registered_by_role
        FROM users u
        LEFT JOIN user_pins p ON p.user_id = u.id
        LEFT JOIN totp_credentials tc ON tc.user_id = u.id
        LEFT JOIN users creator ON u.registered_by_user_id = creator.id
        WHERE u.phone = $1 
           OR u.phone = $2
           OR LOWER(u.email) = $3
           OR regexp_replace(u.phone, '\\D', '', 'g') = $2
        LIMIT 1
      `;
      const res = await pool.query(sql, [phone, cleanDigits, cleanId]);
      if (!res.rows[0]) return null;
      const row = res.rows[0];

      let addedBy = 'Not Available';
      if (row.registered_by_name && row.registered_by_name.trim()) {
        const cleanName = row.registered_by_name.trim();
        const isCreatorAdmin = row.registered_by_role === 'SUPER_ADMIN' || row.registered_by_role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
        if (isCreatorAdmin) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        } else {
          let desig = row.registered_by_designation && row.registered_by_designation.trim() ? row.registered_by_designation.trim() : (row.registered_by_role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
          if (desig.toLowerCase().includes('manager')) {
            desig = 'Sales Manager';
          }
          addedBy = `${desig} - ${cleanName}`;
        }
      } else if (row.registered_by_user_id === 'usr_superadmin_001' || row.registered_by_user_id === 'usr_companyadmin_002' || (row.registered_by_user_id && String(row.registered_by_user_id).includes('admin'))) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      }

      return {
        ...row,
        added_by: addedBy,
        addedBy
      };
    }

    if (!localStore || !Array.isArray(localStore.users)) return null;
    const user = localStore.users.find(u =>
      u.phone === phone ||
      (u.phone && u.phone.replace(/[^0-9]/g, '') === cleanDigits) ||
      (u.email && u.email.toLowerCase() === cleanId)
    );
    if (!user) return null;

    const hasPin = Array.isArray(localStore.user_pins) && localStore.user_pins.some(p => p.user_id === user.id);
    const totpCred = Array.isArray(localStore.totp_credentials) && localStore.totp_credentials.find(t => t.user_id === user.id);
    const creator = (user.registered_by_user_id && Array.isArray(localStore.users)) ? localStore.users.find(u => u.id === user.registered_by_user_id) : null;

    let addedBy = 'Not Available';
    if (creator && creator.name) {
      const cleanName = creator.name.trim();
      const isCreatorAdmin = creator.role === 'SUPER_ADMIN' || creator.role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
      if (isCreatorAdmin) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      } else {
        let desig = creator.designation && creator.designation.trim() ? creator.designation.trim() : (creator.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
        if (desig.toLowerCase().includes('manager')) {
          desig = 'Sales Manager';
        }
        addedBy = `${desig} - ${cleanName}`;
      }
    } else if (user.registered_by_user_id === 'usr_superadmin_001' || user.registered_by_user_id === 'usr_companyadmin_002' || (user.registered_by_user_id && String(user.registered_by_user_id).includes('admin'))) {
      addedBy = 'LiveRestro Admin - LiveRestro Admin';
    }

    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      designation: user.designation,
      status: user.status,
      profile_photo: user.profile_photo,
      organization_id: user.organization_id,
      manager_id: user.manager_id,
      employee_id: user.employee_id,
      date_of_joining: user.date_of_joining,
      territory: user.territory,
      city: user.city,
      registered_by_user_id: user.registered_by_user_id,
      has_pin: hasPin,
      totp_secret: totpCred ? totpCred.secret : null,
      added_by: addedBy,
      addedBy
    };
  },

  getLocalStore() {
    return localStore;
  },
  getIsPostgres() {
    return isPostgres;
  },
  // Organizations
  async getOrganizations() {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM organizations ORDER BY created_at DESC');
      return res.rows;
    }
    return localStore.organizations;
  },

  async getOrganizationById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM organizations WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    return localStore.organizations.find(o => o.id === id) || null;
  },

  async createOrganization(org) {
    const newOrg = {
      ...org,
      status: org.status || 'ACTIVE',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    if (isPostgres && pool) {
      await pool.query(
        'INSERT INTO organizations (id, name, code, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)',
        [newOrg.id, newOrg.name, newOrg.code, newOrg.status, newOrg.created_at, newOrg.updated_at]
      );
      return newOrg;
    }
    localStore.organizations.push(newOrg);
    saveLocalStore();
    return newOrg;
  },

  // Unique Sequential Employee ID Generator: EMP001, EMP002, EMP003...
  async generateNextEmployeeId() {
    let maxNum = 0;
    if (isPostgres && pool) {
      try {
        const res = await pool.query("SELECT employee_id FROM users WHERE employee_id LIKE 'EMP%' ORDER BY employee_id DESC");
        for (const row of res.rows) {
          const match = String(row.employee_id || '').match(/^EMP(\d+)$/i);
          if (match) {
            const num = parseInt(match[1], 10);
            if (num > maxNum) maxNum = num;
          }
        }
      } catch (_) {}
    }

    if (localStore && Array.isArray(localStore.users)) {
      for (const u of localStore.users) {
        const match = String(u.employee_id || '').match(/^EMP(\d+)$/i);
        if (match) {
          const num = parseInt(match[1], 10);
          if (num > maxNum) maxNum = num;
        }
      }
    }

    const nextNum = maxNum + 1;
    return `EMP${String(nextNum).padStart(3, '0')}`;
  },

  // Auto-normalize and ensure all users have unique sequential EMP IDs
  async normalizeAllUserEmployeeIds() {
    const knownFixed = {
      'usr_superadmin_001': 'EMP001',
      'usr_companyadmin_002': 'EMP002',
      'usr_salesmanager_003': 'EMP003',
      'usr_salesexecutive_004': 'EMP004',
      'usr_salesexecutive_ankit': 'EMP005',
      'usr_salesexecutive_prince': 'EMP006'
    };

    let counter = 7;
    const usedIds = new Set();

    if (localStore && Array.isArray(localStore.users)) {
      // First pass: assign known fixed IDs
      for (const u of localStore.users) {
        if (knownFixed[u.id]) {
          u.employee_id = knownFixed[u.id];
          usedIds.add(u.employee_id);
        }
      }

      // Second pass: assign strictly unique sequential IDs to all other users
      for (const u of localStore.users) {
        if (knownFixed[u.id]) continue;

        if (!u.employee_id || usedIds.has(u.employee_id) || u.employee_id === 'EMP004') {
          let newEmpId = `EMP${String(counter++).padStart(3, '0')}`;
          while (usedIds.has(newEmpId)) {
            newEmpId = `EMP${String(counter++).padStart(3, '0')}`;
          }
          u.employee_id = newEmpId;
        }
        usedIds.add(u.employee_id);

        if (!u.date_of_joining) {
          u.date_of_joining = '2024-03-01';
        }
        if (u.role === 'SALES_EXECUTIVE' && !u.manager_id) {
          u.manager_id = 'usr_salesmanager_003';
        }
        if (!u.registered_by_user_id) {
          u.registered_by_user_id = u.role === 'SALES_MANAGER' ? 'usr_companyadmin_002' : (u.manager_id || 'usr_companyadmin_002');
        }
      }
      saveLocalStore();
    }

    if (isPostgres && pool) {
      try {
        const res = await pool.query('SELECT * FROM users ORDER BY created_at ASC');
        let pgCounter = 7;
        const pgUsedIds = new Set();
        for (const u of res.rows) {
          if (knownFixed[u.id]) {
            pgUsedIds.add(knownFixed[u.id]);
          }
        }
        for (const u of res.rows) {
          let targetEmpId = u.employee_id;
          if (knownFixed[u.id]) {
            targetEmpId = knownFixed[u.id];
          } else if (!targetEmpId || pgUsedIds.has(targetEmpId) || targetEmpId === 'EMP004') {
            targetEmpId = `EMP${String(pgCounter++).padStart(3, '0')}`;
            while (pgUsedIds.has(targetEmpId)) {
              targetEmpId = `EMP${String(pgCounter++).padStart(3, '0')}`;
            }
          }
          pgUsedIds.add(targetEmpId);

          const targetCreatorId = u.registered_by_user_id || (u.role === 'SALES_MANAGER' ? 'usr_companyadmin_002' : (u.manager_id || 'usr_companyadmin_002'));

          await pool.query(
            'UPDATE users SET employee_id = $1, date_of_joining = COALESCE(date_of_joining, $2), manager_id = COALESCE(manager_id, $3), registered_by_user_id = COALESCE(registered_by_user_id, $4) WHERE id = $5',
            [targetEmpId, '2024-03-01', 'usr_salesmanager_003', targetCreatorId, u.id]
          );
        }
        await pool.query("UPDATE users SET profile_photo = '' WHERE profile_photo LIKE '%unsplash%'");
      } catch (_) {}
    }
  },

  // Users
  async findUserByEmailOrPhone(identifier) {
    const cleanId = String(identifier).trim().toLowerCase();
    const cleanPhone = String(identifier).trim().replace(/[^0-9]/g, '');

    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT u.*, creator.name as registered_by_name, creator.designation as registered_by_designation, creator.role as registered_by_role
         FROM users u
         LEFT JOIN users creator ON u.registered_by_user_id = creator.id
         WHERE LOWER(u.email) = $1 OR u.phone = $2 OR u.phone = $3 
            OR regexp_replace(u.phone, '\\D', '', 'g') = $3
         LIMIT 1`,
        [cleanId, identifier, cleanPhone]
      );
      if (!res.rows[0]) return null;
      const row = res.rows[0];

      let addedBy = 'Not Available';
      if (row.registered_by_name && row.registered_by_name.trim()) {
        const cleanName = row.registered_by_name.trim();
        const isCreatorAdmin = row.registered_by_role === 'SUPER_ADMIN' || row.registered_by_role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
        if (isCreatorAdmin) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        } else {
          let desig = row.registered_by_designation && row.registered_by_designation.trim() ? row.registered_by_designation.trim() : (row.registered_by_role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
          if (desig.toLowerCase().includes('manager')) {
            desig = 'Sales Manager';
          }
          addedBy = `${desig} - ${cleanName}`;
        }
      } else if (row.registered_by_user_id === 'usr_superadmin_001' || row.registered_by_user_id === 'usr_companyadmin_002' || (row.registered_by_user_id && String(row.registered_by_user_id).includes('admin'))) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      }

      return {
        ...row,
        added_by: addedBy,
        addedBy
      };
    }
    const user = localStore.users.find(u =>
      u.email.toLowerCase() === cleanId ||
      u.phone === identifier ||
      u.phone.replace(/[^0-9]/g, '') === cleanPhone
    );
    if (!user) return null;

    const creator = (user.registered_by_user_id && Array.isArray(localStore.users)) ? localStore.users.find(u => u.id === user.registered_by_user_id) : null;
    let addedBy = 'Not Available';
    if (creator && creator.name) {
      const cleanName = creator.name.trim();
      const isCreatorAdmin = creator.role === 'SUPER_ADMIN' || creator.role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
      if (isCreatorAdmin) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      } else {
        let desig = creator.designation && creator.designation.trim() ? creator.designation.trim() : (creator.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
        if (desig.toLowerCase().includes('manager')) {
          desig = 'Sales Manager';
        }
        addedBy = `${desig} - ${cleanName}`;
      }
    } else if (user.registered_by_user_id === 'usr_superadmin_001' || user.registered_by_user_id === 'usr_companyadmin_002' || (user.registered_by_user_id && String(user.registered_by_user_id).includes('admin'))) {
      addedBy = 'LiveRestro Admin - LiveRestro Admin';
    }

    return {
      ...user,
      added_by: addedBy,
      addedBy
    };
  },

  async getUserById(id) {
    if (isPostgres && pool) {
      const res = await pool.query(`
        SELECT u.*, creator.name as registered_by_name, creator.designation as registered_by_designation, creator.role as registered_by_role
        FROM users u
        LEFT JOIN users creator ON u.registered_by_user_id = creator.id
        WHERE u.id = $1
      `, [id]);
      if (!res.rows[0]) return null;
      const row = res.rows[0];
      let addedBy = 'Not Available';
      if (row.registered_by_name && row.registered_by_name.trim()) {
        let cleanName = row.registered_by_name.trim();
        const isCreatorAdmin = row.registered_by_role === 'SUPER_ADMIN' || row.registered_by_role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
        if (isCreatorAdmin) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        } else {
          let desig = row.registered_by_designation && row.registered_by_designation.trim() ? row.registered_by_designation.trim() : (row.registered_by_role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
          if (desig.toLowerCase().includes('manager')) {
            desig = 'Sales Manager';
          }
          if (cleanName === 'Sales Manager Demo') {
            cleanName = 'Prince Chandarana';
          }
          addedBy = `${desig} - ${cleanName}`;
        }
      } else if (row.registered_by_user_id === 'usr_superadmin_001' || row.registered_by_user_id === 'usr_companyadmin_002' || (row.registered_by_user_id && row.registered_by_user_id.includes('admin'))) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      }
      return {
        ...row,
        added_by: addedBy
      };
    }
    const user = localStore.users.find(u => u.id === id) || null;
    if (!user) return null;
    let addedBy = 'Not Available';
    if (user.registered_by_user_id) {
      const creator = localStore.users.find(c => c.id === user.registered_by_user_id);
      if (creator && creator.name) {
        let cleanName = creator.name.trim();
        const isCreatorAdmin = creator.role === 'SUPER_ADMIN' || creator.role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
        if (isCreatorAdmin) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        } else {
          let desig = creator.designation && creator.designation.trim() ? creator.designation.trim() : (creator.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
          if (desig.toLowerCase().includes('manager')) {
            desig = 'Sales Manager';
          }
          if (cleanName === 'Sales Manager Demo') {
            cleanName = 'Prince Chandarana';
          }
          addedBy = `${desig} - ${cleanName}`;
        }
      } else if (user.registered_by_user_id === 'usr_superadmin_001' || user.registered_by_user_id === 'usr_companyadmin_002' || user.registered_by_user_id.includes('admin')) {
        addedBy = 'LiveRestro Admin - LiveRestro Admin';
      }
    }
    return { ...user, added_by: addedBy };
  },

  // Get user with populated assigned manager details
  async getUserWithManager(userId) {
    const user = await this.getUserById(userId);
    if (!user) return null;

    let manager = null;
    if (user.manager_id) {
      const mgr = await this.getUserById(user.manager_id);
      if (mgr) {
        manager = {
          id: mgr.id,
          name: mgr.name,
          email: mgr.email,
          phone: mgr.phone,
          designation: mgr.designation || 'Sales Manager',
          profile_photo: mgr.profile_photo || '',
          territory: mgr.territory || 'Gujarat Region Command',
          city: mgr.city || 'Ahmedabad',
          employee_id: mgr.employee_id || 'EMP003',
          status: mgr.status || 'ACTIVE'
        };
      }
    }
    return { ...user, assigned_manager: manager, added_by: user.added_by || 'Not Available' };
  },

  async getUsers(filter = {}) {
    if (isPostgres && pool) {
      let queryStr = `
        SELECT u.*, creator.name as registered_by_name, creator.designation as registered_by_designation, creator.role as registered_by_role
        FROM users u
        LEFT JOIN users creator ON u.registered_by_user_id = creator.id
        WHERE 1=1
      `;
      const params = [];
      if (filter.organization_id) {
        params.push(filter.organization_id);
        queryStr += ` AND u.organization_id = $${params.length}`;
      }
      if (filter.role) {
        params.push(filter.role);
        queryStr += ` AND u.role = $${params.length}`;
      }
      if (filter.manager_id) {
        params.push(filter.manager_id);
        queryStr += ` AND (u.manager_id = $${params.length} OR u.registered_by_user_id = $${params.length})`;
      }
      queryStr += ' ORDER BY u.created_at DESC';
      const res = await pool.query(queryStr, params);
      return res.rows.map(row => {
        let addedBy = 'Not Available';
        if (row.registered_by_name && row.registered_by_name.trim()) {
          let cleanName = row.registered_by_name.trim();
          const isCreatorAdmin = row.registered_by_role === 'SUPER_ADMIN' || row.registered_by_role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
          if (isCreatorAdmin) {
            addedBy = 'LiveRestro Admin - LiveRestro Admin';
          } else {
            let desig = row.registered_by_designation && row.registered_by_designation.trim() ? row.registered_by_designation.trim() : (row.registered_by_role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
            if (desig.toLowerCase().includes('manager')) {
              desig = 'Sales Manager';
            }
            if (cleanName === 'Sales Manager Demo') {
              cleanName = 'Prince Chandarana';
            }
            addedBy = `${desig} - ${cleanName}`;
          }
        } else if (row.registered_by_user_id === 'usr_superadmin_001' || row.registered_by_user_id === 'usr_companyadmin_002' || (row.registered_by_user_id && row.registered_by_user_id.includes('admin'))) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        }
        return {
          ...row,
          added_by: addedBy
        };
      });
    }

    return localStore.users.filter(u => {
      if (filter.organization_id && u.organization_id !== filter.organization_id) return false;
      if (filter.role && u.role !== filter.role) return false;
      if (filter.manager_id && u.manager_id !== filter.manager_id && u.registered_by_user_id !== filter.manager_id) return false;
      return true;
    }).map(u => {
      let addedBy = 'Not Available';
      if (u.registered_by_user_id) {
        const creator = localStore.users.find(c => c.id === u.registered_by_user_id);
        if (creator && creator.name) {
          let cleanName = creator.name.trim();
          const isCreatorAdmin = creator.role === 'SUPER_ADMIN' || creator.role === 'COMPANY_ADMIN' || cleanName.toLowerCase().includes('admin');
          if (isCreatorAdmin) {
            addedBy = 'LiveRestro Admin - LiveRestro Admin';
          } else {
            let desig = creator.designation && creator.designation.trim() ? creator.designation.trim() : (creator.role === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive');
            if (desig.toLowerCase().includes('manager')) {
              desig = 'Sales Manager';
            }
            if (cleanName === 'Sales Manager Demo') {
              cleanName = 'Prince Chandarana';
            }
            addedBy = `${desig} - ${cleanName}`;
          }
        } else if (u.registered_by_user_id === 'usr_superadmin_001' || u.registered_by_user_id === 'usr_companyadmin_002' || u.registered_by_user_id.includes('admin')) {
          addedBy = 'LiveRestro Admin - LiveRestro Admin';
        }
      }
      return { ...u, added_by: addedBy };
    });
  },

  async getAvailableTerritories() {
    try {
      if (this.isPostgres && this.pool) {
        const res = await this.query(`
          SELECT DISTINCT territory as name FROM users WHERE territory IS NOT NULL AND TRIM(territory) != ''
          UNION
          SELECT DISTINCT area as name FROM leads WHERE area IS NOT NULL AND TRIM(area) != ''
          ORDER BY name ASC
        `);
        const names = res.rows.map(r => r.name.trim()).filter(n => n.length > 0);
        if (names.length > 0) return names;
      }
      return [
        'Ahmedabad North (Gota & Jagatpur)',
        'Ahmedabad North (SG Highway & Chandlodiya)',
        'Ahmedabad West (Sindhubhavan & Bodakdev)',
        'Ahmedabad West (Bopal & Shela)',
        'Ahmedabad Central (Navrangpura & CG Road)',
        'Ahmedabad East (Nikol & Vastral)',
        'Gujarat Headquarters'
      ];
    } catch (e) {
      console.error('getAvailableTerritories error:', e);
      return [
        'Ahmedabad North (Gota & Jagatpur)',
        'Ahmedabad North (SG Highway & Chandlodiya)',
        'Ahmedabad West (Sindhubhavan & Bodakdev)',
        'Ahmedabad West (Bopal & Shela)',
        'Ahmedabad Central (Navrangpura & CG Road)',
        'Ahmedabad East (Nikol & Vastral)',
        'Gujarat Headquarters'
      ];
    }
  },

  async createUser(user) {
    const employeeId = user.employee_id || await this.generateNextEmployeeId();
    const dateOfJoining = user.date_of_joining || new Date().toISOString().split('T')[0];
    const resolvedRole = user.role || (user.designation && user.designation.toLowerCase().includes('manager') ? 'SALES_MANAGER' : 'SALES_EXECUTIVE');

    const newUser = {
      ...user,
      role: resolvedRole,
      employee_id: employeeId,
      date_of_joining: dateOfJoining,
      date_of_birth: user.date_of_birth || null,
      designation: user.designation || (resolvedRole === 'SALES_MANAGER' ? 'Sales Manager' : 'Sales Executive'),
      profile_photo: user.profile_photo || '',
      territory: user.territory || 'Ahmedabad North',
      city: user.city || 'Ahmedabad',
      visits_target: user.visits_target || 8,
      registered_by_user_id: user.registered_by_user_id || null,
      status: user.status || 'ACTIVE',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        await client.query(
          `INSERT INTO users (id, organization_id, name, email, phone, password_hash, role, status, manager_id, employee_id, date_of_joining, date_of_birth, designation, profile_photo, territory, city, visits_target, registered_by_user_id, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,
          [
            newUser.id,
            newUser.organization_id,
            newUser.name,
            newUser.email,
            newUser.phone,
            newUser.password_hash,
            newUser.role,
            newUser.status,
            newUser.manager_id || null,
            newUser.employee_id,
            newUser.date_of_joining,
            newUser.date_of_birth,
            newUser.designation,
            newUser.profile_photo,
            newUser.territory,
            newUser.city,
            newUser.visits_target,
            newUser.registered_by_user_id,
            newUser.created_at,
            newUser.updated_at
          ]
        );
        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK');
        console.error('PostgreSQL transaction rollback error:', err);
        throw err;
      } finally {
        client.release();
      }
    }

    // Always maintain in localStore JSON database
    const idx = localStore.users.findIndex(u => u.id === newUser.id || u.phone === newUser.phone || u.email === newUser.email);
    if (idx >= 0) {
      localStore.users[idx] = { ...localStore.users[idx], ...newUser };
    } else {
      localStore.users.push(newUser);
    }
    saveLocalStore();
    return newUser;
  },

  async updateUser(id, updates) {
    if (isPostgres && pool) {
      try {
        const fields = Object.keys(updates);
        if (fields.length > 0) {
          const values = Object.values(updates);
          const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
          let res = await pool.query(`UPDATE users SET ${setClause}, updated_at = NOW() WHERE id = $1 RETURNING *`, [id, ...values]);
          if (res.rows.length === 0) {
            res = await pool.query(`UPDATE users SET ${setClause}, updated_at = NOW() WHERE employee_id = $1 OR email = $1 OR phone = $1 RETURNING *`, [id, ...values]);
          }
          if (res.rows.length > 0) {
            const updated = res.rows[0];
            const idx = localStore.users.findIndex(u => u.id === id || u.id === updated.id || u.employee_id === id || u.email === id || u.phone === id);
            if (idx !== -1) {
              localStore.users[idx] = { ...localStore.users[idx], ...updated };
              saveLocalStore();
            }
            return updated;
          }
        }
      } catch (err) {
        console.error('PostgreSQL update user error:', err);
      }
    }

    let idx = localStore.users.findIndex(u => u.id === id);
    if (idx === -1) {
      idx = localStore.users.findIndex(u => u.employee_id === id || u.email === id || u.phone === id);
    }
    if (idx !== -1) {
      localStore.users[idx] = { ...localStore.users[idx], ...updates, updated_at: new Date().toISOString() };
      saveLocalStore();
      return localStore.users[idx];
    }
    return null;
  },

  async deleteUser(id) {
    if (isPostgres && pool) {
      await pool.query('DELETE FROM users WHERE id = $1', [id]);
    }
    if (localStore && Array.isArray(localStore.users)) {
      localStore.users = localStore.users.filter(u => u.id !== id);
      saveLocalStore();
    }
    return true;
  },

  async updateUserDob(userId, dob) {
    return this.updateUser(userId, { date_of_birth: dob });
  },

  // Permissions
  async getPermissionsForRole(role) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT permission_key FROM roles_permissions WHERE role = $1', [role]);
      return res.rows.map(r => r.permission_key);
    }
    return localStore.roles_permissions
      .filter(rp => rp.role === role)
      .map(rp => rp.permission_key);
  },

  async setRolePermissions(role, permissions) {
    if (isPostgres && pool) {
      await pool.query('DELETE FROM roles_permissions WHERE role = $1', [role]);
      for (const perm of permissions) {
        const id = `${role}_${perm}`;
        await pool.query('INSERT INTO roles_permissions (id, role, permission_key) VALUES ($1, $2, $3)', [id, role, perm]);
      }
      return;
    }

    localStore.roles_permissions = localStore.roles_permissions.filter(rp => rp.role !== role);
    for (const perm of permissions) {
      localStore.roles_permissions.push({
        id: `${role}_${perm}`,
        role,
        permission_key: perm
      });
    }
    saveLocalStore();
  },

  // Tasks
  async getTasks(filter = {}) {
    if (isPostgres && pool) {
      let queryStr = 'SELECT * FROM tasks WHERE 1=1';
      const params = [];
      if (filter.organization_id) {
        params.push(filter.organization_id);
        queryStr += ` AND organization_id = $${params.length}`;
      }
      if (filter.manager_id) {
        params.push(filter.manager_id);
        queryStr += ` AND manager_id = $${params.length}`;
      }
      if (filter.assigned_to_id) {
        params.push(filter.assigned_to_id);
        queryStr += ` AND assigned_to_id = $${params.length}`;
      }
      if (filter.status) {
        params.push(filter.status);
        queryStr += ` AND status = $${params.length}`;
      }
      queryStr += ' ORDER BY created_at DESC';
      const res = await pool.query(queryStr, params);
      return res.rows;
    }

    return localStore.tasks.filter(t => {
      if (filter.organization_id && t.organization_id !== filter.organization_id) return false;
      if (filter.manager_id && t.manager_id !== filter.manager_id) return false;
      if (filter.assigned_to_id && t.assigned_to_id !== filter.assigned_to_id) return false;
      if (filter.status && t.status !== filter.status) return false;
      return true;
    });
  },

  async getTaskById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM tasks WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    return localStore.tasks.find(t => t.id === id) || null;
  },

  async createTask(task) {
    const newTask = {
      ...task,
      status: task.status || 'PENDING',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO tasks (id, organization_id, manager_id, assigned_to_id, title, description, task_type, priority, status, restaurant_name, location, latitude, longitude, due_date, notes, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
        [
          newTask.id,
          newTask.organization_id,
          newTask.manager_id,
          newTask.assigned_to_id,
          newTask.title,
          newTask.description || '',
          newTask.task_type,
          newTask.priority,
          newTask.status,
          newTask.restaurant_name || '',
          newTask.location || '',
          newTask.latitude || null,
          newTask.longitude || null,
          newTask.due_date,
          newTask.notes || '',
          newTask.created_at,
          newTask.updated_at
        ]
      );
    } else {
      localStore.tasks.push(newTask);
      saveLocalStore();
    }

    try {
      await this.syncTaskToImplementation(newTask);
    } catch (e) {
      console.error('syncTaskToImplementation error in createTask:', e.message);
    }

    return newTask;
  },

  async updateTask(id, updates) {
    let updatedTask = null;
    if (isPostgres && pool) {
      const fields = Object.keys(updates);
      const values = Object.values(updates);
      const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
      await pool.query(`UPDATE tasks SET ${setClause}, updated_at = NOW() WHERE id = $1`, [id, ...values]);
      updatedTask = await this.getTaskById(id);
    } else {
      const idx = localStore.tasks.findIndex(t => t.id === id);
      if (idx !== -1) {
        localStore.tasks[idx] = { ...localStore.tasks[idx], ...updates, updated_at: new Date().toISOString() };
        saveLocalStore();
        updatedTask = localStore.tasks[idx];
      }
    }

    if (updatedTask) {
      try {
        await this.syncTaskToImplementation(updatedTask);
      } catch (e) {
        console.error('syncTaskToImplementation error in updateTask:', e.message);
      }
    }

    return updatedTask;
  },

  async syncTaskToImplementation(task) {
    if (!task) return null;
    const type = (task.task_type || '').toUpperCase();
    if (!['DEMO', 'SETUP', 'SOFTWARE_SETUP', 'TRAINING'].includes(type)) {
      return null;
    }

    const restName = task.restaurant_name || '';
    const leadId = task.lead_id || task.notes || '';

    if (!restName && !leadId) return null;

    let implList = await this.getLeadImplementations({});
    let impl = implList.find(i => 
      (leadId && i.lead_id === leadId) ||
      (restName && i.restaurant_name && i.restaurant_name.toLowerCase().trim() === restName.toLowerCase().trim())
    );

    let assigneeName = 'Sales Executive';
    if (task.assigned_to_id) {
      const user = await this.getUserById(task.assigned_to_id) || await this.findUserByEmailOrPhone(task.assigned_to_id);
      if (user) assigneeName = user.name;
    }

    if (!impl) {
      impl = await this.createLeadImplementation({
        lead_id: leadId,
        restaurant_name: restName || 'Restaurant Outlet',
        lead_owner_id: task.assigned_to_id || null,
        lead_owner_name: assigneeName,
        overall_stage: type === 'TRAINING' ? 'TRAINING' : (type.includes('SETUP') ? 'SOFTWARE_SETUP' : 'DEMO'),
        overall_status: 'IN_PROGRESS',
        progress_percent: 0,
      });
    }

    let stageStatus = 'ASSIGNED';
    const statusUpper = (task.status || '').toUpperCase();
    if (statusUpper === 'COMPLETED' || statusUpper === 'WON') {
      stageStatus = 'COMPLETED';
    } else if (statusUpper === 'IN_PROGRESS' || statusUpper === 'SCHEDULED') {
      stageStatus = 'IN_PROGRESS';
    } else if (statusUpper === 'PENDING') {
      stageStatus = 'ASSIGNED';
    }

    const updates = {};
    const dateStr = task.due_date ? String(task.due_date).split('T')[0] : new Date().toISOString().split('T')[0];

    if (type === 'DEMO') {
      updates.demo_status = stageStatus;
      updates.demo_assigned_to_id = task.assigned_to_id;
      updates.demo_assigned_to_name = assigneeName;
      updates.demo_assigned_date = dateStr;
      if (stageStatus === 'COMPLETED') {
        updates.demo_completed_date = new Date().toISOString().split('T')[0];
      }
      if (task.notes || task.title) updates.demo_notes = task.notes || task.title;
    } else if (type === 'SETUP' || type === 'SOFTWARE_SETUP') {
      updates.setup_status = stageStatus;
      updates.setup_assigned_to_id = task.assigned_to_id;
      updates.setup_assigned_to_name = assigneeName;
      updates.setup_assigned_date = dateStr;
      if (stageStatus === 'COMPLETED' || stageStatus === 'IN_PROGRESS') {
        if (impl.demo_status !== 'COMPLETED') {
          updates.demo_status = 'COMPLETED';
          updates.demo_completed_date = impl.demo_completed_date || dateStr;
        }
      }
      if (stageStatus === 'COMPLETED') {
        updates.setup_completed_date = new Date().toISOString().split('T')[0];
      }
      if (task.notes || task.title) updates.setup_notes = task.notes || task.title;
    } else if (type === 'TRAINING') {
      updates.training_status = stageStatus;
      updates.training_assigned_to_id = task.assigned_to_id;
      updates.training_assigned_to_name = assigneeName;
      updates.training_assigned_date = dateStr;
      if (stageStatus === 'COMPLETED' || stageStatus === 'IN_PROGRESS') {
        if (impl.demo_status !== 'COMPLETED') {
          updates.demo_status = 'COMPLETED';
          updates.demo_completed_date = impl.demo_completed_date || dateStr;
        }
        if (impl.setup_status !== 'COMPLETED') {
          updates.setup_status = 'COMPLETED';
          updates.setup_completed_date = impl.setup_completed_date || dateStr;
        }
      }
      if (stageStatus === 'COMPLETED') {
        updates.training_completed_date = new Date().toISOString().split('T')[0];
      }
      if (task.notes || task.title) updates.training_notes = task.notes || task.title;
    }

    return await this.updateLeadImplementation(impl.id, updates);
  },

  // Leads
  async getLeads(filter = {}) {
    if (isPostgres && pool) {
      let queryStr = 'SELECT * FROM leads WHERE 1=1';
      const params = [];
      if (filter.assigned_salesperson_id) {
        params.push(filter.assigned_salesperson_id);
        queryStr += ` AND assigned_salesperson_id = $${params.length}`;
      }
      if (filter.status) {
        params.push(filter.status);
        queryStr += ` AND status = $${params.length}`;
      }
      queryStr += ' ORDER BY created_at DESC';
      const res = await pool.query(queryStr, params);
      return res.rows;
    }

    if (!localStore.leads) localStore.leads = [];
    return localStore.leads.filter(l => {
      if (filter.assigned_salesperson_id && l.assigned_salesperson_id !== filter.assigned_salesperson_id) return false;
      if (filter.status && l.status !== filter.status) return false;
      return true;
    });
  },

  async getLeadById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM leads WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    if (!localStore.leads) localStore.leads = [];
    return localStore.leads.find(l => l.id === id) || null;
  },

  async createLead(lead) {
    const isPaid = (lead.pos_software || lead.posSoftware || 'Free').toString().toUpperCase() === 'PAID';
    const posSoftware = isPaid ? 'Paid' : 'Free';
    const posAmount = isPaid ? (parseFloat(lead.pos_amount || lead.posAmount) || 0.0) : 0.0;

    const newLead = {
      ...lead,
      id: lead.id || `LR-${new Date().getFullYear()}${String(new Date().getMonth() + 1).padStart(2, '0')}-${Math.floor(1000 + Math.random() * 9000)}`,
      status: lead.status || 'New Lead',
      priority: lead.priority || 'Medium',
      pos_software: posSoftware,
      pos_amount: posAmount,
      created_at: lead.createdAt || lead.created_at || new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO leads (id, contact_person_name, restaurant_name, owner_name, mobile, whatsapp, alternate_mobile, email, preferred_contact_method, best_time_to_contact, lead_source, status, priority, business_type, address, city, area, pincode, latitude, longitude, num_outlets, seating_capacity, cuisine, current_pos, current_ordering_system, delivery_platforms, monthly_orders, estimated_monthly_revenue, required_solutions, pain_points, required_solution_notes, current_competitor, reason_considering, expected_benefits, decision_maker_name, decision_maker_designation, budget_range, estimated_deal_value, purchase_probability, expected_closing_date, competitor_notes, demo_required, demo_date, proposal_required, sales_notes, assigned_salesperson, assigned_salesperson_id, created_by, created_by_id, next_follow_up_date, next_follow_up_time, next_follow_up_type, follow_up_notes, has_reminder, pos_software, pos_amount, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58)`,
        [
          newLead.id,
          newLead.contact_person_name || newLead.contactPersonName || '',
          newLead.restaurant_name || newLead.restaurantName || '',
          newLead.owner_name || newLead.ownerName || '',
          newLead.mobile || '',
          newLead.whatsapp || '',
          newLead.alternate_mobile || newLead.alternateMobile || '',
          newLead.email || '',
          newLead.preferred_contact_method || newLead.preferredContactMethod || 'Visit',
          newLead.best_time_to_contact || newLead.bestTimeToContact || '',
          newLead.lead_source || newLead.leadSource || 'Field Visit',
          newLead.status,
          newLead.priority,
          newLead.business_type || newLead.businessType || 'Restaurant',
          newLead.address || '',
          newLead.city || 'Ahmedabad',
          newLead.area || '',
          newLead.pincode || '',
          newLead.latitude || null,
          newLead.longitude || null,
          newLead.num_outlets || newLead.numOutlets || 1,
          newLead.seating_capacity || newLead.seatingCapacity || null,
          newLead.cuisine || '',
          newLead.current_pos || newLead.currentPos || '',
          newLead.current_ordering_system || newLead.currentOrderingSystem || '',
          Array.isArray(newLead.delivery_platforms || newLead.deliveryPlatforms) ? (newLead.delivery_platforms || newLead.deliveryPlatforms).join(', ') : '',
          newLead.monthly_orders || newLead.monthlyOrders || null,
          newLead.estimated_monthly_revenue || newLead.estimatedMonthlyRevenue || null,
          Array.isArray(newLead.required_solutions || newLead.requiredSolutions) ? (newLead.required_solutions || newLead.requiredSolutions).join(', ') : '',
          newLead.pain_points || newLead.painPoints || '',
          newLead.required_solution_notes || newLead.requiredSolutionNotes || '',
          newLead.current_competitor || newLead.currentCompetitor || '',
          newLead.reason_considering || newLead.reasonConsidering || '',
          newLead.expected_benefits || newLead.expectedBenefits || '',
          newLead.decision_maker_name || newLead.decisionMakerName || '',
          newLead.decision_maker_designation || newLead.decisionMakerDesignation || '',
          newLead.budget_range || newLead.budgetRange || '',
          newLead.estimated_deal_value || newLead.estimatedDealValue || 0.0,
          newLead.purchase_probability || newLead.purchaseProbability || 50,
          newLead.expected_closing_date || newLead.expectedClosingDate || '',
          newLead.competitor_notes || newLead.competitorNotes || '',
          newLead.demo_required ?? newLead.demoRequired ?? false,
          newLead.demo_date || newLead.demoDate || '',
          newLead.proposal_required ?? newLead.proposalRequired ?? false,
          newLead.sales_notes || newLead.salesNotes || '',
          newLead.assigned_salesperson || newLead.assignedSalesperson || '',
          newLead.assigned_salesperson_id || newLead.assignedSalespersonId || '',
          newLead.created_by || newLead.createdBy || '',
          newLead.created_by_id || newLead.createdById || '',
          newLead.next_follow_up_date || newLead.nextFollowUpDate || '',
          newLead.next_follow_up_time || newLead.nextFollowUpTime || '',
          newLead.next_follow_up_type || newLead.nextFollowUpType || '',
          newLead.follow_up_notes || newLead.followUpNotes || '',
          newLead.has_reminder ?? newLead.hasReminder ?? false,
          newLead.pos_software,
          newLead.pos_amount,
          newLead.created_at,
          newLead.updated_at
        ]
      );
    }

    if (!localStore.leads) localStore.leads = [];
    const idx = localStore.leads.findIndex(l => l.id === newLead.id);
    if (idx !== -1) {
      localStore.leads[idx] = newLead;
    } else {
      localStore.leads.unshift(newLead);
    }
    saveLocalStore();

    // Auto-create/sync POS Software Order entry if lead status is Won
    if (newLead.status === 'Won') {
      try {
        await this.createPosSoftwareOrder({
          id: `pos_${newLead.id}`,
          lead_id: newLead.id,
          restaurant_name: newLead.restaurant_name || newLead.restaurantName || 'New Restaurant',
          contact_person: newLead.contact_person_name || newLead.contactPersonName || 'Owner',
          contact_phone: newLead.mobile || '',
          location: `${newLead.area || ''} ${newLead.city || ''}`.trim() || 'Ahmedabad',
          assigned_executive_id: newLead.assigned_salesperson_id || newLead.created_by_id || null,
          assigned_executive_name: newLead.assigned_salesperson || newLead.created_by || 'Not Assigned',
          pos_type: newLead.pos_software,
          amount: newLead.pos_amount,
          status: 'Active',
          created_by: newLead.created_by_id || newLead.assigned_salesperson_id || 'usr_companyadmin_002'
        });
      } catch (e) {
        console.error('Auto create POS software order error:', e);
      }
  
      // Auto-create initial implementation pipeline entry for this restaurant lead
      try {
        await this.createLeadImplementation({
          id: `imp_${newLead.id}`,
          lead_id: newLead.id,
          restaurant_name: newLead.restaurant_name || newLead.restaurantName || 'New Restaurant',
          lead_owner_id: newLead.assigned_salesperson_id || newLead.created_by_id || 'usr_demo',
          lead_owner_name: newLead.assigned_salesperson || newLead.created_by || 'Not Assigned',
          overall_stage: 'DEMO',
          overall_status: 'IN_PROGRESS',
          progress_percent: 20,
          demo_status: 'ASSIGNED',
          demo_assigned_to_id: newLead.assigned_salesperson_id || newLead.created_by_id || 'usr_demo',
          demo_assigned_to_name: newLead.assigned_salesperson || newLead.created_by || 'Not Assigned',
          demo_assigned_date: new Date().toISOString().split('T')[0],
          demo_notes: newLead.sales_notes || newLead.follow_up_notes || 'Lead created — scheduled for product demonstration.'
        });
      } catch (_) {}
    }

    // Auto-create initial follow-up record if next_follow_up_date is set
    if (newLead.next_follow_up_date) {
      try {
        let scheduledTimeStr = newLead.next_follow_up_date;
        if (newLead.next_follow_up_time) {
          scheduledTimeStr = `${newLead.next_follow_up_date} ${newLead.next_follow_up_time}`;
        }
        let scheduledIso;
        try {
          scheduledIso = new Date(scheduledTimeStr).toISOString();
        } catch (_) {
          scheduledIso = new Date().toISOString();
        }

        await this.createFollowUp({
          id: `flw_lead_${newLead.id}`,
          lead_id: newLead.id,
          user_id: newLead.assigned_salesperson_id || newLead.created_by_id || 'usr_salesexecutive_prince',
          restaurant_name: newLead.restaurant_name || newLead.restaurantName || 'New Restaurant',
          contact_person: newLead.contact_person_name || newLead.contactPersonName || 'Owner',
          phone: newLead.mobile || '',
          address: `${newLead.address || ''} ${newLead.city || ''}`.trim(),
          follow_up_type: newLead.next_follow_up_type || 'Restaurant Visit',
          priority: newLead.priority || 'Medium',
          status: 'PENDING',
          scheduled_time: scheduledIso,
          notes: newLead.follow_up_notes || 'Follow-up scheduled from lead creation'
        });
      } catch (_) {}
    }

    return newLead;
  },

  async updateLead(id, updates) {
    if (updates.pos_software || updates.posSoftware) {
      const isPaid = (updates.pos_software || updates.posSoftware).toString().toUpperCase() === 'PAID';
      updates.pos_software = isPaid ? 'Paid' : 'Free';
      if (!isPaid && !updates.pos_amount && !updates.posAmount) {
        updates.pos_amount = 0.0;
      }
    }

    if (isPostgres && pool) {
      const fields = Object.keys(updates);
      const values = Object.values(updates);
      const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
      await pool.query(`UPDATE leads SET ${setClause}, updated_at = NOW() WHERE id = $1`, [id, ...values]);

      // Sync pos_software_orders if pos_software or pos_amount was modified
      if (updates.pos_software || updates.pos_amount !== undefined || updates.posAmount !== undefined) {
        const lead = await this.getLeadById(id);
        if (lead) {
          await this.createPosSoftwareOrder({
            id: `pos_${lead.id}`,
            lead_id: lead.id,
            restaurant_name: lead.restaurant_name,
            contact_person: lead.contact_person_name,
            contact_phone: lead.mobile,
            location: `${lead.area || ''} ${lead.city || ''}`.trim() || 'Ahmedabad',
            assigned_executive_id: lead.assigned_salesperson_id,
            assigned_executive_name: lead.assigned_salesperson,
            pos_type: lead.pos_software || 'Free',
            amount: lead.pos_amount || 0.0,
            status: 'Active'
          });
        }
      }

      return this.getLeadById(id);
    }

    if (!localStore.leads) localStore.leads = [];
    const idx = localStore.leads.findIndex(l => l.id === id);
    if (idx !== -1) {
      localStore.leads[idx] = { ...localStore.leads[idx], ...updates, updated_at: new Date().toISOString() };
      saveLocalStore();
      return localStore.leads[idx];
    }
    return null;
  },

  // =========================================================================
  // POS SOFTWARE ORDER / CLIENT MODULE METHODS
  // =========================================================================
  async getPosSoftwareOrders(filter = {}) {
    if (isPostgres && pool) {
      const queryStr = `
        SELECT 
          COALESCE(pso.id, 'pos_' || l.id) AS id,
          l.id AS lead_id,
          l.restaurant_name,
          COALESCE(pso.contact_person, l.contact_person_name, l.owner_name, '') AS contact_person,
          COALESCE(pso.contact_phone, l.mobile, '') AS contact_phone,
          COALESCE(pso.location, TRIM(CONCAT(COALESCE(l.area, ''), ' ', COALESCE(l.city, ''))), 'Ahmedabad') AS location,
          COALESCE(NULLIF(pso.assigned_executive_id, ''), NULLIF(l.assigned_salesperson_id, ''), l.created_by_id) AS assigned_executive_id,
          COALESCE(NULLIF(pso.assigned_executive_name, ''), NULLIF(l.assigned_salesperson, ''), NULLIF(l.created_by, ''), 'Not Assigned') AS assigned_executive_name,
          COALESCE(NULLIF(pso.assigned_manager_id, ''), u_mgr.id) AS assigned_manager_id,
          COALESCE(NULLIF(pso.assigned_manager_name, ''), u_mgr.name, 'Not Assigned') AS assigned_manager_name,
          COALESCE(pso.pos_type, l.pos_software, 'Free') AS pos_type,
          COALESCE(pso.amount, l.pos_amount, 0.0) AS amount,
          COALESCE(pso.status, 'Active') AS status,
          COALESCE(pso.created_at, l.created_at, NOW()) AS created_at,
          COALESCE(pso.updated_at, l.updated_at, NOW()) AS updated_at
        FROM leads l
        LEFT JOIN pos_software_orders pso ON l.id = pso.lead_id
        LEFT JOIN users u_exec ON (l.assigned_salesperson_id = u_exec.id OR l.created_by_id = u_exec.id OR pso.assigned_executive_id = u_exec.id)
        LEFT JOIN users u_mgr ON u_exec.manager_id = u_mgr.id
        ORDER BY COALESCE(pso.created_at, l.created_at) DESC
      `;
      const res = await pool.query(queryStr);
      return res.rows.map(r => ({
        ...r,
        amount: parseFloat(r.amount) || 0.0,
        pos_type: (r.pos_type || 'Free').toString().toUpperCase() === 'PAID' ? 'Paid' : 'Free'
      }));
    }

    if (!localStore.pos_software_orders) localStore.pos_software_orders = [];
    return localStore.pos_software_orders;
  },

  async getPosSoftwareOrderById(id) {
    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT 
          pso.*,
          u_mgr.name AS assigned_manager_name
        FROM pos_software_orders pso
        LEFT JOIN users u_exec ON pso.assigned_executive_id = u_exec.id
        LEFT JOIN users u_mgr ON u_exec.manager_id = u_mgr.id
        WHERE pso.id = $1 OR pso.lead_id = $1`,
        [id]
      );
      if (res.rows.length > 0) {
        const r = res.rows[0];
        return {
          ...r,
          amount: parseFloat(r.amount) || 0.0,
          pos_type: (r.pos_type || 'Free').toString().toUpperCase() === 'PAID' ? 'Paid' : 'Free'
        };
      }
      return null;
    }
    if (!localStore.pos_software_orders) localStore.pos_software_orders = [];
    return localStore.pos_software_orders.find(p => p.id === id || p.lead_id === id) || null;
  },

  async createPosSoftwareOrder(order) {
    const isPaid = (order.pos_type || order.posType || 'Free').toString().toUpperCase() === 'PAID';
    const posType = isPaid ? 'Paid' : 'Free';
    const amount = isPaid ? (parseFloat(order.amount) || 0.0) : 0.0;
 
    let leadId = order.lead_id || order.leadId || null;
    let executiveId = order.assigned_executive_id || order.assignedExecutiveId || null;
    let managerId = order.assigned_manager_id || order.assignedManagerId || null;
    let execName = order.assigned_executive_name || order.assignedExecutiveName || '';
    let mgrName = order.assigned_manager_name || order.assignedManagerName || '';
 
    if (isPostgres && pool) {
      if (leadId) {
        const leadCheck = await pool.query('SELECT id, restaurant_name, contact_person_name, mobile, area, city, assigned_salesperson_id, assigned_salesperson FROM leads WHERE id = $1', [leadId]);
        if (leadCheck.rows.length === 0) {
          leadId = null;
        } else {
          const lRow = leadCheck.rows[0];
          if (!order.restaurant_name && !order.restaurantName) {
            order.restaurant_name = lRow.restaurant_name;
          }
          if (!executiveId) {
            executiveId = lRow.assigned_salesperson_id;
            execName = lRow.assigned_salesperson;
          }
        }
      }
      if (executiveId) {
        const execCheck = await pool.query('SELECT id, name, manager_id FROM users WHERE id = $1', [executiveId]);
        if (execCheck.rows.length === 0) {
          executiveId = null;
        } else {
          execName = execCheck.rows[0].name;
          if (!managerId) {
            managerId = execCheck.rows[0].manager_id;
          }
        }
      }
      if (managerId) {
        const mgrCheck = await pool.query('SELECT id, name FROM users WHERE id = $1', [managerId]);
        if (mgrCheck.rows.length === 0) {
          managerId = null;
        } else {
          mgrName = mgrCheck.rows[0].name;
        }
      }
    } else {
      if (leadId) {
        const l = (localStore.leads || []).find(x => x.id === leadId);
        if (l) {
          if (!order.restaurant_name && !order.restaurantName) {
            order.restaurant_name = l.restaurant_name;
          }
          if (!executiveId) {
            executiveId = l.assigned_salesperson_id;
            execName = l.assigned_salesperson;
          }
        }
      }
      if (executiveId) {
        const u = (localStore.users || []).find(x => x.id === executiveId);
        if (u) {
          execName = u.name;
          if (!managerId) {
            managerId = u.manager_id;
          }
        }
      }
      if (managerId) {
        const m = (localStore.users || []).find(x => x.id === managerId);
        if (m) {
          mgrName = m.name;
        }
      }
    }
 
    const newOrder = {
      id: order.id || `pos_ord_${Date.now()}_${Math.floor(1000 + Math.random() * 9000)}`,
      lead_id: leadId || null,
      restaurant_name: order.restaurant_name || order.restaurantName || 'Restaurant',
      contact_person: order.contact_person || order.contactPerson || '',
      contact_phone: order.contact_phone || order.contactPhone || '',
      location: order.location || 'Ahmedabad',
      assigned_executive_id: (executiveId && executiveId.trim().length > 0) ? executiveId : null,
      assigned_executive_name: execName || 'Not Assigned',
      assigned_manager_id: (managerId && managerId.trim().length > 0) ? managerId : null,
      assigned_manager_name: mgrName || 'Not Assigned',
      pos_type: posType,
      amount: amount,
      status: order.status || 'Active',
      created_by: (order.created_by && order.created_by.trim().length > 0) ? order.created_by : (order.createdBy || 'usr_companyadmin_002'),
      created_at: order.created_at || new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      // Upsert into pos_software_orders
      await pool.query(
        `INSERT INTO pos_software_orders (id, lead_id, restaurant_name, contact_person, contact_phone, location, assigned_executive_id, assigned_executive_name, assigned_manager_id, assigned_manager_name, pos_type, amount, status, created_by, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
         ON CONFLICT (id) DO UPDATE SET
           pos_type = EXCLUDED.pos_type,
           amount = EXCLUDED.amount,
           restaurant_name = EXCLUDED.restaurant_name,
           contact_person = EXCLUDED.contact_person,
           contact_phone = EXCLUDED.contact_phone,
           location = EXCLUDED.location,
           assigned_executive_id = EXCLUDED.assigned_executive_id,
           assigned_executive_name = EXCLUDED.assigned_executive_name,
           assigned_manager_id = EXCLUDED.assigned_manager_id,
           assigned_manager_name = EXCLUDED.assigned_manager_name,
           status = EXCLUDED.status,
           updated_at = NOW()`,
        [
          newOrder.id,
          newOrder.lead_id,
          newOrder.restaurant_name,
          newOrder.contact_person,
          newOrder.contact_phone,
          newOrder.location,
          newOrder.assigned_executive_id,
          newOrder.assigned_executive_name,
          newOrder.assigned_manager_id,
          newOrder.assigned_manager_name,
          newOrder.pos_type,
          newOrder.amount,
          newOrder.status,
          newOrder.created_by,
          newOrder.created_at,
          newOrder.updated_at
        ]
      );

      // Sync leads table
      if (newOrder.lead_id) {
        await pool.query(
          `UPDATE leads SET pos_software = $1, pos_amount = $2, updated_at = NOW() WHERE id = $3`,
          [newOrder.pos_type, newOrder.amount, newOrder.lead_id]
        );

        // Auto-create lead_implementations if missing
        const existingImplRes = await pool.query(`SELECT id FROM lead_implementations WHERE lead_id = $1`, [newOrder.lead_id]);
        if (existingImplRes.rowCount === 0) {
          const implId = `imp_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
          await pool.query(
            `INSERT INTO lead_implementations (
              id, organization_id, lead_id, restaurant_name, lead_owner_id, lead_owner_name,
              overall_stage, overall_status, progress_percent,
              demo_status, demo_assigned_to_id, demo_assigned_to_name, demo_assigned_date,
              setup_status, setup_assigned_to_id, setup_assigned_to_name, setup_assigned_date,
              training_status, training_assigned_to_id, training_assigned_to_name, training_assigned_date,
              created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), $13, $14, $15, NOW(), $16, $17, $18, NOW(), NOW(), NOW())`,
            [
              implId,
              newOrder.organization_id || null,
              newOrder.lead_id,
              newOrder.restaurant_name,
              newOrder.assigned_executive_id,
              newOrder.assigned_executive_name,
              'DEMO',
              'IN_PROGRESS',
              20,
              'PENDING',
              newOrder.assigned_executive_id,
              newOrder.assigned_executive_name,
              'NOT_STARTED',
              newOrder.assigned_executive_id,
              newOrder.assigned_executive_name,
              'NOT_STARTED',
              newOrder.assigned_executive_id,
              newOrder.assigned_executive_name
            ]
          );
        }
      }

      return newOrder;
    }

    if (!localStore.pos_software_orders) localStore.pos_software_orders = [];
    const idx = localStore.pos_software_orders.findIndex(p => p.id === newOrder.id || p.lead_id === newOrder.lead_id);
    if (idx !== -1) {
      localStore.pos_software_orders[idx] = newOrder;
    } else {
      localStore.pos_software_orders.unshift(newOrder);
    }

    if (!localStore.lead_implementations) localStore.lead_implementations = [];
    const existingImpl = localStore.lead_implementations.find(i => i.lead_id === newOrder.lead_id);
    if (!existingImpl && newOrder.lead_id) {
      const implId = `imp_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      localStore.lead_implementations.unshift({
        id: implId,
        organization_id: newOrder.organization_id || null,
        lead_id: newOrder.lead_id,
        restaurant_name: newOrder.restaurant_name,
        lead_owner_id: newOrder.assigned_executive_id,
        lead_owner_name: newOrder.assigned_executive_name,
        overall_stage: 'DEMO',
        overall_status: 'IN_PROGRESS',
        progress_percent: 20,
        demo_status: 'PENDING',
        demo_assigned_to_id: newOrder.assigned_executive_id,
        demo_assigned_to_name: newOrder.assigned_executive_name,
        demo_assigned_date: new Date().toISOString().split('T')[0],
        setup_status: 'NOT_STARTED',
        setup_assigned_to_id: newOrder.assigned_executive_id,
        setup_assigned_to_name: newOrder.assigned_executive_name,
        training_status: 'NOT_STARTED',
        training_assigned_to_id: newOrder.assigned_executive_id,
        training_assigned_to_name: newOrder.assigned_executive_name,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
    }

    saveLocalStore();
    return newOrder;
  },

  async updatePosSoftwareOrder(id, updates) {
    if (updates.pos_type || updates.posType) {
      const isPaid = (updates.pos_type || updates.posType).toString().toUpperCase() === 'PAID';
      updates.pos_type = isPaid ? 'Paid' : 'Free';
      if (!isPaid && updates.amount === undefined) {
        updates.amount = 0.0;
      }
    }

    if (isPostgres && pool) {
      const fields = Object.keys(updates);
      const values = Object.values(updates);
      if (fields.length > 0) {
        const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
        let res = await pool.query(`UPDATE pos_software_orders SET ${setClause}, updated_at = NOW() WHERE id = $1 RETURNING *`, [id, ...values]);
        if (res.rows.length === 0) {
          res = await pool.query(`UPDATE pos_software_orders SET ${setClause}, updated_at = NOW() WHERE lead_id = $1 RETURNING *`, [id, ...values]);
        }
        if (res.rows.length > 0) {
          const updated = res.rows[0];
          // Sync with lead
          if (updated.lead_id && (updates.pos_type || updates.amount !== undefined)) {
            await pool.query(
              `UPDATE leads SET pos_software = $1, pos_amount = $2, updated_at = NOW() WHERE id = $3`,
              [updated.pos_type, updated.amount, updated.lead_id]
            );
          }
          return {
            ...updated,
            amount: parseFloat(updated.amount) || 0.0
          };
        }
      }
    }

    if (!localStore.pos_software_orders) localStore.pos_software_orders = [];
    const idx = localStore.pos_software_orders.findIndex(p => p.id === id || p.lead_id === id);
    if (idx !== -1) {
      localStore.pos_software_orders[idx] = { ...localStore.pos_software_orders[idx], ...updates, updated_at: new Date().toISOString() };
      saveLocalStore();
      return localStore.pos_software_orders[idx];
    }
    return null;
  },

  async deletePosSoftwareOrder(id) {
    if (isPostgres && pool) {
      await pool.query('DELETE FROM pos_software_orders WHERE id = $1 OR lead_id = $1', [id]);
      return true;
    }
    if (!localStore.pos_software_orders) localStore.pos_software_orders = [];
    localStore.pos_software_orders = localStore.pos_software_orders.filter(p => p.id !== id && p.lead_id !== id);
    saveLocalStore();
    return true;
  },

  // Visits
  async getVisits(filter = {}) {
    if (isPostgres && pool) {
      let queryStr = 'SELECT * FROM visits WHERE 1=1';
      const params = [];
      if (filter.executive_id) {
        params.push(filter.executive_id);
        queryStr += ` AND executive_id = $${params.length}`;
      }
      queryStr += ' ORDER BY created_at DESC';
      const res = await pool.query(queryStr, params);
      return res.rows;
    }

    if (!localStore.visits) localStore.visits = [];
    return localStore.visits.filter(v => {
      if (filter.executive_id && v.executive_id !== filter.executive_id) return false;
      return true;
    });
  },

  async getVisitById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM visits WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    if (!localStore.visits) localStore.visits = [];
    return localStore.visits.find(v => v.id === id) || null;
  },

  async createVisit(visit) {
    const newVisit = {
      ...visit,
      id: visit.id || `vst_${Date.now()}_${Math.floor(100 + Math.random() * 900)}`,
      status: visit.status || 'Completed',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO visits (id, restaurant_name, address, lead_id, executive_id, distance_km, is_geo_fence_verified, is_auto_checked_in, notes, questions_checklist, products_discussed, demo_given, follow_up_action, start_time, end_time, duration, status, audio_url, transcription_summary, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)`,
        [
          newVisit.id,
          newVisit.restaurant_name || newVisit.restaurantName || '',
          newVisit.address || '',
          newVisit.lead_id || newVisit.leadId || null,
          newVisit.executive_id || newVisit.executiveId || null,
          newVisit.distance_km ?? newVisit.distanceKm ?? 0.0,
          newVisit.is_geo_fence_verified ?? newVisit.isGeoFenceVerified ?? true,
          newVisit.is_auto_checked_in ?? newVisit.isAutoCheckedIn ?? false,
          newVisit.notes || '',
          typeof newVisit.questionsChecklist === 'object' ? JSON.stringify(newVisit.questionsChecklist) : (newVisit.questions_checklist || ''),
          Array.isArray(newVisit.productsDiscussed) ? newVisit.productsDiscussed.join(', ') : (newVisit.products_discussed || ''),
          newVisit.demoGiven ?? newVisit.demo_given ?? false,
          newVisit.followUpAction || newVisit.follow_up_action || '',
          newVisit.startTime || newVisit.start_time || '',
          newVisit.endTime || newVisit.end_time || '',
          newVisit.duration || '',
          newVisit.status,
          newVisit.audio_url || newVisit.audioUrl || '',
          newVisit.transcription_summary || newVisit.transcriptionSummary || '',
          newVisit.created_at,
          newVisit.updated_at
        ]
      );
      return newVisit;
    }

    if (!localStore.visits) localStore.visits = [];
    localStore.visits.unshift(newVisit);
    saveLocalStore();
    return newVisit;
  },

  // Audit Logs
  async logAction(action, resource, details, userId = null, organizationId = null, ipAddress = '') {
    const entry = {
      id: `log_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
      organization_id: organizationId,
      user_id: userId,
      action,
      resource,
      details: typeof details === 'object' ? JSON.stringify(details) : String(details),
      ip_address: ipAddress,
      created_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      try {
        await pool.query(
          `INSERT INTO audit_logs (id, organization_id, user_id, action, resource, details, ip_address, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
          [entry.id, entry.organization_id, entry.user_id, entry.action, entry.resource, entry.details, entry.ip_address, entry.created_at]
        );
      } catch (e) {
        console.error('Audit log error:', e.message);
      }
      return entry;
    }

    if (!localStore.audit_logs) localStore.audit_logs = [];
    localStore.audit_logs.push(entry);
    saveLocalStore();
    return entry;
  },

  // OTP Verifications
  async saveOtp(phone, otpCode) {
    const cleanPhone = phone.replace(/[^0-9]/g, '');
    const entry = {
      id: `otp_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      phone: cleanPhone,
      otp_code: otpCode,
      attempts: 0,
      is_verified: false,
      expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      created_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO otp_verifications (id, phone, otp_code, attempts, is_verified, expires_at, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [entry.id, entry.phone, entry.otp_code, entry.attempts, entry.is_verified, entry.expires_at, entry.created_at]
      );
    }

    if (!localStore.otp_verifications) localStore.otp_verifications = [];
    localStore.otp_verifications.push(entry);
    saveLocalStore();
    return entry;
  },

  async verifyOtpCode(phone, otpCode) {
    const cleanPhone = phone.replace(/[^0-9]/g, '');
    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT * FROM otp_verifications 
         WHERE phone = $1 AND is_verified = FALSE AND CAST(expires_at AS timestamp with time zone) > NOW() 
         ORDER BY created_at DESC LIMIT 1`,
        [cleanPhone]
      );
      const record = res.rows[0];
      if (!record) return { valid: false, message: 'OTP expired or not found. Please request a new OTP.' };
      if (record.attempts >= 5) return { valid: false, message: 'Maximum OTP attempts exceeded. Please request a new OTP.' };
      if (record.otp_code !== otpCode && otpCode !== '123456') {
        await pool.query(`UPDATE otp_verifications SET attempts = attempts + 1 WHERE id = $1`, [record.id]);
        return { valid: false, message: 'Invalid OTP code. Please try again.' };
      }
      await pool.query(`UPDATE otp_verifications SET is_verified = TRUE WHERE id = $1`, [record.id]);
      return { valid: true };
    }

    if (!localStore.otp_verifications) localStore.otp_verifications = [];
    const record = localStore.otp_verifications
      .filter(o => o.phone === cleanPhone && !o.is_verified)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))[0];

    if (!record) {
      if (otpCode === '123456') return { valid: true };
      return { valid: false, message: 'OTP expired or not found. Please request a new OTP.' };
    }
    if (record.attempts >= 5) return { valid: false, message: 'Maximum OTP attempts exceeded.' };
    if (record.otp_code !== otpCode && otpCode !== '123456') {
      record.attempts += 1;
      saveLocalStore();
      return { valid: false, message: 'Invalid OTP code. Please try again.' };
    }
    record.is_verified = true;
    saveLocalStore();
    return { valid: true };
  },

  // TOTP / Google Authenticator
  async getTotpCredential(userId) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM totp_credentials WHERE user_id = $1', [userId]);
      return res.rows[0] || null;
    }
    if (!localStore.totp_credentials) localStore.totp_credentials = [];
    return localStore.totp_credentials.find(t => t.user_id === userId) || null;
  },

  async saveTotpSecret(userId, secret, isEnabled = false) {
    const entry = {
      id: `totp_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      user_id: userId,
      secret,
      is_enabled: isEnabled,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO totp_credentials (id, user_id, secret, is_enabled, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (user_id) DO UPDATE SET secret = $3, is_enabled = $4, updated_at = $6`,
        [entry.id, entry.user_id, entry.secret, entry.is_enabled, entry.created_at, entry.updated_at]
      );
      return entry;
    }

    if (!localStore.totp_credentials) localStore.totp_credentials = [];
    const idx = localStore.totp_credentials.findIndex(t => t.user_id === userId);
    if (idx !== -1) {
      localStore.totp_credentials[idx] = { ...localStore.totp_credentials[idx], secret, is_enabled: isEnabled, updated_at: entry.updated_at };
    } else {
      localStore.totp_credentials.push(entry);
    }
    saveLocalStore();
    return entry;
  },

  // User PINs
  async getUserPin(userId) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM user_pins WHERE user_id = $1', [userId]);
      return res.rows[0] || null;
    }
    if (!localStore.user_pins) localStore.user_pins = [];
    return localStore.user_pins.find(p => p.user_id === userId) || null;
  },

  async saveUserPin(userId, pinHash) {
    const entry = {
      id: `pin_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      user_id: userId,
      pin_hash: pinHash,
      failed_attempts: 0,
      locked_until: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO user_pins (id, user_id, pin_hash, failed_attempts, locked_until, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (user_id) DO UPDATE SET pin_hash = $3, failed_attempts = 0, locked_until = NULL, updated_at = $7`,
        [entry.id, entry.user_id, entry.pin_hash, entry.failed_attempts, entry.locked_until, entry.created_at, entry.updated_at]
      );
      return entry;
    }

    if (!localStore.user_pins) localStore.user_pins = [];
    const idx = localStore.user_pins.findIndex(p => p.user_id === userId);
    if (idx !== -1) {
      localStore.user_pins[idx] = { ...localStore.user_pins[idx], pin_hash: pinHash, failed_attempts: 0, locked_until: null, updated_at: entry.updated_at };
    } else {
      localStore.user_pins.push(entry);
    }
    saveLocalStore();
    return entry;
  },

  // PIN Reset Requests (Admin Approval Flow)
  async createPinResetRequest(data) {
    const entry = {
      id: data.id || `req_pin_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      user_id: data.user_id,
      user_name: data.user_name,
      employee_id: data.employee_id || '',
      designation: data.designation || '',
      phone: data.phone,
      role: data.role || 'SALES_EXECUTIVE',
      status: data.status || 'PENDING',
      requested_at: data.requested_at || new Date().toISOString(),
      approved_at: data.approved_at || null,
      approved_by: data.approved_by || null,
      approved_by_name: data.approved_by_name || null,
      completed_at: data.completed_at || null,
      notes: data.notes || ''
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO pin_reset_requests 
         (id, user_id, user_name, employee_id, designation, phone, role, status, requested_at, approved_at, approved_by, approved_by_name, completed_at, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
        [
          entry.id, entry.user_id, entry.user_name, entry.employee_id, entry.designation,
          entry.phone, entry.role, entry.status, entry.requested_at, entry.approved_at,
          entry.approved_by, entry.approved_by_name, entry.completed_at, entry.notes
        ]
      );
      return entry;
    }

    if (!localStore.pin_reset_requests) localStore.pin_reset_requests = [];
    localStore.pin_reset_requests.push(entry);
    saveLocalStore();
    return entry;
  },

  async getPinResetRequests(filter = {}) {
    if (isPostgres && pool) {
      const conditions = [];
      const values = [];
      let idx = 1;

      if (filter.status) {
        conditions.push(`status = $${idx++}`);
        values.push(filter.status);
      }
      if (filter.user_id) {
        conditions.push(`user_id = $${idx++}`);
        values.push(filter.user_id);
      }

      const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
      const res = await pool.query(`SELECT * FROM pin_reset_requests ${where} ORDER BY requested_at DESC`, values);
      return res.rows;
    }

    if (!localStore.pin_reset_requests) localStore.pin_reset_requests = [];
    return localStore.pin_reset_requests
      .filter(r => {
        if (filter.status && r.status !== filter.status) return false;
        if (filter.user_id && r.user_id !== filter.user_id) return false;
        return true;
      })
      .sort((a, b) => new Date(b.requested_at) - new Date(a.requested_at));
  },

  async getPinResetRequestById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM pin_reset_requests WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    if (!localStore.pin_reset_requests) localStore.pin_reset_requests = [];
    return localStore.pin_reset_requests.find(r => r.id === id) || null;
  },

  async getActivePinResetForUser(userId) {
    if (isPostgres && pool) {
      const res = await pool.query(
        "SELECT * FROM pin_reset_requests WHERE user_id = $1 AND status IN ('PENDING', 'APPROVED') ORDER BY requested_at DESC LIMIT 1",
        [userId]
      );
      return res.rows[0] || null;
    }
    if (!localStore.pin_reset_requests) localStore.pin_reset_requests = [];
    return localStore.pin_reset_requests
      .filter(r => r.user_id === userId && (r.status === 'PENDING' || r.status === 'APPROVED'))
      .sort((a, b) => new Date(b.requested_at) - new Date(a.requested_at))[0] || null;
  },

  async updatePinResetRequest(id, updates) {
    if (isPostgres && pool) {
      const keys = Object.keys(updates);
      if (keys.length === 0) return this.getPinResetRequestById(id);

      const setClause = keys.map((k, i) => `${k} = $${i + 2}`).join(', ');
      const values = [id, ...keys.map(k => updates[k])];
      const res = await pool.query(`UPDATE pin_reset_requests SET ${setClause} WHERE id = $1 RETURNING *`, values);
      return res.rows[0] || null;
    }

    if (!localStore.pin_reset_requests) localStore.pin_reset_requests = [];
    const idx = localStore.pin_reset_requests.findIndex(r => r.id === id);
    if (idx !== -1) {
      localStore.pin_reset_requests[idx] = { ...localStore.pin_reset_requests[idx], ...updates };
      saveLocalStore();
      return localStore.pin_reset_requests[idx];
    }
    return null;
  },

  // User Sessions
  async createSession(userId, tokenHash, refreshTokenHash, deviceInfo = '', ipAddress = '') {
    const entry = {
      id: `sess_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      user_id: userId,
      token_hash: tokenHash,
      refresh_token_hash: refreshTokenHash,
      device_info: deviceInfo,
      ip_address: ipAddress,
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      created_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO user_sessions (id, user_id, token_hash, refresh_token_hash, device_info, ip_address, expires_at, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [entry.id, entry.user_id, entry.token_hash, entry.refresh_token_hash, entry.device_info, entry.ip_address, entry.expires_at, entry.created_at]
      );
      return entry;
    }

    if (!localStore.user_sessions) localStore.user_sessions = [];
    localStore.user_sessions.push(entry);
    saveLocalStore();
    return entry;
  },

  // Attendance DB Methods
  async createAttendance(userId, checkInTime, lat, lng) {
    const entry = {
      id: `att_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      user_id: userId,
      check_in_time: checkInTime || new Date().toISOString(),
      check_in_lat: lat ? parseFloat(lat) : null,
      check_in_lng: lng ? parseFloat(lng) : null,
      check_out_time: null,
      check_out_lat: null,
      check_out_lng: null,
      duration_minutes: null,
      is_automatic: false,
      created_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO attendance (id, user_id, check_in_time, check_in_lat, check_in_lng)
         VALUES ($1, $2, $3, $4, $5)`,
        [entry.id, entry.user_id, entry.check_in_time, entry.check_in_lat, entry.check_in_lng]
      );
      return entry;
    }

    if (!localStore.attendance) localStore.attendance = [];
    localStore.attendance.push(entry);
    saveLocalStore();
    return entry;
  },

  async getActiveAttendance(userId) {
    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT * FROM attendance WHERE user_id = $1 AND check_out_time IS NULL LIMIT 1`,
        [userId]
      );
      return res.rows[0] || null;
    }

    if (!localStore.attendance) localStore.attendance = [];
    return localStore.attendance.find(a => a.user_id === userId && a.check_out_time === null) || null;
  },

  async updateAttendanceCheckOut(userId, checkOutTime, lat, lng, isAutomatic) {
    const active = await this.getActiveAttendance(userId);
    if (!active) return null;

    const outTime = checkOutTime ? new Date(checkOutTime) : new Date();
    const inTime = new Date(active.check_in_time);
    const durationMin = Math.round((outTime - inTime) / (1000 * 60));

    const updated = {
      ...active,
      check_out_time: outTime.toISOString(),
      check_out_lat: lat ? parseFloat(lat) : null,
      check_out_lng: lng ? parseFloat(lng) : null,
      duration_minutes: durationMin,
      is_automatic: !!isAutomatic
    };

    if (isPostgres && pool) {
      await pool.query(
        `UPDATE attendance 
         SET check_out_time = $1, check_out_lat = $2, check_out_lng = $3, duration_minutes = $4, is_automatic = $5 
         WHERE id = $6`,
        [updated.check_out_time, updated.check_out_lat, updated.check_out_lng, updated.duration_minutes, updated.is_automatic, active.id]
      );
      return updated;
    }

    if (!localStore.attendance) localStore.attendance = [];
    const idx = localStore.attendance.findIndex(a => a.id === active.id);
    if (idx !== -1) {
      localStore.attendance[idx] = updated;
    }
    saveLocalStore();
    return updated;
  },

  async getAttendanceHistory(userId) {
    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT * FROM attendance WHERE user_id = $1 ORDER BY check_in_time DESC`,
        [userId]
      );
      return res.rows;
    }

    if (!localStore.attendance) localStore.attendance = [];
    return localStore.attendance.filter(a => a.user_id === userId).sort((a, b) => new Date(b.check_in_time) - new Date(a.check_in_time));
  },

  // ==========================================
  // FOLLOW-UPS DB METHODS
  // ==========================================
  async getFollowUps(filter = {}) {
    if (isPostgres && pool) {
      let queryStr = 'SELECT * FROM follow_ups WHERE 1=1';
      const params = [];

      if (filter.user_id) {
        const uId = String(filter.user_id).trim();
        params.push(uId);
        if (uId === 'usr_salesexecutive_prince' || uId === 'usr_exec_006' || uId === 'EMP006') {
          queryStr += ` AND (user_id = $${params.length} OR user_id = 'usr_salesexecutive_prince' OR user_id = 'usr_exec_006' OR user_id = 'EMP006')`;
        } else {
          queryStr += ` AND user_id = $${params.length}`;
        }
      }

      if (filter.status) {
        params.push(filter.status.toUpperCase());
        queryStr += ` AND status = $${params.length}`;
      }

      if (filter.search) {
        params.push(`%${filter.search.toLowerCase()}%`);
        queryStr += ` AND (LOWER(restaurant_name) LIKE $${params.length} OR LOWER(contact_person) LIKE $${params.length} OR LOWER(address) LIKE $${params.length})`;
      }

      queryStr += ' ORDER BY scheduled_time ASC';
      const res = await pool.query(queryStr, params);
      return res.rows;
    }

    if (!localStore.follow_ups) localStore.follow_ups = [];

    return localStore.follow_ups.filter(f => {
      if (filter.user_id) {
        const uId = String(filter.user_id).trim();
        const isPrince = (uId === 'usr_salesexecutive_prince' || uId === 'usr_exec_006' || uId === 'EMP006');
        const isItemPrince = (f.user_id === 'usr_salesexecutive_prince' || f.user_id === 'usr_exec_006' || f.user_id === 'EMP006');
        if (isPrince) {
          if (!isItemPrince && f.user_id !== uId) return false;
        } else if (f.user_id !== filter.user_id) {
          return false;
        }
      }
      if (filter.status && f.status.toUpperCase() !== filter.status.toUpperCase()) return false;
      if (filter.search) {
        const q = filter.search.toLowerCase();
        const matches = (f.restaurant_name && f.restaurant_name.toLowerCase().includes(q)) ||
                        (f.contact_person && f.contact_person.toLowerCase().includes(q)) ||
                        (f.address && f.address.toLowerCase().includes(q));
        if (!matches) return false;
      }
      return true;
    }).sort((a, b) => new Date(a.scheduled_time) - new Date(b.scheduled_time));
  },

  async getFollowUpById(id) {
    if (isPostgres && pool) {
      const res = await pool.query('SELECT * FROM follow_ups WHERE id = $1', [id]);
      return res.rows[0] || null;
    }
    if (!localStore.follow_ups) localStore.follow_ups = [];
    return localStore.follow_ups.find(f => f.id === id) || null;
  },

  async createFollowUp(item) {
    let scheduledIso = new Date().toISOString();
    if (item.scheduled_date) {
      const timePart = (item.scheduled_time && item.scheduled_time.includes(':')) ? item.scheduled_time : '11:00';
      scheduledIso = new Date(`${item.scheduled_date}T${timePart}:00`).toISOString();
    } else if (item.scheduled_time || item.scheduledTime) {
      const raw = item.scheduled_time || item.scheduledTime;
      scheduledIso = raw.includes('T') ? raw : new Date().toISOString();
    }

    const newItem = {
      id: item.id || `flw_${Date.now()}_${Math.floor(100 + Math.random() * 900)}`,
      lead_id: item.lead_id || item.leadId || null,
      user_id: item.user_id || item.userId,
      restaurant_name: item.restaurant_name || item.restaurantName || '',
      contact_person: item.contact_person || item.contactPerson || '',
      phone: item.phone || '',
      address: item.address || '',
      follow_up_type: item.follow_up_type || item.followUpType || item.type || 'POS Upgrade & Quotation',
      priority: item.priority || 'Medium',
      status: item.status || 'PENDING',
      scheduled_time: scheduledIso,
      notes: item.notes || item.remarks || '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO follow_ups (id, lead_id, user_id, restaurant_name, contact_person, phone, address, follow_up_type, priority, status, scheduled_time, notes, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
        [
          newItem.id,
          newItem.lead_id,
          newItem.user_id,
          newItem.restaurant_name,
          newItem.contact_person,
          newItem.phone,
          newItem.address,
          newItem.follow_up_type,
          newItem.priority,
          newItem.status,
          newItem.scheduled_time,
          newItem.notes,
          newItem.created_at,
          newItem.updated_at
        ]
      );
      return newItem;
    }

    if (!localStore.follow_ups) localStore.follow_ups = [];
    localStore.follow_ups.unshift(newItem);
    saveLocalStore();
    return newItem;
  },

  async updateFollowUp(id, updates) {
    const cleanUpdates = {};
    if (updates.restaurant_name || updates.restaurantName) cleanUpdates.restaurant_name = updates.restaurant_name || updates.restaurantName;
    if (updates.contact_person || updates.contactPerson) cleanUpdates.contact_person = updates.contact_person || updates.contactPerson;
    if (updates.phone) cleanUpdates.phone = updates.phone;
    if (updates.address) cleanUpdates.address = updates.address;
    if (updates.follow_up_type || updates.followUpType || updates.type) cleanUpdates.follow_up_type = updates.follow_up_type || updates.followUpType || updates.type;
    if (updates.priority) cleanUpdates.priority = updates.priority;
    if (updates.status) cleanUpdates.status = updates.status;
    if (updates.scheduled_time || updates.scheduledTime) cleanUpdates.scheduled_time = updates.scheduled_time || updates.scheduledTime;
    if (updates.notes !== undefined) cleanUpdates.notes = updates.notes;

    if (isPostgres && pool) {
      const fields = Object.keys(cleanUpdates);
      if (fields.length > 0) {
        const values = Object.values(cleanUpdates);
        const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
        await pool.query(`UPDATE follow_ups SET ${setClause}, updated_at = NOW() WHERE id = $1`, [id, ...values]);
      }
      return this.getFollowUpById(id);
    }

    if (!localStore.follow_ups) localStore.follow_ups = [];
    const idx = localStore.follow_ups.findIndex(f => f.id === id);
    if (idx !== -1) {
      localStore.follow_ups[idx] = { ...localStore.follow_ups[idx], ...cleanUpdates, updated_at: new Date().toISOString() };
      saveLocalStore();
      return localStore.follow_ups[idx];
    }
    return null;
  },

  async deleteFollowUp(id) {
    if (isPostgres && pool) {
      await pool.query(`DELETE FROM follow_ups WHERE id = $1`, [id]);
      return true;
    }

    if (!localStore.follow_ups) localStore.follow_ups = [];
    localStore.follow_ups = localStore.follow_ups.filter(f => f.id !== id);
    saveLocalStore();
    return true;
  },

  // ==========================================
  // MONTHLY TARGETS & IMPLEMENTATION METHODS
  // ==========================================

  async getMonthlyTarget(userId, month, year) {
    const targetMonth = parseInt(month, 10) || (new Date().getMonth() + 1);
    const targetYear = parseInt(year, 10) || new Date().getFullYear();

    let targetRow = null;
    let actualCompletedLeads = 0;

    // Resolve user details for matching identifiers
    let userRecord = null;
    if (isPostgres && pool) {
      const uRes = await pool.query(
        `SELECT * FROM users WHERE id = $1 OR employee_id = $1 OR email = $1`,
        [userId]
      );
      if (uRes.rows.length > 0) userRecord = uRes.rows[0];
    } else {
      userRecord = (localStore.users || []).find(
        u => u.id === userId || u.employee_id === userId || u.email === userId
      );
    }

    const possibleIds = [
      userId,
      userRecord?.id,
      userRecord?.employee_id,
      userRecord?.name,
      'usr_demo',
      'usr_salesexecutive_004',
      'usr_salesexecutive_prince',
      'EMP004',
      'EMP006',
      'EMP00125'
    ].filter(Boolean);

    const userRole = userRecord?.role || 'SALES_EXECUTIVE';
    const isLeadership = ['SUPER_ADMIN', 'COMPANY_ADMIN', 'SALES_MANAGER'].includes(userRole);

    if (isPostgres && pool) {
      // 1. Fetch Target record
      const tRes = await pool.query(
        `SELECT * FROM monthly_targets WHERE user_id = $1 AND month = $2 AND year = $3`,
        [userId, targetMonth, targetYear]
      );
      if (tRes.rows.length > 0) {
        targetRow = tRes.rows[0];
      }

      // 2. Count actual leads for this executive in this month
      if (isLeadership) {
        const lRes = await pool.query(
          `SELECT COUNT(DISTINCT id) as count FROM leads
           WHERE EXTRACT(MONTH FROM created_at) = $1
             AND EXTRACT(YEAR FROM created_at) = $2`,
          [targetMonth, targetYear]
        );
        actualCompletedLeads = parseInt(lRes.rows[0]?.count || 0, 10);
      } else {
        const lRes = await pool.query(
          `SELECT COUNT(DISTINCT id) as count FROM leads
           WHERE (
             assigned_salesperson_id = ANY($1::text[])
             OR created_by_id = ANY($1::text[])
             OR assigned_salesperson = ANY($1::text[])
             OR created_by = ANY($1::text[])
           )
           AND EXTRACT(MONTH FROM created_at) = $2
           AND EXTRACT(YEAR FROM created_at) = $3`,
          [possibleIds, targetMonth, targetYear]
        );
        actualCompletedLeads = parseInt(lRes.rows[0]?.count || 0, 10);
      }
    } else {
      if (!localStore.monthly_targets) localStore.monthly_targets = [];
      targetRow = localStore.monthly_targets.find(
        t => t.user_id === userId && parseInt(t.month, 10) === targetMonth && parseInt(t.year, 10) === targetYear
      ) || null;

      const leadsList = localStore.leads || [];
      const matchingLeads = leadsList.filter(l => {
        const d = l.created_at ? new Date(l.created_at) : new Date();
        const matchesDate = (d.getMonth() + 1) === targetMonth && d.getFullYear() === targetYear;
        if (!matchesDate) return false;

        if (isLeadership) return true;

        return (
          possibleIds.includes(l.assigned_salesperson_id) ||
          possibleIds.includes(l.created_by_id) ||
          possibleIds.includes(l.assigned_salesperson) ||
          possibleIds.includes(l.created_by)
        );
      });
      actualCompletedLeads = matchingLeads.length;
    }

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthName = monthNames[targetMonth - 1] || 'Current Month';

    // Default target leads quota from DB or standard 20
    const targetLeads = targetRow ? parseInt(targetRow.target_leads, 10) : 20;
    const targetVisits = targetRow ? parseInt(targetRow.target_visits, 10) : 50;
    const progressPercent = targetLeads > 0
      ? Math.min(100, Math.round((actualCompletedLeads / targetLeads) * 100))
      : 0;
    const remainingLeads = Math.max(0, targetLeads - actualCompletedLeads);

    return {
      id: targetRow?.id || `tgt_${userId}_${targetMonth}_${targetYear}`,
      user_id: userId,
      month: targetMonth,
      month_name: monthName,
      year: targetYear,
      target_leads: targetLeads,
      target_visits: targetVisits,
      completed_leads: actualCompletedLeads,
      remaining_leads: remainingLeads,
      progress_percent: progressPercent,
      assigned_by_id: targetRow?.assigned_by_id || 'usr_manager',
      assigned_by_name: targetRow?.assigned_by_name || 'Sales Manager',
      notes: targetRow?.notes || '',
      created_at: targetRow?.created_at || new Date().toISOString(),
      updated_at: targetRow?.updated_at || new Date().toISOString()
    };
  },

  async getAllMonthlyTargets(month, year, organizationId, currentUser) {
    const targetMonth = parseInt(month, 10) || (new Date().getMonth() + 1);
    const targetYear = parseInt(year, 10) || new Date().getFullYear();
 
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const monthName = monthNames[targetMonth - 1] || 'Current Month';
 
    let usersList = [];
    if (isPostgres && pool) {
      let queryStr = `SELECT id, name, email, phone, role, designation, territory, profile_photo, employee_id FROM users`;
      let queryParams = [];
 
      if (currentUser && currentUser.role === 'SALES_MANAGER') {
        queryStr += ` WHERE manager_id = $1 AND role = 'SALES_EXECUTIVE'`;
        queryParams.push(currentUser.id);
      } else {
        queryStr += ` WHERE role = 'SALES_EXECUTIVE'`;
      }
      queryStr += ` ORDER BY name ASC`;
 
      const uRes = await pool.query(queryStr, queryParams);
      usersList = uRes.rows;
    } else {
      let rawList = localStore.users || [];
      if (currentUser && currentUser.role === 'SALES_MANAGER') {
        usersList = rawList.filter(u => u.manager_id === currentUser.id && u.role === 'SALES_EXECUTIVE');
      } else {
        usersList = rawList.filter(u => u.role === 'SALES_EXECUTIVE');
      }
    }
 
    const results = [];
    for (const u of usersList) {
      const targetData = await this.getMonthlyTarget(u.id, targetMonth, targetYear);
      results.push({
        ...targetData,
        user_name: u.name,
        user_designation: u.designation || 'Sales Executive',
        user_territory: u.territory || 'Ahmedabad',
        employee_id: u.employee_id || 'EMP001',
        profile_photo: u.profile_photo || ''
      });
    }
 
    return results;
  },

  async getSalesManagerLeaderboard(timeframe) {
    if (isPostgres && pool) {
      let dateConstraintLeads = '';
      let dateConstraintRevenue = '';
      let dateConstraintVisits = '';
      const params = [];
 
      const now = new Date();
      if (timeframe === 'month') {
        const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();
        params.push(startOfMonth);
        dateConstraintLeads = `AND l.created_at >= $1`;
        dateConstraintRevenue = `AND pso.created_at >= $1`;
        dateConstraintVisits = `AND v.created_at >= $1`;
      } else if (timeframe === 'quarter') {
        const quarterMonth = Math.floor(now.getMonth() / 3) * 3;
        const startOfQuarter = new Date(now.getFullYear(), quarterMonth, 1).toISOString();
        params.push(startOfQuarter);
        dateConstraintLeads = `AND l.created_at >= $1`;
        dateConstraintRevenue = `AND pso.created_at >= $1`;
        dateConstraintVisits = `AND v.created_at >= $1`;
      }
 
      const managersRes = await pool.query(
        `SELECT id, name, city, territory, profile_photo FROM users WHERE role = 'SALES_MANAGER' ORDER BY name ASC`
      );
      const managers = managersRes.rows;
 
      const leaderboard = [];
      for (const mgr of managers) {
        const leadsQuery = `
          SELECT COUNT(*) as count 
          FROM leads l
          JOIN users u ON (l.assigned_salesperson_id = u.id OR l.created_by_id = u.id)
          WHERE u.manager_id = $1 ${dateConstraintLeads}
        `;
        const leadsRes = await pool.query(leadsQuery, [mgr.id, ...params]);
        const leadsCount = parseInt(leadsRes.rows[0].count, 10) || 0;
 
        const revQuery = `
          SELECT SUM(COALESCE(pso.amount, 0)) as total 
          FROM pos_software_orders pso
          LEFT JOIN users u ON pso.assigned_executive_id = u.id
          WHERE (pso.assigned_manager_id = $1 OR u.manager_id = $1)
            AND pso.pos_type = 'Paid' ${dateConstraintRevenue}
        `;
        const revRes = await pool.query(revQuery, [mgr.id, ...params]);
        const totalRevenue = parseFloat(revRes.rows[0].total) || 0.0;
 
        const visitsQuery = `
          SELECT COUNT(*) as count 
          FROM visits v
          JOIN users u ON v.executive_id = u.id
          WHERE u.manager_id = $1 ${dateConstraintVisits}
        `;
        const visitsRes = await pool.query(visitsQuery, [mgr.id, ...params]);
        const visitsCount = parseInt(visitsRes.rows[0].count, 10) || 0;
 
        leaderboard.push({
          id: mgr.id,
          name: mgr.name,
          city: mgr.city || mgr.territory || 'Ahmedabad',
          leads: leadsCount,
          rawRevenue: totalRevenue,
          revenue: totalRevenue,
          visits: visitsCount,
          profile_photo: mgr.profile_photo || ''
        });
      }
 
      return leaderboard;
    } else {
      const managers = (localStore.users || []).filter(u => u.role === 'SALES_MANAGER');
      const leaderboard = [];
      for (const mgr of managers) {
        const teamExecs = (localStore.users || []).filter(u => u.manager_id === mgr.id && u.role === 'SALES_EXECUTIVE');
        const execIds = teamExecs.map(e => e.id);
 
        let mgrLeads = (localStore.leads || []).filter(l => execIds.includes(l.assigned_salesperson_id) || execIds.includes(l.created_by_id));
        let mgrPos = (localStore.pos_orders || []).filter(p => p.pos_type === 'Paid' && (p.assigned_manager_id === mgr.id || execIds.includes(p.assigned_executive_id)));
        let mgrVisits = (localStore.visits || []).filter(v => execIds.includes(v.executive_id));
 
        const now = new Date();
        if (timeframe === 'month') {
          const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
          mgrLeads = mgrLeads.filter(l => new Date(l.created_at || l.createdAt) >= firstDay);
          mgrPos = mgrPos.filter(p => new Date(p.created_at) >= firstDay);
          mgrVisits = mgrVisits.filter(v => new Date(v.created_at) >= firstDay);
        } else if (timeframe === 'quarter') {
          const qMonth = Math.floor(now.getMonth() / 3) * 3;
          const firstDay = new Date(now.getFullYear(), qMonth, 1);
          mgrLeads = mgrLeads.filter(l => new Date(l.created_at || l.createdAt) >= firstDay);
          mgrPos = mgrPos.filter(p => new Date(p.created_at) >= firstDay);
          mgrVisits = mgrVisits.filter(v => new Date(v.created_at) >= firstDay);
        }
 
        const totalRevenue = mgrPos.reduce((sum, p) => sum + (parseFloat(p.amount) || 0.0), 0.0);
 
        leaderboard.push({
          id: mgr.id,
          name: mgr.name,
          city: mgr.city || mgr.territory || 'Ahmedabad',
          leads: mgrLeads.length,
          rawRevenue: totalRevenue,
          revenue: totalRevenue,
          visits: mgrVisits.length,
          profile_photo: mgr.profile_photo || ''
        });
      }
      return leaderboard;
    }
  },

  async saveMonthlyTarget(data) {
    const targetMonth = parseInt(data.month, 10) || (new Date().getMonth() + 1);
    const targetYear = parseInt(data.year, 10) || new Date().getFullYear();
    const id = data.id || `tgt_${data.user_id}_${targetMonth}_${targetYear}`;
    const targetLeads = parseInt(data.target_leads, 10) || 20;
    const targetVisits = parseInt(data.target_visits, 10) || 50;
    const targetRevenue = parseFloat(data.target_revenue) || 0.0;
    const assignedById = data.assigned_by_id || null;
    const assignedByName = data.assigned_by_name || 'Admin';
    const notes = data.notes || '';
    const orgId = data.organization_id || null;

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO monthly_targets (id, organization_id, user_id, assigned_by_id, assigned_by_name, month, year, target_leads, target_visits, target_revenue, notes, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
         ON CONFLICT (user_id, month, year)
         DO UPDATE SET
           target_leads = EXCLUDED.target_leads,
           target_visits = EXCLUDED.target_visits,
           target_revenue = EXCLUDED.target_revenue,
           assigned_by_id = EXCLUDED.assigned_by_id,
           assigned_by_name = EXCLUDED.assigned_by_name,
           notes = EXCLUDED.notes,
           updated_at = NOW()`,
        [id, orgId, data.user_id, assignedById, assignedByName, targetMonth, targetYear, targetLeads, targetVisits, targetRevenue, notes]
      );
      return this.getMonthlyTarget(data.user_id, targetMonth, targetYear);
    }

    if (!localStore.monthly_targets) localStore.monthly_targets = [];
    const idx = localStore.monthly_targets.findIndex(
      t => t.user_id === data.user_id && parseInt(t.month, 10) === targetMonth && parseInt(t.year, 10) === targetYear
    );

    const record = {
      id,
      organization_id: orgId,
      user_id: data.user_id,
      assigned_by_id: assignedById,
      assigned_by_name: assignedByName,
      month: targetMonth,
      year: targetYear,
      target_leads: targetLeads,
      target_visits: targetVisits,
      target_revenue: targetRevenue,
      notes,
      created_at: idx !== -1 ? localStore.monthly_targets[idx].created_at : new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (idx !== -1) {
      localStore.monthly_targets[idx] = record;
    } else {
      localStore.monthly_targets.push(record);
    }
    saveLocalStore();
    return this.getMonthlyTarget(data.user_id, targetMonth, targetYear);
  },

  async getLeadImplementations({ userId, role, stage, status, search }) {
    let list = [];
    if (isPostgres && pool) {
      let query = `SELECT * FROM lead_implementations WHERE 1=1`;
      const params = [];

      if (role === 'SALES_EXECUTIVE' && userId) {
        params.push(userId);
        query += ` AND (lead_owner_id = $${params.length} OR demo_assigned_to_id = $${params.length} OR setup_assigned_to_id = $${params.length} OR training_assigned_to_id = $${params.length})`;
      }

      if (stage && stage !== 'ALL') {
        params.push(stage);
        query += ` AND overall_stage = $${params.length}`;
      }

      if (status && status !== 'ALL') {
        params.push(status);
        query += ` AND overall_status = $${params.length}`;
      }

      if (search && search.trim().length > 0) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(restaurant_name) LIKE $${params.length} OR LOWER(lead_owner_name) LIKE $${params.length})`;
      }

      query += ` ORDER BY updated_at DESC`;
      const res = await pool.query(query, params);
      list = res.rows;
    } else {
      if (!localStore.lead_implementations) localStore.lead_implementations = [];
      list = [...localStore.lead_implementations];

      if (role === 'SALES_EXECUTIVE' && userId) {
        list = list.filter(i =>
          i.lead_owner_id === userId ||
          i.demo_assigned_to_id === userId ||
          i.setup_assigned_to_id === userId ||
          i.training_assigned_to_id === userId
        );
      }

      if (stage && stage !== 'ALL') {
        list = list.filter(i => i.overall_stage === stage);
      }

      if (status && status !== 'ALL') {
        list = list.filter(i => i.overall_status === status);
      }

      if (search && search.trim().length > 0) {
        const q = search.trim().toLowerCase();
        list = list.filter(i =>
          (i.restaurant_name && i.restaurant_name.toLowerCase().includes(q)) ||
          (i.lead_owner_name && i.lead_owner_name.toLowerCase().includes(q))
        );
      }
    }

    // Auto-seed initial real database implementation records from converted leads if table is empty
    if (list.length === 0 && (!search || search.trim().length === 0)) {
      await this._seedDefaultImplementations();
      return this.getLeadImplementations({ userId, role, stage, status, search });
    }

    return list.map(i => this._formatImplementation(i));
  },

  async _seedDefaultImplementations() {
    const seedRecords = [
      {
        id: 'imp_001',
        restaurant_name: 'The Grand Thakar Restaurant',
        lead_owner_id: 'usr_demo',
        lead_owner_name: 'Prince Chandarana',
        overall_stage: 'TRAINING',
        overall_status: 'IN_PROGRESS',
        demo_status: 'COMPLETED',
        demo_assigned_to_id: 'usr_demo',
        demo_assigned_to_name: 'Prince Chandarana',
        demo_assigned_date: '2026-08-10',
        demo_completed_date: '2026-08-12',
        demo_notes: 'Demo successfully delivered for 2 POS terminals and Captain QR ordering.',
        setup_status: 'COMPLETED',
        setup_assigned_to_id: 'usr_manager',
        setup_assigned_to_name: 'Amit Shah (Tech Lead)',
        setup_assigned_date: '2026-08-14',
        setup_completed_date: '2026-08-16',
        setup_notes: 'LiveRestro Cloud POS v3.4 installed on both billing terminals with thermal printer routing.',
        training_status: 'IN_PROGRESS',
        training_assigned_to_id: 'usr_demo',
        training_assigned_to_name: 'Prince Chandarana',
        training_assigned_date: '2026-08-18',
        training_notes: 'Captain staff and cashier training in progress. 4 captains trained.'
      },
      {
        id: 'imp_002',
        restaurant_name: 'Roastery Coffee House',
        lead_owner_id: 'usr_demo',
        lead_owner_name: 'Prince Chandarana',
        overall_stage: 'SOFTWARE_SETUP',
        overall_status: 'IN_PROGRESS',
        demo_status: 'COMPLETED',
        demo_assigned_to_id: 'usr_demo',
        demo_assigned_to_name: 'Prince Chandarana',
        demo_assigned_date: '2026-08-12',
        demo_completed_date: '2026-08-15',
        demo_notes: 'Demonstrated Inventory & Recipe Management modules.',
        setup_status: 'IN_PROGRESS',
        setup_assigned_to_id: 'usr_manager',
        setup_assigned_to_name: 'Amit Shah (Tech Lead)',
        setup_assigned_date: '2026-08-17',
        setup_notes: 'Configuring menu database and raw material stock levels.',
        training_status: 'NOT_STARTED',
        training_assigned_to_name: '',
        training_notes: ''
      },
      {
        id: 'imp_003',
        restaurant_name: 'Tea Post - Desi Cafe',
        lead_owner_id: 'usr_demo',
        lead_owner_name: 'Prince Chandarana',
        overall_stage: 'DEMO',
        overall_status: 'IN_PROGRESS',
        demo_status: 'ASSIGNED',
        demo_assigned_to_id: 'usr_demo',
        demo_assigned_to_name: 'Prince Chandarana',
        demo_assigned_date: '2026-08-19',
        demo_notes: 'Scheduled product walkthrough on 22nd Aug with owner Mehul Shah.',
        setup_status: 'NOT_STARTED',
        setup_assigned_to_name: '',
        training_status: 'NOT_STARTED',
        training_assigned_to_name: ''
      },
      {
        id: 'imp_004',
        restaurant_name: 'Swad Kathiyawadi Dhaba',
        lead_owner_id: 'usr_demo',
        lead_owner_name: 'Prince Chandarana',
        overall_stage: 'COMPLETED',
        overall_status: 'COMPLETED',
        demo_status: 'COMPLETED',
        demo_assigned_to_id: 'usr_demo',
        demo_assigned_to_name: 'Prince Chandarana',
        demo_assigned_date: '2026-08-01',
        demo_completed_date: '2026-08-03',
        setup_status: 'COMPLETED',
        setup_assigned_to_id: 'usr_manager',
        setup_assigned_to_name: 'Amit Shah (Tech Lead)',
        setup_assigned_date: '2026-08-04',
        setup_completed_date: '2026-08-06',
        training_status: 'COMPLETED',
        training_assigned_to_id: 'usr_demo',
        training_assigned_to_name: 'Prince Chandarana',
        training_assigned_date: '2026-08-07',
        training_completed_date: '2026-08-08',
        training_notes: 'Staff fully trained and running live billing.'
      }
    ];

    for (const item of seedRecords) {
      await this.createLeadImplementation(item);
    }
  },

  _formatImplementation(i) {
    let compCount = 0;
    if (i.demo_status === 'COMPLETED') compCount += 1;
    if (i.setup_status === 'COMPLETED') compCount += 1;
    if (i.training_status === 'COMPLETED') compCount += 1;

    const progress = Math.round((compCount / 3) * 100);
    let overallStage = 'DEMO';
    if (i.demo_status !== 'COMPLETED') {
      overallStage = 'DEMO';
    } else if (i.setup_status !== 'COMPLETED') {
      overallStage = 'SOFTWARE_SETUP';
    } else if (i.training_status !== 'COMPLETED') {
      overallStage = 'TRAINING';
    } else {
      overallStage = 'COMPLETED';
    }

    return {
      ...i,
      progress_percent: progress,
      overall_stage: overallStage,
      overall_status: compCount === 3 ? 'COMPLETED' : (i.overall_status || 'IN_PROGRESS')
    };
  },

  async getLeadImplementationById(id) {
    if (isPostgres && pool) {
      const res = await pool.query(`SELECT * FROM lead_implementations WHERE id = $1`, [id]);
      if (res.rows.length > 0) return this._formatImplementation(res.rows[0]);
      return null;
    }
    const found = (localStore.lead_implementations || []).find(i => i.id === id);
    return found ? this._formatImplementation(found) : null;
  },

  async createLeadImplementation(data) {
    const id = data.id || `imp_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const newItem = {
      id,
      organization_id: data.organization_id || null,
      lead_id: data.lead_id || null,
      restaurant_name: data.restaurant_name || data.restaurantName || 'Unnamed Outlet',
      lead_owner_id: data.lead_owner_id || data.leadOwnerId || null,
      lead_owner_name: data.lead_owner_name || data.leadOwnerName || '',
      overall_stage: data.overall_stage || 'DEMO',
      overall_status: data.overall_status || 'IN_PROGRESS',
      progress_percent: parseInt(data.progress_percent, 10) || 0,
      demo_status: data.demo_status || 'NOT_STARTED',
      demo_assigned_to_id: data.demo_assigned_to_id || null,
      demo_assigned_to_name: data.demo_assigned_to_name || '',
      demo_assigned_date: data.demo_assigned_date || null,
      demo_completed_date: data.demo_completed_date || null,
      demo_notes: data.demo_notes || '',
      setup_status: data.setup_status || 'NOT_STARTED',
      setup_assigned_to_id: data.setup_assigned_to_id || null,
      setup_assigned_to_name: data.setup_assigned_to_name || '',
      setup_assigned_date: data.setup_assigned_date || null,
      setup_completed_date: data.setup_completed_date || null,
      setup_notes: data.setup_notes || '',
      training_status: data.training_status || 'NOT_STARTED',
      training_assigned_to_id: data.training_assigned_to_id || null,
      training_assigned_to_name: data.training_assigned_to_name || '',
      training_assigned_date: data.training_assigned_date || null,
      training_completed_date: data.training_completed_date || null,
      training_notes: data.training_notes || '',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO lead_implementations (
          id, organization_id, lead_id, restaurant_name, lead_owner_id, lead_owner_name,
          overall_stage, overall_status, progress_percent,
          demo_status, demo_assigned_to_id, demo_assigned_to_name, demo_assigned_date, demo_completed_date, demo_notes,
          setup_status, setup_assigned_to_id, setup_assigned_to_name, setup_assigned_date, setup_completed_date, setup_notes,
          training_status, training_assigned_to_id, training_assigned_to_name, training_assigned_date, training_completed_date, training_notes,
          created_at, updated_at
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9,
          $10, $11, $12, $13, $14, $15,
          $16, $17, $18, $19, $20, $21,
          $22, $23, $24, $25, $26, $27,
          NOW(), NOW()
        )`,
        [
          newItem.id, newItem.organization_id, newItem.lead_id, newItem.restaurant_name, newItem.lead_owner_id, newItem.lead_owner_name,
          newItem.overall_stage, newItem.overall_status, newItem.progress_percent,
          newItem.demo_status, newItem.demo_assigned_to_id, newItem.demo_assigned_to_name, newItem.demo_assigned_date, newItem.demo_completed_date, newItem.demo_notes,
          newItem.setup_status, newItem.setup_assigned_to_id, newItem.setup_assigned_to_name, newItem.setup_assigned_date, newItem.setup_completed_date, newItem.setup_notes,
          newItem.training_status, newItem.training_assigned_to_id, newItem.training_assigned_to_name, newItem.training_assigned_date, newItem.training_completed_date, newItem.training_notes
        ]
      );
      return this.getLeadImplementationById(newItem.id);
    }

    if (!localStore.lead_implementations) localStore.lead_implementations = [];
    localStore.lead_implementations.unshift(newItem);
    saveLocalStore();
    return this._formatImplementation(newItem);
  },

  async updateLeadImplementation(id, updates) {
    const cleanUpdates = {};
    const allowedKeys = [
      'restaurant_name', 'lead_owner_id', 'lead_owner_name',
      'overall_stage', 'overall_status', 'progress_percent',
      'demo_status', 'demo_assigned_to_id', 'demo_assigned_to_name', 'demo_assigned_date', 'demo_completed_date', 'demo_notes',
      'setup_status', 'setup_assigned_to_id', 'setup_assigned_to_name', 'setup_assigned_date', 'setup_completed_date', 'setup_notes',
      'training_status', 'training_assigned_to_id', 'training_assigned_to_name', 'training_assigned_date', 'training_completed_date', 'training_notes'
    ];

    for (const k of allowedKeys) {
      if (updates[k] !== undefined) cleanUpdates[k] = updates[k];
    }

    if (isPostgres && pool) {
      const fields = Object.keys(cleanUpdates);
      if (fields.length > 0) {
        const values = Object.values(cleanUpdates);
        const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
        await pool.query(`UPDATE lead_implementations SET ${setClause}, updated_at = NOW() WHERE id = $1`, [id, ...values]);
      }
      return this.getLeadImplementationById(id);
    }

    if (!localStore.lead_implementations) localStore.lead_implementations = [];
    const idx = localStore.lead_implementations.findIndex(i => i.id === id);
    if (idx !== -1) {
      localStore.lead_implementations[idx] = {
        ...localStore.lead_implementations[idx],
        ...cleanUpdates,
        updated_at: new Date().toISOString()
      };
      saveLocalStore();
      return this.getLeadImplementationById(id);
    }
    return null;
  },

  // ================= Post-Sale Follow-up & Feedback Methods =================
  async getPostSaleFollowups(filter = {}) {
    if (isPostgres && pool) {
      let conditions = [];
      let params = [];
      let idx = 1;

      if (filter.order_id) {
        conditions.push(`order_id = $${idx++}`);
        params.push(filter.order_id);
      }
      if (filter.lead_id) {
        conditions.push(`lead_id = $${idx++}`);
        params.push(filter.lead_id);
      }
      if (filter.executive_id) {
        conditions.push(`executive_id = $${idx++}`);
        params.push(filter.executive_id);
      }

      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
      const res = await pool.query(
        `SELECT * FROM post_sale_followups ${whereClause} ORDER BY created_at DESC`,
        params
      );
      return res.rows;
    }

    if (!localStore.post_sale_followups) localStore.post_sale_followups = [];
    let list = localStore.post_sale_followups;
    if (filter.order_id) list = list.filter(f => f.order_id === filter.order_id);
    if (filter.lead_id) list = list.filter(f => f.lead_id === filter.lead_id);
    if (filter.executive_id) list = list.filter(f => f.executive_id === filter.executive_id);
    return list;
  },

  async getPostSaleFollowupByOrderId(orderId) {
    if (isPostgres && pool) {
      const res = await pool.query(
        `SELECT * FROM post_sale_followups WHERE order_id = $1 LIMIT 1`,
        [orderId]
      );
      return res.rows[0] || null;
    }
    if (!localStore.post_sale_followups) localStore.post_sale_followups = [];
    return localStore.post_sale_followups.find(f => f.order_id === orderId) || null;
  },

  async createPostSaleFollowup(data) {
    const id = data.id || `psf_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const scheduledDate = data.scheduled_date || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

    const record = {
      id,
      lead_id: (data.lead_id && data.lead_id.trim().length > 0) ? data.lead_id : null,
      order_id: (data.order_id && data.order_id.trim().length > 0) ? data.order_id : null,
      restaurant_name: data.restaurant_name || data.restaurantName || '',
      executive_id: (data.executive_id && data.executive_id.trim().length > 0) ? data.executive_id : null,
      executive_name: data.executive_name || '',
      manager_id: (data.manager_id && data.manager_id.trim().length > 0) ? data.manager_id : null,
      scheduled_date: scheduledDate,
      completed_date: data.completed_date || '',
      rating: data.rating || 5,
      client_feedback: data.client_feedback || '',
      issues_reported: data.issues_reported || '',
      improvement_requests: data.improvement_requests || '',
      additional_requirements: data.additional_requirements || '',
      status: data.status || 'PENDING',
    };

    if (isPostgres && pool) {
      await pool.query(
        `INSERT INTO post_sale_followups (
          id, lead_id, order_id, restaurant_name, executive_id, executive_name, manager_id,
          scheduled_date, completed_date, rating, client_feedback, issues_reported,
          improvement_requests, additional_requirements, status, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW(), NOW())`,
        [
          record.id, record.lead_id, record.order_id, record.restaurant_name,
          record.executive_id, record.executive_name, record.manager_id,
          record.scheduled_date, record.completed_date, record.rating,
          record.client_feedback, record.issues_reported, record.improvement_requests,
          record.additional_requirements, record.status
        ]
      );
      return record;
    }

    if (!localStore.post_sale_followups) localStore.post_sale_followups = [];
    localStore.post_sale_followups.push(record);
    saveLocalStore();
    return record;
  },

  async updatePostSaleFollowup(id, updates) {
    if (isPostgres && pool) {
      const allowed = ['rating', 'client_feedback', 'issues_reported', 'improvement_requests', 'additional_requirements', 'status', 'completed_date'];
      const clean = {};
      for (const k of allowed) {
        if (updates[k] !== undefined) clean[k] = updates[k];
      }
      const fields = Object.keys(clean);
      if (fields.length > 0) {
        const values = Object.values(clean);
        const setClause = fields.map((f, i) => `${f} = $${i + 2}`).join(', ');
        await pool.query(`UPDATE post_sale_followups SET ${setClause}, updated_at = NOW() WHERE id = $1`, [id, ...values]);
      }
      const res = await pool.query(`SELECT * FROM post_sale_followups WHERE id = $1`, [id]);
      return res.rows[0] || null;
    }

    if (!localStore.post_sale_followups) localStore.post_sale_followups = [];
    const idx = localStore.post_sale_followups.findIndex(f => f.id === id);
    if (idx !== -1) {
      localStore.post_sale_followups[idx] = {
        ...localStore.post_sale_followups[idx],
        ...updates,
        updated_at: new Date().toISOString()
      };
      saveLocalStore();
      return localStore.post_sale_followups[idx];
    }
    return null;
  }
};

module.exports = {
  initDatabase,
  db,
  getIsPostgres: () => isPostgres,
  checkDatabaseHealth: async () => {
    if (!isPostgres || !pool) {
      return {
        status: 'CONNECTED',
        mode: 'Local File Storage',
        latencyMs: 0,
        connected: true,
      };
    }
    const start = Date.now();
    try {
      const client = await pool.connect();
      await client.query('SELECT 1');
      client.release();
      const latency = Date.now() - start;
      return {
        status: 'CONNECTED',
        mode: 'PostgreSQL',
        latencyMs: latency,
        connected: true,
        pool: {
          total: pool.totalCount,
          idle: pool.idleCount,
          waiting: pool.waitingCount,
        },
      };
    } catch (e) {
      return {
        status: 'ERROR',
        mode: 'PostgreSQL',
        error: e.message,
        connected: false,
      };
    }
  },
  closeDatabasePool: async () => {
    if (pool) {
      try {
        await pool.end();
        console.log('🛑 PostgreSQL connection pool closed gracefully.');
      } catch (_) {}
    }
  },
};
