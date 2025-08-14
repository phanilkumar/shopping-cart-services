import React from 'react';
import { Box, Typography, Card, CardContent, Button, Grid } from '@mui/material';
import { useAuth } from '../contexts/AuthContext';

const ProfilePage: React.FC = () => {
  const { user, authMethod, logout } = useAuth();

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        User Profile
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Profile page - Microservices integration demo
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Profile Information
              </Typography>
              {user ? (
                <Box>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Name:</strong> {user.first_name} {user.last_name}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Email:</strong> {user.email}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Phone:</strong> {user.phone || 'Not provided'}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Status:</strong> {user.status}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Role:</strong> {user.role}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Auth Method:</strong> {authMethod}
                  </Typography>
                  <Typography variant="body2" sx={{ mb: 1 }}>
                    <strong>Last Login:</strong> {user.last_login_at ? new Date(user.last_login_at).toLocaleString() : 'Never'}
                  </Typography>
                </Box>
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No user information available
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Account Actions
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Button variant="outlined" color="primary">
                  Edit Profile
                </Button>
                <Button variant="outlined" color="secondary">
                  Change Password
                </Button>
                <Button variant="contained" color="error" onClick={handleLogout}>
                  Logout
                </Button>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ProfilePage;
