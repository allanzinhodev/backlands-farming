'use strict';

const http = require('node:http');
const net = require('node:net');
const fs = require('node:fs');
const path = require('node:path');
const { WebSocketServer, WebSocket } = require('ws');

const MIME = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json',
  '.png': 'image/png', '.wasm': 'application/wasm', '.data': 'application/octet-stream'
};
const LIMIT = 2 * 1024 * 1024;

function createServer({ directory, target = '127.0.0.1', loginPort = 7171, gamePort = 7172,
  port = 8088, idleTimeout = 15 * 60 * 1000 } = {}) {
  const root = fs.realpathSync(directory);
  if (!fs.existsSync(path.join(root, 'astraclient.html')))
    throw new Error('Build AstraClient first: astraclient.html is missing.');
  const origins = new Set([`http://127.0.0.1:${port}`, `http://localhost:${port}`]);
  const routes = new Map([['/login', loginPort], ['/game', gamePort]]);
  const headers = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Resource-Policy': 'same-origin',
    'X-Content-Type-Options': 'nosniff',
    'Cache-Control': 'no-cache'
  };
  const config = Buffer.from('window.ASTRA_CONFIG = ' + JSON.stringify({
    title: 'Backlands · Astra Web (local)',
    websocketOverrides: { '127.0.0.1:7171': '/login', '127.0.0.1:7172': '/game',
      'localhost:7171': '/login', 'localhost:7172': '/game' }
  }) + ';\n');
  const wss = new WebSocketServer({ noServer: true, maxPayload: LIMIT, perMessageDeflate: false });

  const server = http.createServer((req, res) => {
    for (const [key, value] of Object.entries(headers)) res.setHeader(key, value);
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.writeHead(405, { Allow: 'GET, HEAD' }); res.end(); return;
    }
    let pathname;
    try { pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); }
    catch { res.writeHead(400); res.end(); return; }
    if (pathname === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ service: 'backlands-astra-web', ready: true, connections: wss.clients.size }));
      return;
    }
    if (pathname === '/config.js') {
      res.writeHead(200, { 'Content-Type': MIME['.js'], 'Content-Length': config.length });
      res.end(req.method === 'HEAD' ? undefined : config); return;
    }
    if (pathname === '/') pathname = '/astraclient.html';
    if (pathname.includes('\\') || pathname.split('/').some(segment => segment.startsWith('.'))) {
      res.writeHead(404); res.end(); return;
    }
    let file, stat;
    try {
      file = fs.realpathSync(path.join(root, pathname));
      if (!file.startsWith(root + path.sep) || !MIME[path.extname(file)]) throw new Error('Denied');
      stat = fs.statSync(file);
      if (!stat.isFile()) throw new Error('Denied');
    } catch { res.writeHead(404); res.end(); return; }
    let start = 0, end = stat.size - 1, status = 200;
    if (req.headers.range) {
      const range = /^bytes=(\d+)-(\d*)$/.exec(req.headers.range);
      start = range ? Number(range[1]) : -1;
      end = range?.[2] ? Math.min(Number(range[2]), end) : end;
      if (!Number.isSafeInteger(start) || start < 0 || start > end || !Number.isSafeInteger(end)) {
        res.writeHead(416, { 'Content-Range': `bytes */${stat.size}` }); res.end(); return;
      }
      status = 206;
      res.setHeader('Content-Range', `bytes ${start}-${end}/${stat.size}`);
    }
    res.writeHead(status, { 'Content-Type': MIME[path.extname(file)],
      'Content-Length': Math.max(0, end - start + 1), 'Accept-Ranges': 'bytes' });
    if (req.method === 'HEAD' || stat.size === 0) { res.end(); return; }
    const stream = fs.createReadStream(file, { start, end });
    stream.on('error', () => res.destroy());
    res.on('close', () => stream.destroy());
    stream.pipe(res);
  });

  server.on('upgrade', (req, socket, head) => {
    if (!origins.has(req.headers.origin) || !routes.has(req.url) || wss.clients.size >= 16) {
      socket.end('HTTP/1.1 403 Forbidden\r\nConnection: close\r\n\r\n'); return;
    }
    wss.handleUpgrade(req, socket, head, ws => {
      const tcp = net.connect({ host: target, port: routes.get(req.url) });
      tcp.setNoDelay(true);
      tcp.setTimeout(idleTimeout);
      const shutdown = () => {
        tcp.destroy();
        if (ws.readyState === WebSocket.OPEN) ws.close(1001, 'Connection closed');
      };
      ws.on('error', shutdown);
      ws.on('close', () => tcp.destroy());
      tcp.on('error', shutdown);
      tcp.on('timeout', shutdown);
      tcp.on('end', shutdown);
      ws.on('message', (bytes, binary) => {
        if (!binary || tcp.writableLength + bytes.length > LIMIT) { ws.close(1008, 'Binary frames required'); return; }
        if (!tcp.write(bytes)) ws.pause();
      });
      tcp.on('drain', () => ws.resume());
      tcp.on('data', bytes => {
        if (ws.readyState !== WebSocket.OPEN) { tcp.destroy(); return; }
        if (ws.bufferedAmount + bytes.length > LIMIT) { shutdown(); return; }
        tcp.pause();
        ws.send(bytes, { binary: true }, error => { if (error) shutdown(); else tcp.resume(); });
      });
    });
  });
  server.on('close', () => { for (const ws of wss.clients) ws.terminate(); wss.close(); });
  return server;
}

if (require.main === module) {
  const { parseArgs } = require('node:util');
  const { values } = parseArgs({ options: {
    directory: { type: 'string', default: path.resolve(__dirname, '../../_study/AstraClient/build-wasm-release/dist') },
    bind: { type: 'string', default: '127.0.0.1' },
    port: { type: 'string', default: '8088' }, target: { type: 'string', default: '127.0.0.1' }
  } });
  const port = Number(values.port);
  const server = createServer({ directory: values.directory, target: values.target, port });
  server.on('error', error => { console.error(error.message); process.exitCode = 1; });
  server.listen(port, values.bind, () => console.log(`Astra Web: http://127.0.0.1:${port}/astraclient.html`));
}

module.exports = { createServer };
