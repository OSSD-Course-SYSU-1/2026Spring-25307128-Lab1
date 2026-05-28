const fs = require('fs');
const path = require('path');

const fixedScripts = ['analyze.js', 'verify.js', 'refactor.js', 'cleanup.js'];
const temporaryScriptNames = [
  'refactor_focus.js',
  'refactor_fix.js',
  'analyze_style.js',
  'verify_build.js',
  'verify_rebuild.js',
  'verify_style.js',
  'verify_final.js',
  'verify_final3.js',
  'verify_final4.js',
  'refactor_homepet.js',
  'refactor_pet.js',
  'refactor_petpage.js',
  'refactor_mood.js',
  'brace_check.js',
  'fix_brace.js',
  'check_avail.js'
];

function exists(filePath) {
  return fs.existsSync(filePath);
}

let failed = false;

fixedScripts.forEach((scriptName) => {
  const scriptPath = path.join('scripts', scriptName);
  if (exists(scriptPath)) {
    console.log('OK: fixed script exists: ' + scriptPath);
  } else {
    console.log('FAIL: missing fixed script: ' + scriptPath);
    failed = true;
  }
});

temporaryScriptNames.forEach((scriptName) => {
  const rootPath = scriptName;
  const scriptPath = path.join('scripts', scriptName);
  if (exists(rootPath) || exists(scriptPath)) {
    console.log('FAIL: temporary script remains: ' + scriptName);
    failed = true;
  }
});

const claudeSettingsPath = path.join('.claude', 'settings.local.json');
if (exists(claudeSettingsPath)) {
  console.log('FAIL: temporary Claude settings remain: ' + claudeSettingsPath);
  failed = true;
}

if (!failed) {
  console.log('Cleanup check: OK');
} else {
  process.exit(1);
}
