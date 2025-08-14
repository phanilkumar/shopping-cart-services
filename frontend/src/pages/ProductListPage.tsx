import React from 'react';
import { Box, Typography, Grid, Card, CardContent } from '@mui/material';

const ProductListPage: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Products
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Product listing page - Microservices integration demo
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">Sample Product 1</Typography>
              <Typography variant="body2" color="text.secondary">
                This is a sample product for demonstration purposes.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">Sample Product 2</Typography>
              <Typography variant="body2" color="text.secondary">
                Another sample product for demonstration purposes.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6">Sample Product 3</Typography>
              <Typography variant="body2" color="text.secondary">
                Yet another sample product for demonstration purposes.
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default ProductListPage;
