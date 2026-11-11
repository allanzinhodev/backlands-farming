'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const net = require('node:net');
const { once } = require('node:events');
const { WebSocket } = require('ws');
const { createServer } = require('./server.cjs');

async function fixture(t) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'backlands-astra-web-'));
  fs.writeFileSync(path.join(directory, 'astraclient.html'), '<html>test</html>');
  fs.writeFileSync(path.join(directory, 'astraclient.wasm'), Buffer.from([0, 97, 115, 109, 0, 255]));
  fs.writeFileSync(path.join(directory, '.env'), 'must never be served');
  const login = net.createServer(socket => socket.pipe(socket));
  const game = net.createServer(socket => socket.end(Buffer.from([0, 255, 17, 0])));
  login.listen(0, '127.0.0.1'); game.listen(0, '127.0.0.1');
  await Promise.all([once(login, 'listening'), once(game, 'listening')]);
  const server = createServer({ directory, loginPort: login.address().port, gamePort: game.address().port });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  t.after(() => {
    server.closeAllConnections(); server.close(); login.close(); game.close();
    fs.rmSync(directory, { recursive: true, force: true });
  });
  return { base: `http://127.0.0.1:${server.address().port}`, server };
}

test('serves the build with WASM isolation, ranges and trusted WS routes', async t => {
  const { base } = await fixture(t);
  const page = await fetch(base + '/');
  assert.equal(page.status, 200);
  assert.equal(page.headers.get('cross-origin-opener-policy'), 'same-origin');
  assert.equal(page.headers.get('cross-origin-embedder-policy'), 'require-corp');
  assert.match(await page.text(), /<html>test/);
  const wasm = await fetch(base + '/astraclient.wasm', { headers: { Range: 'bytes=1-3' } });
  assert.equal(wasm.status, 206);
  assert.equal(wasm.headers.get('content-type'), 'application/wasm');
  assert.deepEqual(Buffer.from(await wasm.arrayBuffer()), Buffer.from([97, 115, 109]));
  assert.equal((await fetch(base + '/astraclient.wasm', { headers: { Range: 'bytes=99-' } })).status, 416);
  assert.match(await (await fetch(base + '/config.js?gameHost=evil.example')).text(), /127\.0\.0\.1:7171/);
  assert.equal((await fetch(base + '/.env')).status, 404);
  assert.equal((await fetch(base + '/%2e%2e%2f.env')).status, 404);
  assert.equal((await fetch(base + '/', { method: 'POST' })).status, 405);
});

test('login bridge preserves binary zero bytes and game uses its separate TCP route', async t => {
  const { base } = await fixture(t);
  const ws = new WebSocket(base.replace('http:', 'ws:') + '/login', { origin: 'http://127.0.0.1:8088' });
  t.after(() => ws.terminate());
  await once(ws, 'open');
  const echoed = once(ws, 'message');
  const bytes = Buffer.from([0, 0, 255, 128, 1, 2, 0, 3]);
  ws.send(bytes);
  const [received, binary] = await echoed;
  assert.ok(binary); assert.deepEqual(received, bytes);
  const game = new WebSocket(base.replace('http:', 'ws:') + '/game', { origin: 'http://localhost:8088' });
  t.after(() => game.terminate());
  const message = once(game, 'message');
  const [greeting] = await message;
  assert.deepEqual(greeting, Buffer.from([0, 255, 17, 0]));
});

test('rejects cross-site upgrades, unknown routes and text frames', async t => {
  const { base } = await fixture(t);
  for (const [route, origin] of [['/login', 'https://evil.example'], ['/unknown', 'http://127.0.0.1:8088']]) {
    const denied = new WebSocket(base.replace('http:', 'ws:') + route, { origin });
    const [error] = await once(denied, 'error');
    assert.match(error.message, /403/);
  }
  const text = new WebSocket(base.replace('http:', 'ws:') + '/login', { origin: 'http://127.0.0.1:8088' });
  await once(text, 'open');
  const closed = once(text, 'close'); text.send('not a TCP packet');
  assert.equal((await closed)[0], 1008);
});
