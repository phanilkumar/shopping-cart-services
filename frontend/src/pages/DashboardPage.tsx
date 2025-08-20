import React from 'react';
import {
  Box,
  Container,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  CardActions,
  Button,
  Avatar,
  Chip,
  Divider,
} from '@mui/material';
import {
  Person as PersonIcon,
  ShoppingCart as CartIcon,
  ShoppingBag as OrdersIcon,
  Favorite as WishlistIcon,
  Settings as SettingsIcon,
  ExitToApp as LogoutIcon,
} from '@mui/icons-material';
import { useUser } from '../contexts/UserContext';

const DashboardPage: React.FC = () => {
  const { state, logout } = useUser();

  const handleLogout = async () => {
    await logout();
    window.location.href = '/auth';
  };

  const dashboardItems = [
    {
      title: 'My Profile',
      description: 'View and edit your profile information',
      icon: <PersonIcon sx={{ fontSize: 40 }} />,
      color: '#1976d2',
      link: '/profile',
    },
    {
      title: 'My Orders',
      description: 'Track your order history and status',
      icon: <OrdersIcon sx={{ fontSize: 40 }} />,
      color: '#2e7d32',
      link: '/orders',
    },
    {
      title: 'Shopping Cart',
      description: 'View items in your cart',
      icon: <CartIcon sx={{ fontSize: 40 }} />,
      color: '#ed6c02',
      link: '/cart',
    },
    {
      title: 'Wishlist',
      description: 'Manage your saved items',
      icon: <WishlistIcon sx={{ fontSize: 40 }} />,
      color: '#d32f2f',
      link: '/wishlist',
    },
    {
      title: 'Settings',
      description: 'Account and privacy settings',
      icon: <SettingsIcon sx={{ fontSize: 40 }} />,
      color: '#7b1fa2',
      link: '/settings',
    },
  ];

  if (!state.user) {
    return (
      <Container maxWidth="lg">
        <Box sx={{ mt: 4, textAlign: 'center' }}>
          <Typography variant="h6">Loading dashboard...</Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg">
      <Box sx={{ mt: 4, mb: 4 }}>
        {/* Welcome Header */}
        <Paper elevation={2} sx={{ p: 3, mb: 4 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Avatar
                sx={{
                  width: 64,
                  height: 64,
                  bgcolor: 'primary.main',
                  fontSize: '1.5rem',
                  mr: 2,
                }}
              >
                {state.user.first_name.charAt(0).toUpperCase()}
              </Avatar>
              <Box>
                <Typography variant="h4" component="h1" gutterBottom>
                  Welcome back, {state.user.first_name}!
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  Here's what's happening with your account
                </Typography>
              </Box>
            </Box>
            <Box>
              <Chip
                label={state.user.role === 1 ? 'admin' : 'user'}
                color={state.user.role === 1 ? 'error' : 'primary'}
                sx={{ mr: 1 }}
              />
              <Chip
                label={state.user.status === 1 ? 'active' : 'inactive'}
                color={state.user.status === 1 ? 'success' : 'warning'}
              />
            </Box>
          </Box>
        </Paper>

        {/* Dashboard Grid */}
        <Grid container spacing={3}>
          {dashboardItems.map((item, index) => (
            <Grid item xs={12} sm={6} md={4} key={index}>
              <Card
                sx={{
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  transition: 'transform 0.2s ease-in-out',
                  '&:hover': {
                    transform: 'translateY(-4px)',
                    boxShadow: 4,
                  },
                }}
              >
                <CardContent sx={{ flexGrow: 1, textAlign: 'center' }}>
                  <Box
                    sx={{
                      display: 'flex',
                      justifyContent: 'center',
                      mb: 2,
                    }}
                  >
                    <Box
                      sx={{
                        p: 2,
                        borderRadius: '50%',
                        bgcolor: `${item.color}15`,
                        color: item.color,
                      }}
                    >
                      {item.icon}
                    </Box>
                  </Box>
                  <Typography variant="h6" component="h2" gutterBottom>
                    {item.title}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {item.description}
                  </Typography>
                </CardContent>
                <CardActions sx={{ justifyContent: 'center', pb: 2 }}>
                  <Button
                    size="small"
                    variant="outlined"
                    onClick={() => {
                      // TODO: Implement navigation
                      console.log(`Navigate to ${item.link}`);
                    }}
                  >
                    View {item.title}
                  </Button>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>

        {/* Quick Actions */}
        <Paper elevation={2} sx={{ p: 3, mt: 4 }}>
          <Typography variant="h6" gutterBottom>
            Quick Actions
          </Typography>
          <Divider sx={{ mb: 2 }} />
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <Button
              variant="outlined"
              startIcon={<PersonIcon />}
              onClick={() => {
                // TODO: Navigate to profile
                console.log('Navigate to profile');
              }}
            >
              Edit Profile
            </Button>
            <Button
              variant="outlined"
              startIcon={<SettingsIcon />}
              onClick={() => {
                // TODO: Navigate to settings
                console.log('Navigate to settings');
              }}
            >
              Account Settings
            </Button>
            <Button
              variant="outlined"
              color="error"
              startIcon={<LogoutIcon />}
              onClick={handleLogout}
            >
              Logout
            </Button>
          </Box>
        </Paper>

        {/* User Stats */}
        <Paper elevation={2} sx={{ p: 3, mt: 4 }}>
          <Typography variant="h6" gutterBottom>
            Account Information
          </Typography>
          <Divider sx={{ mb: 2 }} />
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="body2" color="text.secondary">
                Email
              </Typography>
              <Typography variant="body1">{state.user.email}</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="body2" color="text.secondary">
                Phone
              </Typography>
              <Typography variant="body1">{state.user.phone}</Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="body2" color="text.secondary">
                Member Since
              </Typography>
              <Typography variant="body1">
                {new Date(state.user.created_at).toLocaleDateString()}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Typography variant="body2" color="text.secondary">
                Last Login
              </Typography>
              <Typography variant="body1">
                {state.user.last_login_at
                  ? new Date(state.user.last_login_at).toLocaleDateString()
                  : 'Never'}
              </Typography>
            </Grid>
          </Grid>
        </Paper>
      </Box>
    </Container>
  );
};

export default DashboardPage;
