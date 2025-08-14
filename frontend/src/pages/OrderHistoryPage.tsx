import React from 'react';
import { Box, Typography, Card, CardContent } from '@mui/material';

const OrderHistoryPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Order History
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Order history page - Microservices integration demo
      </Typography>
      
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            No Orders Found
          </Typography>
          <Typography variant="body2" color="text.secondary">
            You haven't placed any orders yet. Start shopping to see your order history here.
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default OrderHistoryPage;
