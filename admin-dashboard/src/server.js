import express from 'express';
import { exec } from 'child_process';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 3009;

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'admin-dashboard-api',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Get all services status
app.get('/api/admin/services/status', async (req, res) => {
  try {
    exec('docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}"', (error, stdout, stderr) => {
      if (error) {
        console.error('Error getting services status:', error);
        return res.status(500).json({ 
          success: false, 
          error: 'Failed to get services status',
          details: error.message 
        });
      }
      
      try {
        const services = stdout.trim().split('\n').map(line => {
          const [name, status, ports] = line.split('\t');
          return { name, status, ports };
        });
        res.json({ 
          success: true, 
          services 
        });
      } catch (parseError) {
        res.status(500).json({ 
          success: false, 
          error: 'Failed to parse services status',
          details: parseError.message 
        });
      }
    });
  } catch (error) {
    console.error('Error in services status endpoint:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error',
      details: error.message 
    });
  }
});

app.listen(PORT, () => {
  console.log(`Admin Dashboard API server running on port ${PORT}`);
});
