import React from 'react';
import { Box, Typography, Card, CardContent, Button } from '@mui/material';

const ProductDetailPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Product Details
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Product detail page - Microservices integration demo
      </Typography>
      
      <Card>
        <CardContent>
          <Typography variant="h5" gutterBottom>
            Sample Product
          </Typography>
          <Typography variant="body1" sx={{ mb: 2 }}>
            This is a detailed view of a sample product for demonstration purposes.
          </Typography>
          <Button variant="contained" color="primary">
            Add to Cart
          </Button>
        </CardContent>
      </Card>
    </Box>
  );
};

export default ProductDetailPage;
