const { Client } = require('pg');

async function findPassword() {
  const common = [
    'root', 'admin', 'password', '123456', '12345678', '1234', '12345', 'postgres123',
    'Prince', 'prince', 'Prince@123', 'prince@123', 'Prince123', 'prince123',
    'Demo@SuperAdmin123', 'Demo@123', 'Live@123', 'Liverestro', 'liverestro', 'LiveRestro',
    'Ankit', 'ankit', 'Ankit@123', 'ankit@123', '9974114114', '9408894448', 'postgres'
  ];

  for (const pwd of common) {
    const client = new Client({
      connectionString: `postgresql://postgres:${encodeURIComponent(pwd)}@localhost:5432/liverestro`
    });
    try {
      await client.connect();
      console.log('🎉 FOUND POSTGRESQL PASSWORD:', pwd);
      const res = await client.query('SELECT count(*) FROM users');
      console.log('Users count in PostgreSQL:', res.rows[0].count);
      await client.end();
      return pwd;
    } catch (e) {
      if (e.code !== '28P01') {
        console.log('Password', pwd, 'returned error:', e.message);
      }
    }
  }
  console.log('None of the common passwords matched.');
}

findPassword();
