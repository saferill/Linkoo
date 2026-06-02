/**
 * ============================================================================
 * Linko WebRTC Signaling Server — Cloudflare Worker (Standalone In-Memory)
 * 100% Free & No Complex Bindings Required
 * Linko WebRTC Protocol v1
 * ============================================================================
 */

// In-memory active peer sessions: WebSocket -> ClientInfo
const sessions = new Map();

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // 1. Health Check Endpoint
    if (url.pathname === '/' || url.pathname === '/health') {
      return new Response(JSON.stringify({
        status: 'online',
        server: 'Linko WebRTC Signaling Hub',
        version: '1.0.0',
        activePeers: sessions.size
      }), {
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      });
    }

    // 2. WebSocket Upgrade Endpoint: /v1/ws
    if (url.pathname === '/v1/ws') {
      const upgradeHeader = request.headers.get('Upgrade');
      if (!upgradeHeader || upgradeHeader.toLowerCase() !== 'websocket') {
        return new Response('Expected WebSocket connection.', { status: 426 });
      }

      const rawData = url.searchParams.get('d');
      if (!rawData) {
        return new Response('Missing registration payload (?d=)', { status: 400 });
      }

      let clientInfoWithoutId;
      try {
        const decoded = atob(rawData);
        clientInfoWithoutId = JSON.parse(decoded);
      } catch (e) {
        return new Response('Invalid base64 payload', { status: 400 });
      }

      const webSocketPair = new WebSocketPair();
      const [clientSocket, serverSocket] = Object.values(webSocketPair);

      serverSocket.accept();

      const clientId = crypto.randomUUID();
      const clientInfo = {
        id: clientId,
        alias: clientInfoWithoutId.alias || 'Unknown Device',
        version: clientInfoWithoutId.version || '2.2',
        deviceModel: clientInfoWithoutId.deviceModel || null,
        deviceType: clientInfoWithoutId.deviceType || null,
        token: clientInfoWithoutId.token || ''
      };

      // 1. Send HELLO message with list of existing active peers
      const existingPeers = Array.from(sessions.values());
      try {
        serverSocket.send(JSON.stringify({
          type: 'HELLO',
          client: clientInfo,
          peers: existingPeers
        }));
      } catch (e) {}

      // 2. Broadcast JOIN to all existing peers
      const joinMsg = JSON.stringify({
        type: 'JOIN',
        peer: clientInfo
      });
      for (const [socket] of sessions) {
        try {
          socket.send(joinMsg);
        } catch (err) {}
      }

      // Store in active sessions map
      sessions.set(serverSocket, clientInfo);

      // 3. Handle incoming WebSocket messages (Offer, Answer, Update)
      serverSocket.addEventListener('message', (event) => {
        try {
          const msg = JSON.parse(event.data);
          const senderInfo = sessions.get(serverSocket);
          if (!senderInfo) return;

          switch (msg.type) {
            case 'UPDATE': {
              if (msg.info) {
                senderInfo.alias = msg.info.alias || senderInfo.alias;
                senderInfo.deviceModel = msg.info.deviceModel || senderInfo.deviceModel;
                senderInfo.deviceType = msg.info.deviceType || senderInfo.deviceType;
                senderInfo.token = msg.info.token || senderInfo.token;

                const updateMsg = JSON.stringify({
                  type: 'UPDATE',
                  peer: senderInfo
                });
                broadcastExcept(serverSocket, updateMsg);
              }
              break;
            }

            case 'OFFER': {
              const targetSocket = findSocketById(msg.target);
              if (targetSocket) {
                targetSocket.send(JSON.stringify({
                  type: 'OFFER',
                  peer: senderInfo,
                  sessionId: msg.sessionId,
                  sdp: msg.sdp
                }));
              }
              break;
            }

            case 'ANSWER': {
              const targetSocket = findSocketById(msg.target);
              if (targetSocket) {
                targetSocket.send(JSON.stringify({
                  type: 'ANSWER',
                  peer: senderInfo,
                  sessionId: msg.sessionId,
                  sdp: msg.sdp
                }));
              }
              break;
            }
          }
        } catch (err) {
          console.error('Error handling message:', err);
        }
      });

      // 4. Handle Disconnect / Close
      const closeHandler = () => {
        const exitingInfo = sessions.get(serverSocket);
        if (exitingInfo) {
          sessions.delete(serverSocket);
          const leftMsg = JSON.stringify({
            type: 'LEFT',
            peerId: exitingInfo.id
          });
          broadcast(leftMsg);
        }
      };

      serverSocket.addEventListener('close', closeHandler);
      serverSocket.addEventListener('error', closeHandler);

      return new Response(null, {
        status: 101,
        webSocket: clientSocket
      });
    }

    return new Response('Not Found', { status: 404 });
  }
};

function broadcast(message) {
  for (const [socket] of sessions) {
    try {
      socket.send(message);
    } catch (err) {}
  }
}

function broadcastExcept(excludeSocket, message) {
  for (const [socket] of sessions) {
    if (socket !== excludeSocket) {
      try {
        socket.send(message);
      } catch (err) {}
    }
  }
}

function findSocketById(id) {
  for (const [socket, info] of sessions) {
    if (info.id === id) {
      return socket;
    }
  }
  return null;
}
