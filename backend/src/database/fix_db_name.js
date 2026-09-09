const { Client } = require('pg');

async function fixDbName() {
  const client = new Client({
    connectionString: 'postgresql://postgres:Dhruvisha@localhost:5432/postgres'
  });
  await client.connect();
  try {
    await client.query("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'liverestro ' AND pid != pg_backend_pid()");
    await client.query('ALTER DATABASE "liverestro " RENAME TO liverestro');
    console.log('✅ Successfully renamed database "liverestro " to "liverestro"!');
  } catch (err) {
    console.log('Notice:', err.message);
  } finally {
    await client.end();
  }
}

fixDbName();
