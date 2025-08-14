import React from 'react';
import { Box, Typography, Container } from '@mui/material';

function App() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ py: 4 }}>
        <Typography variant="h3" component="h1" gutterBottom>
          🎉 Frontend is Working!
        </Typography>
        <Typography variant="h5" color="text.secondary" gutterBottom>
          React + TypeScript + Material-UI Frontend
        </Typography>
        <Typography variant="body1" sx={{ mt: 2 }}>
          This is a test to verify that the frontend is working correctly.
        </Typography>
        <Box sx={{ mt: 4, p: 3, bgcolor: 'primary.main', color: 'white', borderRadius: 2 }}>
          <Typography variant="h6">
            ✅ Basic Setup Complete
          </Typography>
          <Typography variant="body2" sx={{ mt: 1 }}>
            The frontend is now running successfully. You can now add the full microservices integration.
          </Typography>
        </Box>
      </Box>
    </Container>
  );
}

export default App;

