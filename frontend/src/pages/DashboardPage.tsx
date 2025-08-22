import React from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Button,
  Avatar,
} from '@mui/material';
import { useUser } from '../contexts/UserContext';

const DashboardPage: React.FC = () => {
  const { state, logout } = useUser();

  const handleLogout = async () => {
    await logout();
    window.location.href = '/auth';
  };

  if (!state.user) {
    return (
      <Container maxWidth="md">
        <Box sx={{ mt: 4, textAlign: 'center' }}>
          <Typography variant="h6">Loading...</Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="md">
      <Box sx={{ mt: 4, mb: 4 }}>
        {/* Welcome Header */}
        <Paper elevation={2} sx={{ p: 3, mb: 4 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Avatar
                sx={{
                  width: 60,
                  height: 60,
                  bgcolor: 'primary.main',
                  fontSize: '1.5rem',
                  mr: 2,
                }}
              >
                {state.user.first_name.charAt(0).toUpperCase()}
              </Avatar>
              <Box>
                <Typography variant="h5" component="h1">
                  Welcome, {state.user.first_name}!
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Your account is active
                </Typography>
              </Box>
            </Box>
            <Button
              variant="outlined"
              color="error"
              onClick={handleLogout}
            >
              Logout
            </Button>
          </Box>
        </Paper>

        {/* Simple Info */}
        <Paper elevation={2} sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>
            Your Information
          </Typography>
          <Box sx={{ mt: 2 }}>
            <Typography variant="body1" sx={{ mb: 1 }}>
              <strong>Name:</strong> {state.user.full_name}
            </Typography>
            <Typography variant="body1" sx={{ mb: 1 }}>
              <strong>Email:</strong> {state.user.email}
            </Typography>
            <Typography variant="body1" sx={{ mb: 1 }}>
              <strong>Mobile:</strong> {state.user.phone}
            </Typography>
            <Typography variant="body1">
              <strong>Member since:</strong> {new Date(state.user.created_at).toLocaleDateString()}
            </Typography>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default DashboardPage;
