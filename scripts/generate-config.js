// scripts/generate-config.js
// Simple build script that reads SUPABASE_URL and SUPABASE_ANON_KEY from the environment
// and writes a config.js file that the client can load at runtime.
const fs = require('fs');
const path = require('path');
const tpl = fs.readFileSync(path.join(__dirname, '..', 'config.template.js'), 'utf8');
const out = tpl
  .replace('REPLACE_SB_URL', process.env.SUPABASE_URL || '')
  .replace('REPLACE_SB_KEY', process.env.SUPABASE_ANON_KEY || '');
fs.writeFileSync(path.join(__dirname, '..', 'config.js'), out);
console.log('Wrote config.js');
