import React from 'react';
import { Box, Typography, Card, CardContent, Button } from '@mui/material';

const CheckoutPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Checkout
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Checkout page - Microservices integration demo
      </Typography>
      
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Checkout Form
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            This is where users would complete their purchase.
          </Typography>
          <Button variant="contained" color="primary">
            Complete Order
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CheckoutPage;
