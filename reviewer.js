const { execSync } = require('child_process');

try {
  execSync('npm test', { cwd: __dirname, stdio: 'pipe' });
  console.log('PASS');
  console.log('Reason: npm test exited 0');
} catch (err) {
  const out = (err.stdout || '').toString();
  const lines = out.split(/\r?\n/).filter(l => l.includes('AssertionError') || l.includes('actual') || l.includes('expected'));
  console.log('FAIL');
  console.log('Reason: tests did not pass');
  for (const line of lines.slice(0, 3)) {
    console.log('  ' + line.trim());
  }
}
