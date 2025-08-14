import React from 'react';
import { Box, Typography, Card, CardContent, Button } from '@mui/material';

const CartPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Shopping Cart
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Cart page - Microservices integration demo
      </Typography>
      
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Your Cart is Empty
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Add some products to your cart to see them here.
          </Typography>
          <Button variant="contained" color="primary">
            Continue Shopping
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
};

export default CartPage;
