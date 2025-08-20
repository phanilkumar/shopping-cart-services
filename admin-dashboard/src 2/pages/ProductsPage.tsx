import React from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  CardMedia,
  Chip,
  CircularProgress,
  Alert,
} from '@mui/material';
import { useQuery } from 'react-query';
import { Helmet } from 'react-helmet-async';
import { adminAPI } from '../services/api/adminAPI';

const ProductsPage: React.FC = () => {
  const { data: products, isLoading, error } = useQuery('products', () =>
    adminAPI.getProducts()
  );

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">Error loading products: {(error as any)?.message || 'Unknown error'}</Alert>
      </Box>
    );
  }

  return (
    <>
      <Helmet>
        <title>Products Management - Admin Panel</title>
      </Helmet>
      
      <Box sx={{ p: 3 }}>
        <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 600 }}>
          Products Management
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Manage your e-commerce products and inventory.
        </Typography>

        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              All Products ({products?.length || 0})
            </Typography>
            
            <Grid container spacing={3} sx={{ mt: 2 }}>
              {products?.map((product: any) => (
                <Grid item xs={12} sm={6} md={4} lg={3} key={product.id}>
                  <Card sx={{ height: '100%' }}>
                    <CardMedia
                      component="img"
                      height="200"
                      image={product.image_url}
                      alt={product.name}
                      sx={{ objectFit: 'cover' }}
                    />
                    <CardContent>
                      <Typography variant="h6" component="h3" gutterBottom>
                        {product.name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                        {product.description}
                      </Typography>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                        <Typography variant="h6" color="primary">
                          ${product.price}
                        </Typography>
                        {product.sale_price && (
                          <Typography variant="body2" color="error" sx={{ textDecoration: 'line-through' }}>
                            ${product.sale_price}
                          </Typography>
                        )}
                      </Box>
                      <Box sx={{ display: 'flex', gap: 1, mb: 1 }}>
                        <Chip label={product.category} size="small" />
                        {product.is_featured && (
                          <Chip label="Featured" color="primary" size="small" />
                        )}
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        Stock: {product.stock_quantity} units
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </CardContent>
        </Card>
      </Box>
    </>
  );
};

export default ProductsPage;
