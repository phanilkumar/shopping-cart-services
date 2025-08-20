const express = require('express');
const { exec } = require('child_process');
const cors = require('cors');

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

// Restart service endpoint
app.post('/api/admin/restart-service', async (req, res) => {
  const { serviceId } = req.body;
  
  if (!serviceId) {
    return res.status(400).json({ success: false, error: 'Service ID is required' });
  }

  try {
    // Map service IDs to Docker container names
    const containerMap = {
      'api-gateway': 'shopping_cart-api-gateway-1',
      'user-service': 'shopping_cart-user-service-1',
      'product-service': 'shopping_cart-product-service-1',
      'order-service': 'shopping_cart-order-service-1',
      'cart-service': 'shopping_cart-cart-service-1',
      'frontend': 'shopping_cart-frontend-1',
      'notification-service': 'shopping_cart-notification-service-1',
      'wallet-service': 'shopping_cart-wallet-service-1',
      'admin-dashboard': 'shopping_cart-admin-dashboard-1'
    };

    const containerName = containerMap[serviceId];
    if (!containerName) {
      return res.status(400).json({ success: false, error: 'Invalid service ID' });
    }

    // Execute Docker restart command using the socket
    exec(`docker restart ${containerName}`, (error, stdout, stderr) => {
      if (error) {
        console.error('Error restarting service:', error);
        return res.status(500).json({ 
          success: false, 
          error: 'Failed to restart service',
          details: error.message 
        });
      }
      
      console.log(`Service ${serviceId} restarted successfully`);
      res.json({ 
        success: true, 
        message: `Service ${serviceId} restarted successfully`,
        output: stdout 
      });
    });
  } catch (error) {
    console.error('Error in restart service endpoint:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Internal server error',
      details: error.message 
    });
  }
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
