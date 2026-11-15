// Static file server with gzip/brotli for the T-009 Lighthouse probe.
const http = require('http');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const root = path.resolve(process.argv[2] || '.');
const port = Number(process.argv[3] || 8099);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.symbols': 'text/plain; charset=utf-8',
  '.map': 'application/json; charset=utf-8',
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);
  let file = path.join(root, urlPath === '/' ? 'index.html' : urlPath);
  if (!file.startsWith(root)) {
    res.writeHead(403).end();
    return;
  }
  if (fs.existsSync(file) && fs.statSync(file).isDirectory()) {
    file = path.join(file, 'index.html');
  }
  if (!fs.existsSync(file)) {
    res.writeHead(404, { 'content-type': 'text/plain' }).end('not found');
    return;
  }
  const body = fs.readFileSync(file);
  const ext = path.extname(file).toLowerCase();
  const accept = String(req.headers['accept-encoding'] || '');
  const headers = {
    'content-type': types[ext] || 'application/octet-stream',
    'cache-control': 'no-store',
    vary: 'accept-encoding',
  };
  if (accept.includes('br') && body.length > 512) {
    headers['content-encoding'] = 'br';
    res.writeHead(200, headers).end(zlib.brotliCompressSync(body));
    return;
  }
  if (accept.includes('gzip') && body.length > 512) {
    headers['content-encoding'] = 'gzip';
    res.writeHead(200, headers).end(zlib.gzipSync(body, { level: 9 }));
    return;
  }
  headers['content-length'] = body.length;
  res.writeHead(200, headers).end(body);
});

server.listen(port, '127.0.0.1', () => {
  console.log(`serving ${root} on http://127.0.0.1:${port}`);
});
