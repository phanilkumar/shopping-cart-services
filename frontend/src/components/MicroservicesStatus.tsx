import React, { useState, useEffect } from 'react';
import { Box, Card, CardContent, Typography, Button, Chip, Alert } from '@mui/material';
import { CheckCircle, Error, Refresh } from '@mui/icons-material';
import { apiService } from '../services/api';

interface ServiceStatus {
  auth: {
    status: string;
    service: string;
    timestamp: string;
    version: string;
  } | null;
  oauth: {
    status: string;
    service: string;
    timestamp: string;
    version: string;
  } | null;
}

const MicroservicesStatus: React.FC = () => {
  const [status, setStatus] = useState<ServiceStatus>({ auth: null, oauth: null });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkServices = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const health = await apiService.health.checkAll();
      setStatus(health);
    } catch (err) {
      setError('Failed to check service status');
      console.error('Health check error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    checkServices();
  }, []);

  const getStatusIcon = (serviceStatus: any) => {
    if (!serviceStatus) return <Error color="error" />;
    return serviceStatus.status === 'healthy' ? (
      <CheckCircle color="success" />
    ) : (
      <Error color="error" />
    );
  };

  const getStatusColor = (serviceStatus: any) => {
    if (!serviceStatus) return 'error';
    return serviceStatus.status === 'healthy' ? 'success' : 'error';
  };

  return (
    <Card sx={{ mb: 2 }}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6" component="h2">
            Microservices Status
          </Typography>
          <Button
            startIcon={<Refresh />}
            onClick={checkServices}
            disabled={loading}
            size="small"
          >
            Refresh
          </Button>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
          {/* Auth Service Status */}
          <Box sx={{ flex: 1, minWidth: 200 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              {getStatusIcon(status.auth)}
              <Typography variant="subtitle1" fontWeight="bold">
                Auth Service
              </Typography>
              <Chip
                label={status.auth?.status || 'Unknown'}
                color={getStatusColor(status.auth) as any}
                size="small"
              />
            </Box>
            {status.auth && (
              <Typography variant="body2" color="text.secondary">
                Port: 3000 | Version: {status.auth.version}
              </Typography>
            )}
          </Box>

          {/* OAuth Service Status */}
          <Box sx={{ flex: 1, minWidth: 200 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              {getStatusIcon(status.oauth)}
              <Typography variant="subtitle1" fontWeight="bold">
                OAuth Service
              </Typography>
              <Chip
                label={status.oauth?.status || 'Unknown'}
                color={getStatusColor(status.oauth) as any}
                size="small"
              />
            </Box>
            {status.oauth && (
              <Typography variant="body2" color="text.secondary">
                Port: 3001 | Version: {status.oauth.version}
              </Typography>
            )}
          </Box>
        </Box>

        <Typography variant="caption" color="text.secondary" sx={{ mt: 2, display: 'block' }}>
          Last checked: {new Date().toLocaleTimeString()}
        </Typography>
      </CardContent>
    </Card>
  );
};

export default MicroservicesStatus;
