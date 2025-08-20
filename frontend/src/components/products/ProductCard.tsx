import React from 'react';
import {
  Card,
  CardMedia,
  CardContent,
  Typography,
  Button,
  Box,
  Chip,
  Rating,
  IconButton,
  Tooltip,
  useTheme,
} from '@mui/material';
import {
  ShoppingCart,
  Favorite,
  FavoriteBorder,
  Visibility,
} from '@mui/icons-material';
import { useCart } from '../../contexts/CartContext';

interface ProductCardProps {
  product: {
    id: string;
    name: string;
    price: number;
    sale_price?: number;
    sku: string;
    slug: string;
    primary_image?: {
      image_url: string;
    };
    average_rating?: number;
    review_count?: number;
    stock_quantity?: number;
    featured?: boolean;
    on_sale?: boolean;
  };
  onAddToCart: () => void;
  onViewProduct: () => void;
  onToggleFavorite?: () => void;
  isFavorite?: boolean;
  showActions?: boolean;
}

const ProductCard: React.FC<ProductCardProps> = ({
  product,
  onAddToCart,
  onViewProduct,
  onToggleFavorite,
  isFavorite = false,
  showActions = true,
}) => {
  const theme = useTheme();
  const { isInCart, getItemQuantity } = useCart();
  
  const isInCartItem = isInCart(product.id);
  const cartQuantity = getItemQuantity(product.id);
  const isOutOfStock = (product.stock_quantity || 0) <= 0;
  const displayPrice = product.sale_price || product.price;
  const originalPrice = product.sale_price ? product.price : null;
  const discountPercentage = product.sale_price 
    ? Math.round(((product.price - product.sale_price) / product.price) * 100)
    : 0;

  const handleAddToCart = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (!isOutOfStock) {
      onAddToCart();
    }
  };

  const handleViewProduct = (e: React.MouseEvent) => {
    e.stopPropagation();
    onViewProduct();
  };

  const handleToggleFavorite = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (onToggleFavorite) {
      onToggleFavorite();
    }
  };

  return (
    <Card
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        cursor: 'pointer',
        transition: 'transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out',
        '&:hover': {
          transform: 'translateY(-4px)',
          boxShadow: theme.shadows[8],
        },
        position: 'relative',
        overflow: 'visible',
      }}
      onClick={onViewProduct}
    >
      {/* Product Image */}
      <Box sx={{ position: 'relative' }}>
        <CardMedia
          component="img"
          height="200"
          image={product.primary_image?.image_url || '/placeholder-product.jpg'}
          alt={product.name}
          sx={{
            objectFit: 'cover',
            backgroundColor: 'grey.100',
          }}
        />
        
        {/* Badges */}
        <Box
          sx={{
            position: 'absolute',
            top: 8,
            left: 8,
            display: 'flex',
            flexDirection: 'column',
            gap: 1,
          }}
        >
          {product.featured && (
            <Chip
              label="Featured"
              size="small"
              color="primary"
              sx={{ fontSize: '0.7rem' }}
            />
          )}
          {product.on_sale && discountPercentage > 0 && (
            <Chip
              label={`-${discountPercentage}%`}
              size="small"
              color="secondary"
              sx={{ fontSize: '0.7rem' }}
            />
          )}
        </Box>

        {/* Action Buttons */}
        {showActions && (
          <Box
            sx={{
              position: 'absolute',
              top: 8,
              right: 8,
              display: 'flex',
              flexDirection: 'column',
              gap: 1,
            }}
          >
            <Tooltip title="Quick View">
              <IconButton
                size="small"
                sx={{
                  backgroundColor: 'rgba(255,255,255,0.9)',
                  '&:hover': {
                    backgroundColor: 'white',
                  },
                }}
                onClick={handleViewProduct}
              >
                <Visibility fontSize="small" />
              </IconButton>
            </Tooltip>
            
            {onToggleFavorite && (
              <Tooltip title={isFavorite ? 'Remove from favorites' : 'Add to favorites'}>
                <IconButton
                  size="small"
                  sx={{
                    backgroundColor: 'rgba(255,255,255,0.9)',
                    '&:hover': {
                      backgroundColor: 'white',
                    },
                  }}
                  onClick={handleToggleFavorite}
                >
                  {isFavorite ? (
                    <Favorite fontSize="small" color="error" />
                  ) : (
                    <FavoriteBorder fontSize="small" />
                  )}
                </IconButton>
              </Tooltip>
            )}
          </Box>
        )}

        {/* Out of Stock Overlay */}
        {isOutOfStock && (
          <Box
            sx={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              backgroundColor: 'rgba(0,0,0,0.5)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Chip
              label="Out of Stock"
              color="error"
              sx={{ fontWeight: 'bold' }}
            />
          </Box>
        )}
      </Box>

      {/* Product Content */}
      <CardContent sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Product Name */}
        <Typography
          variant="h6"
          component="h3"
          gutterBottom
          sx={{
            fontWeight: 500,
            lineHeight: 1.2,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            display: '-webkit-box',
            WebkitLineClamp: 2,
            WebkitBoxOrient: 'vertical',
            minHeight: '2.4em',
          }}
        >
          {product.name}
        </Typography>

        {/* Rating */}
        {product.average_rating && (
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
            <Rating
              value={product.average_rating}
              precision={0.5}
              size="small"
              readOnly
            />
            <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
              ({product.review_count || 0})
            </Typography>
          </Box>
        )}

        {/* Price */}
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <Typography
            variant="h6"
            component="span"
            color="primary"
            sx={{ fontWeight: 'bold' }}
          >
            ${displayPrice.toFixed(2)}
          </Typography>
          {originalPrice && (
            <Typography
              variant="body2"
              component="span"
              color="text.secondary"
              sx={{ textDecoration: 'line-through', ml: 1 }}
            >
              ${originalPrice.toFixed(2)}
            </Typography>
          )}
        </Box>

        {/* Stock Status */}
        {!isOutOfStock && product.stock_quantity !== undefined && (
          <Typography
            variant="body2"
            color={product.stock_quantity <= 5 ? 'warning.main' : 'success.main'}
            sx={{ mb: 2 }}
          >
            {product.stock_quantity <= 5
              ? `Only ${product.stock_quantity} left`
              : 'In Stock'}
          </Typography>
        )}

        {/* Add to Cart Button */}
        {showActions && (
          <Button
            variant="contained"
            fullWidth
            startIcon={<ShoppingCart />}
            onClick={handleAddToCart}
            disabled={isOutOfStock}
            sx={{
              mt: 'auto',
              textTransform: 'none',
              fontWeight: 'bold',
            }}
          >
            {isInCartItem ? `In Cart (${cartQuantity})` : 'Add to Cart'}
          </Button>
        )}
      </CardContent>
    </Card>
  );
};

export default ProductCard;



