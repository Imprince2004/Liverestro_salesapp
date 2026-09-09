const bcrypt = require('bcryptjs');
const { initDatabase, db } = require('../config/database');

const ROLE_PERMISSIONS = {
  SUPER_ADMIN: [
    'full_system_control',
    'manage_all_organizations',
    'create_companies',
    'edit_companies',
    'deactivate_companies',
    'manage_company_admin_users',
    'view_all_users',
    'manage_global_roles_permissions',
    'view_system_wide_analytics',
    'manage_subscriptions_plans',
    'view_audit_logs',
    'manage_global_settings',
    'view_system_health_integrations'
  ],
  COMPANY_ADMIN: [
    'manage_organization_profile',
    'create_sales_managers',
    'manage_sales_managers',
    'create_sales_executives',
    'manage_sales_executives',
    'activate_deactivate_users',
    'assign_executives_to_managers',
    'manage_restaurants',
    'manage_leads',
    'view_visits',
    'view_follow_ups',
    'manage_tasks',
    'view_attendance',
    'view_team_reports',
    'manage_products_price_lists',
    'manage_organization_settings',
    'view_organization_notifications'
  ],
  SALES_MANAGER: [
    'view_assigned_executives',
    'view_team_performance',
    'view_team_leads',
    'view_restaurants',
    'view_team_visits',
    'view_follow_ups',
    'view_attendance',
    'view_team_reports',
    'create_tasks',
    'assign_tasks_to_executives',
    'assign_restaurant_visits',
    'assign_area_territory_visits',
    'assign_lead_follow_ups',
    'schedule_demos_meetings',
    'reassign_tasks',
    'monitor_task_progress',
    'review_completed_tasks',
    'add_manager_notes'
  ],
  SALES_EXECUTIVE: [
    'view_assigned_leads',
    'create_leads',
    'view_assigned_restaurants',
    'add_restaurants',
    'record_visits',
    'check_in_check_out',
    'capture_gps',
    'capture_selfie',
    'record_voice_notes',
    'generate_ai_visit_summaries',
    'create_follow_ups',
    'view_assigned_tasks',
    'update_task_status',
    'add_task_notes',
    'upload_photos_documents',
    'view_assigned_task_location',
    'navigate_to_assigned_restaurants',
    'complete_assigned_tasks',
    'view_own_attendance_performance'
  ]
};

async function seed() {
  console.log('🌱 Starting LiveRestro Seed Process...');
  await initDatabase();

  // 1. Seed Permissions Matrix
  console.log('🔐 Seeding Role Permissions...');
  for (const [role, perms] of Object.entries(ROLE_PERMISSIONS)) {
    await db.setRolePermissions(role, perms);
  }

  // 2. Seed Default Organization
  console.log('🏢 Seeding Organization...');
  const orgId = 'org_demo_001';
  let org = await db.getOrganizationById(orgId);
  if (!org) {
    org = await db.createOrganization({
      id: orgId,
      name: 'LiveRestro Demo Organization',
      code: 'LR-DEMO',
      status: 'ACTIVE'
    });
  }

  // 3. Precompute Password Hashes
  const superAdminHash = await bcrypt.hash('Demo@SuperAdmin123', 10);
  const companyAdminHash = await bcrypt.hash('Demo@CompanyAdmin123', 10);
  const managerHash = await bcrypt.hash('Demo@Manager123', 10);
  const executiveHash = await bcrypt.hash('Demo@Executive123', 10);

  // 4. Seed The Main LiveRestro Admin Account Only
  console.log('👤 Seeding LiveRestro Admin Account...');

  const usersToSeed = [
    {
      id: 'usr_companyadmin_002',
      organization_id: orgId,
      name: 'LiveRestro Admin',
      email: 'admin@liverestro.com',
      phone: '9000000002',
      password_hash: companyAdminHash,
      role: 'COMPANY_ADMIN',
      status: 'ACTIVE',
      manager_id: null,
      employee_id: 'EMP001',
      date_of_joining: '2024-01-15',
      designation: 'Company Administrator',
      profile_photo: '',
      territory: 'Gujarat Headquarters',
      city: 'Ahmedabad'
    }
  ];

  for (const u of usersToSeed) {
    const existing = await db.getUserById(u.id) || await db.findUserByEmailOrPhone(u.email) || await db.findUserByEmailOrPhone(u.phone);
    if (!existing) {
      await db.createUser(u);
      console.log(`  ✓ Created user: ${u.name} (${u.role}) -> ${u.employee_id}`);
    } else {
      await db.updateUser(existing.id, {
        password_hash: u.password_hash,
        role: u.role,
        manager_id: null,
        organization_id: u.organization_id,
        employee_id: u.employee_id,
        date_of_joining: u.date_of_joining,
        designation: u.designation,
        profile_photo: u.profile_photo,
        territory: u.territory,
        city: u.city,
        visits_target: u.visits_target,
        status: 'ACTIVE'
      });
      console.log(`  ✓ Updated user: ${u.name} (${u.role}) -> ${u.employee_id}`);
    }

    const current = await db.getUserById(u.id) || await db.findUserByEmailOrPhone(u.email) || await db.findUserByEmailOrPhone(u.phone);
    if (current) {
      const defaultPinHash = await bcrypt.hash('1234', 10);
      await db.saveUserPin(current.id, defaultPinHash);
      await db.saveTotpSecret(current.id, 'BNRJWTZUM6OSB2XOSYAMQRG7CJ7L2GPH', true);
    }
  }

  // 5. Seed Help Center, Video Tutorials & Hardware Catalog (PostgreSQL only)
  if (db.getIsPostgres()) {
    console.log('📦 Seeding Hardware Catalog...');
    const hwCatalog = [
      {
        id: 'hw_01',
        title: 'Android Touch POS Terminal (15")',
        price: 32000.0,
        description: 'Professional 15.6 inch dual-screen widescreen POS billing system with high-speed customer display panel.',
        sku: 'HW-TRM-15D',
        category: 'Hardware',
        image_url: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400',
        specifications: '15.6" IPS Display, 4GB RAM, 64GB Storage, Android 11 OS, Dual Screen capability'
      },
      {
        id: 'hw_02',
        title: '80mm Thermal Receipt Printer',
        price: 6500.0,
        description: 'Ultra-fast thermal printing speed of 250mm/sec with auto cutter and dual interface (USB + LAN).',
        sku: 'HW-PRN-80',
        category: 'Hardware',
        image_url: 'https://images.unsplash.com/photo-1610483178766-8092dccb4c2e?w=400',
        specifications: 'Print speed: 250mm/s, Interface: USB + LAN, Auto-cutter: 1.5 million cuts'
      },
      {
        id: 'hw_03',
        title: 'Kitchen Display System Tablet (10.1")',
        price: 14500.0,
        description: 'Commercial grade tablet for real-time kitchen order ticket display with wall mount bracket.',
        sku: 'HW-KDS-10',
        category: 'Hardware',
        image_url: 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400',
        specifications: '10.1" Capacitive Touch, IP65 Front panel, Wi-Fi 2.4/5GHz, Heavy Duty Wall Mount'
      }
    ];

    for (const hw of hwCatalog) {
      try {
        await db.query(
          `INSERT INTO hardware_catalog (id, title, price, description, sku, category, image_url, specifications)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (sku) DO NOTHING`,
          [hw.id, hw.title, hw.price, hw.description, hw.sku, hw.category, hw.image_url, hw.specifications]
        );
      } catch (err) {
        console.error('Seeding hardware error:', err.message);
      }
    }

    console.log('❓ Seeding Help Center & FAQs...');
    const faqs = [
      { id: 'faq_01', question: 'How to register a new Sales Executive?', answer: 'Authorized Managers can click on the Register Sales Executive button on the Sales Manager hub, input the employee details, and submit to save the user to PostgreSQL instantly.', category: 'System Setup' },
      { id: 'faq_02', question: 'How to track Sales Executive live GPS location?', answer: 'Go to the Field Radar section on the Manager dashboard to see real-time route tracing, checked-in visits, and active executive positions.', category: 'Live Tracking' },
      { id: 'faq_03', question: 'How does the Open Deal Quotation Calculator work?', answer: 'Select client items from the Orders section, input custom discount percentages, and the app will dynamically calculate tax totals and generate a WhatsApp shareable quote.', category: 'Calculator' }
    ];

    for (const faq of faqs) {
      try {
        await db.query(
          `INSERT INTO help_center (id, question, answer, category)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (id) DO NOTHING`,
          [faq.id, faq.question, faq.answer, faq.category]
        );
      } catch (err) {
        console.error('Seeding FAQ error:', err.message);
      }
    }

    console.log('🎥 Seeding Video Tutorials...');
    const tutorials = [
      { id: 'vid_01', title: 'Getting Started with LiveRestro App', description: 'Introduction to checking in at restaurants and registering new leads.', category: 'Training', video_url: 'https://assets.mixkit.co/videos/preview/mixkit-kitchen-chef-preparing-a-dish-42225-large.mp4', thumbnail_url: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400', duration: '05:12' },
      { id: 'vid_02', title: 'Closing Deals: Handling Objections', description: 'F&B sales objection handling and price calculations.', category: 'Sales Mastery', video_url: 'https://assets.mixkit.co/videos/preview/mixkit-businessmen-discussing-charts-40158-large.mp4', thumbnail_url: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=400', duration: '08:45' }
    ];

    for (const vid of tutorials) {
      try {
        await db.query(
          `INSERT INTO video_tutorials (id, title, description, category, video_url, thumbnail_url, duration)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (id) DO NOTHING`,
          [vid.id, vid.title, vid.description, vid.category, vid.video_url, vid.thumbnail_url, vid.duration]
        );
      } catch (err) {
        console.error('Seeding video error:', err.message);
      }
    }
  }

  console.log('✅ LiveRestro Seeding Complete!');
}

if (require.main === module) {
  seed()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('Seed error:', err);
      process.exit(1);
    });
}

module.exports = { seed, ROLE_PERMISSIONS };
