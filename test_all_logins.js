const http = require('http');

function post(path, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const req = http.request({
      hostname: '127.0.0.1',
      port: 5000,
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve(JSON.parse(body)));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function testAll() {
  const accounts = [
    { label: 'Super Admin', id: '9000000001', pwd: 'Demo@SuperAdmin123', role: 'SUPER_ADMIN' },
    { label: 'Company Admin', id: '9000000002', pwd: 'Demo@CompanyAdmin123', role: 'COMPANY_ADMIN' },
    { label: 'Sales Manager', id: '9000000003', pwd: 'Demo@Manager123', role: 'SALES_MANAGER' },
    { label: 'Sales Executive (Default)', id: '9000000004', pwd: 'Demo@Executive123', role: 'SALES_EXECUTIVE' },
    { label: 'Ankit Chandarana', id: '9974114114', pwd: 'Live@hfVETxjhR8', role: 'SALES_EXECUTIVE' },
    { label: 'Prince', id: '9408894448', pwd: 'Live@p#aYYt3Eho', role: 'SALES_EXECUTIVE' },
    { label: 'Rajan (Newly Created)', id: '9876543210', pwd: 'Demo@Executive123', role: 'SALES_EXECUTIVE' },
  ];

  console.log('--- TESTING ALL EXISTING & NEW MEMBERS VIA OTP LOGIN ---');
  for (const acc of accounts) {
    const otpRes = await post('/api/auth/verify-otp', { phone: acc.id, otp: '123456' });
    if (otpRes.success && otpRes.data && otpRes.data.user) {
      const u = otpRes.data.user;
      console.log(`✓ ${acc.label} (${acc.id}) => Name: "${u.name}", Role: [${u.role}], Dashboard: ${u.role}_DASHBOARD`);
    } else {
      console.log(`✗ ${acc.label} (${acc.id}) => Error: ${otpRes.message}`);
    }
  }

  console.log('\n--- TESTING ALL EXISTING & NEW MEMBERS VIA PASSWORD LOGIN ---');
  for (const acc of accounts) {
    const pwdRes = await post('/api/auth/login', { identifier: acc.id, password: acc.pwd });
    if (pwdRes.success && pwdRes.data && pwdRes.data.user) {
      const u = pwdRes.data.user;
      console.log(`✓ ${acc.label} (${acc.id}) => Name: "${u.name}", Role: [${u.role}], Dashboard: ${u.role}_DASHBOARD`);
    } else {
      console.log(`✗ ${acc.label} (${acc.id}) => Error: ${pwdRes.message}`);
    }
  }
}

testAll();
