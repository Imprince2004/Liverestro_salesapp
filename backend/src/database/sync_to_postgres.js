const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function syncAllToPostgres() {
  const pool = new Pool({
    connectionString: 'postgresql://postgres:Dhruvisha@localhost:5432/liverestro'
  });

  const client = await pool.connect();
  console.log('🔗 Connected to PostgreSQL database: liverestro');

  try {
    const raw = fs.readFileSync(path.join(__dirname, '../../data/liverestro_db.json'), 'utf8');
    const localDb = JSON.parse(raw);

    console.log(`Found ${localDb.users.length} users in local database file.`);

    // 1. Ensure schema table columns exist
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(64) PRIMARY KEY,
        organization_id VARCHAR(64),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        phone VARCHAR(64) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(64) NOT NULL,
        status VARCHAR(64) DEFAULT 'ACTIVE',
        manager_id VARCHAR(64),
        employee_id VARCHAR(64),
        date_of_joining VARCHAR(64),
        date_of_birth VARCHAR(64),
        designation VARCHAR(128),
        profile_photo TEXT,
        territory VARCHAR(255),
        city VARCHAR(128),
        visits_target INTEGER DEFAULT 8,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // Ensure columns exist if table was previously created with fewer columns
    const columnsToAdd = [
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id VARCHAR(64)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_joining VARCHAR(64)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth VARCHAR(64)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS designation VARCHAR(128)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo TEXT",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS territory VARCHAR(255)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(128)",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS visits_target INTEGER DEFAULT 8",
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS manager_id VARCHAR(64)"
    ];

    for (const alterSql of columnsToAdd) {
      try {
        await client.query(alterSql);
      } catch (_) {}
    }

    // 2. Insert or update all users
    for (const u of localDb.users) {
      // Check if user exists by id, email, or phone
      const existingRes = await client.query('SELECT id FROM users WHERE id = $1 OR email = $2 OR phone = $3 LIMIT 1', [
        u.id,
        u.email,
        u.phone
      ]);

      if (existingRes.rows.length > 0) {
        const existingId = existingRes.rows[0].id;
        await client.query(`
          UPDATE users SET
            name = $1,
            email = $2,
            phone = $3,
            role = $4,
            status = $5,
            manager_id = $6,
            employee_id = $7,
            date_of_joining = $8,
            date_of_birth = $9,
            designation = $10,
            profile_photo = $11,
            territory = $12,
            city = $13,
            visits_target = $14,
            updated_at = NOW()
          WHERE id = $15
        `, [
          u.name,
          u.email,
          u.phone,
          u.role || 'SALES_EXECUTIVE',
          u.status || 'ACTIVE',
          u.manager_id || (u.role === 'SALES_EXECUTIVE' ? 'usr_salesmanager_003' : null),
          u.employee_id || 'EMP001',
          u.date_of_joining || '2024-03-01',
          u.date_of_birth || null,
          u.designation || (u.role === 'SALES_MANAGER' ? 'Regional Sales Manager' : 'Sales Executive'),
          u.profile_photo || 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
          u.territory || 'Ahmedabad North',
          u.city || 'Ahmedabad',
          u.visits_target || 8,
          existingId
        ]);
      } else {
        await client.query(`
          INSERT INTO users (
            id, organization_id, name, email, phone, password_hash, role, status,
            manager_id, employee_id, date_of_joining, date_of_birth, designation,
            profile_photo, territory, city, visits_target, created_at, updated_at
          ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
          )
        `, [
          u.id,
          u.organization_id || 'org_demo_001',
          u.name,
          u.email,
          u.phone,
          u.password_hash || '$2a$10$Z.6Fjq7xPP0BvSgcHqSKKeHb7BFXc13KFjh1qLKE0jvD8QYBe/thC',
          u.role || 'SALES_EXECUTIVE',
          u.status || 'ACTIVE',
          u.manager_id || (u.role === 'SALES_EXECUTIVE' ? 'usr_salesmanager_003' : null),
          u.employee_id || 'EMP001',
          u.date_of_joining || '2024-03-01',
          u.date_of_birth || null,
          u.designation || (u.role === 'SALES_MANAGER' ? 'Regional Sales Manager' : 'Sales Executive'),
          u.profile_photo || 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
          u.territory || 'Ahmedabad North',
          u.city || 'Ahmedabad',
          u.visits_target || 8,
          u.created_at || new Date().toISOString(),
          u.updated_at || new Date().toISOString()
        ]);
      }
    }

    const countRes = await client.query('SELECT count(*) FROM users');
    console.log(`✅ SYNC COMPLETE! Total users in PostgreSQL: ${countRes.rows[0].count}`);

    const latest = await client.query('SELECT name, employee_id, email, phone, role, territory FROM users ORDER BY employee_id ASC');
    console.log('\n--- POSTGRESQL USERS TABLE CONTENT ---');
    latest.rows.forEach(r => {
      console.log(`  • [${r.employee_id}] ${r.name} (${r.role}) - ${r.phone} - ${r.territory}`);
    });

  } catch (err) {
    console.error('Sync failed:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

syncAllToPostgres();
