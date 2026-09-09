const crypto = require('crypto');

const BASE32_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

function base32Decode(str) {
  if (!str || typeof str !== 'string') return Buffer.alloc(0);
  const clean = str.toUpperCase().replace(/[\s\-=]/g, '');
  let bits = 0;
  let value = 0;
  const output = [];

  for (let i = 0; i < clean.length; i++) {
    const idx = BASE32_ALPHABET.indexOf(clean[i]);
    if (idx === -1) continue;
    value = (value << 5) | idx;
    bits += 5;
    if (bits >= 8) {
      output.push((value >>> (bits - 8)) & 255);
      bits -= 8;
    }
  }
  return Buffer.from(output);
}

function base32Encode(buffer) {
  if (!buffer || buffer.length === 0) return '';
  let bits = 0;
  let value = 0;
  let output = '';

  for (let i = 0; i < buffer.length; i++) {
    value = (value << 8) | buffer[i];
    bits += 8;
    while (bits >= 5) {
      output += BASE32_ALPHABET[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }
  if (bits > 0) {
    output += BASE32_ALPHABET[(value << (5 - bits)) & 31];
  }
  return output;
}

function generateSecret(numBytes = 20) {
  const bytes = crypto.randomBytes(numBytes);
  return base32Encode(bytes);
}

function generateTotp(secret, timeStepOffset = 0, timestampMs = Date.now()) {
  const key = base32Decode(secret);
  if (key.length === 0) return '';

  const epochSeconds = Math.floor(timestampMs / 1000);
  const timeStep = Math.floor(epochSeconds / 30) + timeStepOffset;

  const buf = Buffer.alloc(8);
  buf.writeBigUInt64BE(BigInt(timeStep), 0);

  const hmac = crypto.createHmac('sha1', key).update(buf).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;
  const code =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);

  return (code % 1000000).toString().padStart(6, '0');
}

function verifyTotp(inputCode, secret, window = 1, timestampMs = Date.now()) {
  if (!inputCode || !secret) return false;
  const cleanCode = String(inputCode).trim().replace(/\D/g, '');
  if (cleanCode.length !== 6) return false;

  for (let offset = -window; offset <= window; offset++) {
    const expected = generateTotp(secret, offset, timestampMs);
    if (expected.length === 6 && expected === cleanCode) {
      return true;
    }
  }
  return false;
}

function generateUri({ secret, accountName, issuer = 'LiveRestro CRM' }) {
  const cleanSecret = String(secret || '').toUpperCase().replace(/[\s\-=]/g, '');
  const label = `${issuer}:${accountName || 'User'}`;
  return `otpauth://totp/${encodeURIComponent(label)}?secret=${cleanSecret}&issuer=${encodeURIComponent(issuer)}&algorithm=SHA1&digits=6&period=30`;
}

module.exports = {
  generateSecret,
  generateTotp,
  verifyTotp,
  generateUri,
  base32Decode,
  base32Encode
};
