const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function purgeSalesExecutives() {
  const pool = new Pool({
    connectionString: 'postgresql://postgres:Dhruvisha@localhost:5432/liverestro'
  });

  const client = await pool.connect();
  try {
    console.log('--- 1. CLEANING POSTGRESQL DATABASE ---');
    // First, delete tasks assigned to sales executives to avoid foreign key constraints
    await client.query("DELETE FROM tasks WHERE assigned_to_id NOT IN ('usr_superadmin_001', 'usr_companyadmin_002', 'usr_salesmanager_003')");
    
    // Delete all users with role SALES_EXECUTIVE
    const deleteRes = await client.query("DELETE FROM users WHERE role = 'SALES_EXECUTIVE'");
    console.log(`✅ Deleted ${deleteRes.rowCount} Sales Executives from PostgreSQL.`);

    // Query remaining users
    const remainingPg = await client.query('SELECT employee_id, name, role, email, phone FROM users ORDER BY employee_id ASC');
    console.log('\n--- REMAINING USERS IN POSTGRESQL ---');
    remainingPg.rows.forEach(u => {
      console.log(`  • [${u.employee_id}] ${u.name} (${u.role}) | ${u.email}`);
    });

    console.log('\n--- 2. CLEANING LOCAL JSON DATABASE ---');
    const jsonPath = path.join(__dirname, '../../data/liverestro_db.json');
    if (fs.existsSync(jsonPath)) {
      const db = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
      const beforeCount = db.users.length;
      db.users = db.users.filter(u => u.role !== 'SALES_EXECUTIVE');
      if (db.tasks) {
        db.tasks = db.tasks.filter(t => t.assigned_to_id === 'usr_salesmanager_003' || t.assigned_to_id === 'usr_superadmin_001');
      }
      fs.writeFileSync(jsonPath, JSON.stringify(db, null, 2), 'utf8');
      console.log(`✅ Removed ${beforeCount - db.users.length} Sales Executives from liverestro_db.json.`);
      console.log(`Remaining Users in JSON file: ${db.users.length}`);
    }
  } catch (err) {
    console.error('Error removing sales executives:', err);
  } finally {
    client.release();
    await pool.end();
  }
}

purgeSalesExecutives();
