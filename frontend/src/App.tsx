import React, { useState, useEffect } from 'react';
import { Box, Typography, Container, Button, Alert } from '@mui/material';
import { UserProvider, useUser } from './contexts/UserContext';
import AuthPage from './pages/AuthPage';
import DashboardPage from './pages/DashboardPage';
import UserProfile from './components/user/UserProfile';

// Main App Content
const AppContent: React.FC = () => {
  const { state } = useUser();
  const [currentPage, setCurrentPage] = useState<'auth' | 'dashboard' | 'profile'>('auth');

  // Auto-redirect based on authentication status
  useEffect(() => {
    console.log('Auth state changed:', { isAuthenticated: state.isAuthenticated, currentPage });
    
    if (state.isAuthenticated && currentPage === 'auth') {
      console.log('Redirecting to dashboard');
      setCurrentPage('dashboard');
    } else if (!state.isAuthenticated && currentPage !== 'auth') {
      // Only redirect to auth if we're not already on auth page
      // This allows the congratulations popup to show properly
      console.log('Redirecting to auth');
      setCurrentPage('auth');
    }
  }, [state.isAuthenticated, currentPage]);

  // Show loading state
  if (state.isLoading) {
    return (
      <Container maxWidth="lg">
        <Box sx={{ py: 4, textAlign: 'center' }}>
          <Typography variant="h6">Loading...</Typography>
        </Box>
      </Container>
    );
  }

  // Render appropriate page based on current state
  switch (currentPage) {
    case 'auth':
      return <AuthPage />;
    case 'dashboard':
      return <DashboardPage />;
    case 'profile':
      return <UserProfile />;
    default:
      return <AuthPage />;
  }
};

// Main App Component with User Provider
function App() {
  return (
    <UserProvider>
      <AppContent />
    </UserProvider>
  );
}

export default App;

