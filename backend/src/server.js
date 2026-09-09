const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const { initDatabase, checkDatabaseHealth, closeDatabasePool } = require('./config/database');
const { seed } = require('./database/seed');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const taskRoutes = require('./routes/taskRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const leadRoutes = require('./routes/leadRoutes');
const visitRoutes = require('./routes/visitRoutes');
const aiRoutes = require('./routes/aiRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const followUpRoutes = require('./routes/followUpRoutes');
const targetRoutes = require('./routes/targetRoutes');
const implementationRoutes = require('./routes/implementationRoutes');
const posOrderRoutes = require('./routes/posOrderRoutes');

const app = express();
const PORT = process.env.PORT || 5000;
const NODE_ENV = process.env.NODE_ENV || 'production';

// Production Middleware
app.use(cors({ origin: process.env.CORS_ORIGIN === '*' || !process.env.CORS_ORIGIN ? '*' : process.env.CORS_ORIGIN.split(',') }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
if (NODE_ENV !== 'test') {
  app.use(morgan(NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// Production Comprehensive Health Check (both /health and /api/health)
async function handleHealthCheck(req, res) {
  const dbHealth = await checkDatabaseHealth();
  const memory = process.memoryUsage();
  const isHealthy = dbHealth.connected;

  const payload = {
    status: isHealthy ? 'UP' : 'DEGRADED',
    service: 'LiveRestro CRM Production API',
    version: '1.0.0',
    environment: NODE_ENV,
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    database: dbHealth,
    memory: {
      rssMb: (memory.rss / 1024 / 1024).toFixed(2),
      heapUsedMb: (memory.heapUsed / 1024 / 1024).toFixed(2),
      heapTotalMb: (memory.heapTotal / 1024 / 1024).toFixed(2),
    },
  };

  return res.status(isHealthy ? 200 : 503).json(payload);
}

app.get('/health', handleHealthCheck);
app.get('/api/health', handleHealthCheck);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/leads', leadRoutes);
app.use('/api/visits', visitRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/follow-ups', followUpRoutes);
app.use('/api/targets', targetRoutes);
app.use('/api/implementations', implementationRoutes);
app.use('/api/pos-orders', posOrderRoutes);

// Notifications Endpoint
app.get('/api/notifications', (req, res) => {
  res.status(200).json({
    success: true,
    data: [
      {
        id: 'notif_01',
        title: 'Welcome to LiveRestro CRM',
        body: 'Your account is active. Check out your assigned leads and targets.',
        type: 'SYSTEM',
        read: true,
        createdAt: new Date().toISOString(),
      },
    ],
  });
});

// Fallback 404
app.use((req, res) => {
  res.status(404).json({ success: false, message: `API endpoint '${req.method} ${req.originalUrl}' not found on LiveRestro server.` });
});

// Global Production Error Handler
app.use((err, req, res, next) => {
  console.error('[Production Error Handler]:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    ...(NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

let server = null;

// Bootstrap Database & Start Server
async function start() {
  try {
    await initDatabase();
    await seed();
    server = app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 LiveRestro CRM Production Server running on port ${PORT} [NODE_ENV=${NODE_ENV}]`);
      console.log(`📡 Healthcheck available at: http://0.0.0.0:${PORT}/api/health`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful Shutdown Handlers
async function gracefulShutdown(signal) {
  console.log(`\n🛑 Received ${signal}. Starting graceful shutdown...`);
  if (server) {
    server.close(async () => {
      console.log('🔒 Closed incoming HTTP connections.');
      await closeDatabasePool();
      console.log('✅ Server shutdown cleanly.');
      process.exit(0);
    });

    // Force shutdown after 10s if hanging
    setTimeout(() => {
      console.error('⚠️ Forcefully terminating after timeout.');
      process.exit(1);
    }, 10000);
  } else {
    process.exit(0);
  }
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

process.on('uncaughtException', (err) => {
  console.error('💥 Uncaught Exception:', err);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('💥 Unhandled Rejection at:', promise, 'reason:', reason);
});

start();

