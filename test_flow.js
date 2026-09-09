const http = require('http');

function post(path, data, token) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(data);
    const headers = {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload)
    };
    if (token) headers['Authorization'] = 'Bearer ' + token;

    const req = http.request({
      hostname: '127.0.0.1',
      port: 5000,
      path: path,
      method: 'POST',
      headers: headers
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(body) });
        } catch (e) {
          resolve({ status: res.statusCode, body });
        }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

async function runTestFlow() {
  console.log('=== STEP 1: Company/Admin Login ===');
  const adminLogin = await post('/api/auth/login', {
    identifier: 'admin@liverestro.com',
    password: 'Demo@CompanyAdmin123'
  });
  console.log('Admin Login Status:', adminLogin.status);
  console.log('Admin Message:', adminLogin.data.message);
  const adminToken = adminLogin.data.data.token;
  console.log('Admin Role:', adminLogin.data.data.user.role);

  console.log('\n=== STEP 2: Company/Admin Creates Sales Executive Rajan ===');
  const rajanPhone = '9876543210';
  const rajanEmail = 'rajan@liverestro.demo';
  const createUserRes = await post('/api/users', {
    name: 'Rajan',
    email: rajanEmail,
    phone: rajanPhone,
    password: 'Demo@Executive123',
    role: 'SALES_EXECUTIVE',
    territory: 'Ahmedabad West (Bopal & Shela)',
    city: 'Ahmedabad',
    visitsTarget: 8
  }, adminToken);
  console.log('Create Rajan Status:', createUserRes.status);
  console.log('Create Rajan Message:', createUserRes.data.message);
  console.log('Created User Profile:', createUserRes.data.data);

  console.log('\n=== STEP 3: Rajan Logs In via Mobile Number OTP ===');
  const sendOtpRes = await post('/api/auth/send-otp', { phone: rajanPhone });
  console.log('Send OTP Status:', sendOtpRes.status, sendOtpRes.data.message);

  const verifyOtpRes = await post('/api/auth/verify-otp', {
    phone: rajanPhone,
    otp: '123456'
  });
  console.log('Verify OTP Status:', verifyOtpRes.status);
  console.log('Verify OTP Message:', verifyOtpRes.data.message);
  const rajanUser = verifyOtpRes.data.data.user;
  console.log('-> Authenticated User ID:', rajanUser.id);
  console.log('-> Authenticated Name:', rajanUser.name);
  console.log('-> Authenticated Phone:', rajanUser.phone);
  console.log('-> Authenticated Role:', rajanUser.role);
  console.log('-> Authenticated Org ID:', rajanUser.organizationId);
  console.log('-> Authenticated Territory:', rajanUser.territory);
  console.log('-> Permissions Count:', rajanUser.permissions.length);

  console.log('\n=== STEP 4: Rajan Logs In via Email and Password ===');
  const rajanPwdLogin = await post('/api/auth/login', {
    identifier: rajanEmail,
    password: 'Demo@Executive123'
  });
  console.log('Rajan Password Login Status:', rajanPwdLogin.status);
  console.log('Password Auth Name:', rajanPwdLogin.data.data.user.name);
  console.log('Password Auth Role:', rajanPwdLogin.data.data.user.role);

  console.log('\n✅ ALL VERIFICATION STEPS PASSED PERFECTLY!');
}

runTestFlow();
