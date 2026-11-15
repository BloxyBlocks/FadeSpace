const fs = require('fs');
const zlib = require('zlib');

const files = [
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/canvaskit.js',
  'assets/NOTICES',
  'manifest.json',
  'favicon.png',
  'version.json',
];

const out = [];
let tot = 0;
let gz = 0;
let br = 0;

for (const file of files) {
  if (!fs.existsSync(file)) {
    out.push({ file, missing: true });
    continue;
  }
  const buffer = fs.readFileSync(file);
  const gzip = zlib.gzipSync(buffer, { level: 9 }).length;
  const brotli = zlib.brotliCompressSync(buffer, {
    params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 11 },
  }).length;
  tot += buffer.length;
  gz += gzip;
  br += brotli;
  out.push({ file, raw: buffer.length, gzip, brotli });
}

out.push({ file: 'TOTAL(first-load set)', raw: tot, gzip: gz, brotli: br });
process.stdout.write(JSON.stringify(out, null, 2) + '\n');
