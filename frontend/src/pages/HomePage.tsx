import React from 'react';
import { Box, Typography, Grid, Card, CardContent, Button } from '@mui/material';
import { useAuth } from '../contexts/AuthContext';

const HomePage: React.FC = () => {
  const { user, isAuthenticated, authMethod } = useAuth();

  return (
    <Box>
      <Typography variant="h3" component="h1" gutterBottom>
        Welcome to E-commerce
      </Typography>
      
      <Typography variant="h5" color="text.secondary" sx={{ mb: 4 }}>
        Microservices Architecture Demo
      </Typography>

      {isAuthenticated && user ? (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Welcome back, {user.first_name}!
            </Typography>
            <Typography variant="body2" color="text.secondary">
              You are logged in via {authMethod} service.
            </Typography>
          </CardContent>
        </Card>
      ) : (
        <Card sx={{ mb: 4 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Get Started
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              Please log in to access your account and start shopping.
            </Typography>
            <Button variant="contained" color="primary" href="/login">
              Login
            </Button>
          </CardContent>
        </Card>
      )}

      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🛍️ Products
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Browse our collection of products with detailed information and reviews.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🔐 Authentication
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Secure login with traditional email/password or OAuth providers.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                🏗️ Microservices
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Built with modern microservices architecture for scalability and reliability.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default HomePage;

