
const express = require('express');
const cors = require('cors');

const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const { BackendError } = require('./src/authorization');
const { createAttendanceBackend } = require('./src/attendance_backend');
const { createAccountBackend } = require('./src/account_backend');

const app = express();
app.use(cors());
app.use(express.json({ limit: '100kb' }));

// Configure Firebase Admin using a secret stored on the server.
function initializeFirebase() {
  if (getApps().length > 0) return;

  const rawCredentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!rawCredentials) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not configured.');
  }

  const credentials = JSON.parse(rawCredentials);

  initializeApp({
    credential: cert(credentials),
    projectId: process.env.FIREBASE_PROJECT_ID || credentials.project_id,
  });
}

initializeFirebase();

const db = getFirestore();
const authAdmin = getAuth();

const attendance = createAttendanceBackend({ db, FieldValue });
const accounts = createAccountBackend({
  db,
  FieldValue,
  authAdmin,
});

const routes = {
  'create-session': attendance.createSession,
  'update-session': attendance.updateSession,
  'update-session-status': attendance.updateSessionStatus,
  'list-sessions': attendance.listSessions,
  'get-roster': attendance.getRoster,
  'mark-attendance': attendance.markAttendance,
  'my-attendance': attendance.getOwnHistory,
  'session-summary': attendance.getSessionSummary,
  'set-user-access': accounts.setUserAccess,
};

// Verify the Firebase ID token on every protected request.
app.use('/api', async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    const match = header.match(/^Bearer (.+)$/i);

    if (!match) {
      return res.status(401).json({ error: 'Sign in required.' });
    }

    const decoded = await authAdmin.verifyIdToken(match[1], true);

    req.backendRequest = {
      auth: {
        uid: decoded.uid,
        token: decoded,
      },
      data: req.body || {},
    };

    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired sign-in token.' });
  }
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/:action', async (req, res) => {
  try {
    const handler = routes[req.params.action];

    if (!handler) {
      return res.status(404).json({ error: 'Unknown API action.' });
    }

    const result = await handler(req.backendRequest);
    return res.json(result ?? {});
  } catch (error) {
    if (error instanceof BackendError) {
      const statusCodes = {
        unauthenticated: 401,
        'permission-denied': 403,
        'invalid-argument': 400,
        'not-found': 404,
        'resource-exhausted': 429,
      };

      return res.status(statusCodes[error.code] || 400).json({
        error: error.message,
        code: error.code,
      });
    }

    console.error('Protected API request failed:', error.code || 'unknown');
    return res.status(500).json({
      error: 'The request could not be completed.',
    });
  }
});

const port = Number(process.env.PORT) || 10000;

app.listen(port, '0.0.0.0', () => {
  console.log(`Sports Management API listening on port ${port}`);
});
