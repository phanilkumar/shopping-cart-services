import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { ThemeProvider } from '@mui/material/styles';
import { BrowserRouter } from 'react-router-dom';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import ProductCard from '../ProductCard';
import { CartProvider } from '../../../contexts/CartContext';
import theme from '../../../theme';

// Mock the cart context
const mockAddItem = jest.fn();
const mockIsInCart = jest.fn();
const mockGetItemQuantity = jest.fn();

jest.mock('../../../contexts/CartContext', () => ({
  ...jest.requireActual('../../../contexts/CartContext'),
  useCart: () => ({
    addItem: mockAddItem,
    isInCart: mockIsInCart,
    getItemQuantity: mockGetItemQuantity,
  }),
}));

// Create a mock store
const createMockStore = () =>
  configureStore({
    reducer: {
      auth: (state = { isAuthenticated: false, user: null }) => state,
    },
  });

const renderWithProviders = (component: React.ReactElement) => {
  const store = createMockStore();
  
  return render(
    <Provider store={store}>
      <ThemeProvider theme={theme}>
        <BrowserRouter>
          <CartProvider>
            {component}
          </CartProvider>
        </BrowserRouter>
      </ThemeProvider>
    </Provider>
  );
};

const mockProduct = {
  id: '1',
  name: 'Test Product',
  price: 99.99,
  sale_price: undefined,
  sku: 'TEST-001',
  slug: 'test-product',
  primary_image: {
    image_url: 'https://example.com/image.jpg',
  },
  average_rating: 4.5,
  review_count: 10,
  stock_quantity: 50,
  featured: false,
  on_sale: false,
};

const mockProductOnSale = {
  ...mockProduct,
  sale_price: 79.99,
  on_sale: true,
};

const mockOutOfStockProduct = {
  ...mockProduct,
  stock_quantity: 0,
};

describe('ProductCard', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockIsInCart.mockReturnValue(false);
    mockGetItemQuantity.mockReturnValue(0);
  });

  describe('Rendering', () => {
    it('renders product information correctly', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('Test Product')).toBeInTheDocument();
      expect(screen.getByText('$99.99')).toBeInTheDocument();
      expect(screen.getByText('In Stock')).toBeInTheDocument();
      expect(screen.getByText('Add to Cart')).toBeInTheDocument();
    });

    it('renders product image with fallback', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      const image = screen.getByAltText('Test Product');
      expect(image).toBeInTheDocument();
      expect(image).toHaveAttribute('src', 'https://example.com/image.jpg');
    });

    it('renders product without image', () => {
      const productWithoutImage = { ...mockProduct, primary_image: undefined };
      
      renderWithProviders(
        <ProductCard
          product={productWithoutImage}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      const image = screen.getByAltText('Test Product');
      expect(image).toHaveAttribute('src', '/placeholder-product.jpg');
    });

    it('renders rating and review count', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('(10)')).toBeInTheDocument();
    });

    it('renders featured badge when product is featured', () => {
      const featuredProduct = { ...mockProduct, featured: true };
      
      renderWithProviders(
        <ProductCard
          product={featuredProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('Featured')).toBeInTheDocument();
    });

    it('renders sale badge and discounted price', () => {
      renderWithProviders(
        <ProductCard
          product={mockProductOnSale}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('-20%')).toBeInTheDocument();
      expect(screen.getByText('$79.99')).toBeInTheDocument();
      expect(screen.getByText('$99.99')).toHaveStyle('text-decoration: line-through');
    });

    it('renders out of stock overlay', () => {
      renderWithProviders(
        <ProductCard
          product={mockOutOfStockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('Out of Stock')).toBeInTheDocument();
    });

    it('renders low stock warning', () => {
      const lowStockProduct = { ...mockProduct, stock_quantity: 3 };
      
      renderWithProviders(
        <ProductCard
          product={lowStockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('Only 3 left')).toBeInTheDocument();
    });
  });

  describe('Cart Integration', () => {
    it('shows "In Cart" when product is in cart', () => {
      mockIsInCart.mockReturnValue(true);
      mockGetItemQuantity.mockReturnValue(2);

      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('In Cart (2)')).toBeInTheDocument();
    });

    it('calls onAddToCart when add to cart button is clicked', () => {
      const mockOnAddToCart = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={mockOnAddToCart}
          onViewProduct={jest.fn()}
        />
      );

      const addToCartButton = screen.getByText('Add to Cart');
      fireEvent.click(addToCartButton);

      expect(mockOnAddToCart).toHaveBeenCalledTimes(1);
    });

    it('disables add to cart button for out of stock products', () => {
      renderWithProviders(
        <ProductCard
          product={mockOutOfStockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      const addToCartButton = screen.getByText('Add to Cart');
      expect(addToCartButton).toBeDisabled();
    });
  });

  describe('User Interactions', () => {
    it('calls onViewProduct when card is clicked', () => {
      const mockOnViewProduct = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={mockOnViewProduct}
        />
      );

      const card = screen.getByText('Test Product').closest('.MuiCard-root');
      fireEvent.click(card!);

      expect(mockOnViewProduct).toHaveBeenCalledTimes(1);
    });

    it('calls onViewProduct when quick view button is clicked', () => {
      const mockOnViewProduct = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={mockOnViewProduct}
        />
      );

      const quickViewButton = screen.getByLabelText('Quick View');
      fireEvent.click(quickViewButton);

      expect(mockOnViewProduct).toHaveBeenCalledTimes(1);
    });

    it('calls onToggleFavorite when favorite button is clicked', () => {
      const mockOnToggleFavorite = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
          onToggleFavorite={mockOnToggleFavorite}
        />
      );

      const favoriteButton = screen.getByLabelText('Add to favorites');
      fireEvent.click(favoriteButton);

      expect(mockOnToggleFavorite).toHaveBeenCalledTimes(1);
    });

    it('shows filled heart when product is favorited', () => {
      const mockOnToggleFavorite = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
          onToggleFavorite={mockOnToggleFavorite}
          isFavorite={true}
        />
      );

      expect(screen.getByLabelText('Remove from favorites')).toBeInTheDocument();
    });
  });

  describe('Action Buttons', () => {
    it('hides action buttons when showActions is false', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
          showActions={false}
        />
      );

      expect(screen.queryByLabelText('Quick View')).not.toBeInTheDocument();
      expect(screen.queryByText('Add to Cart')).not.toBeInTheDocument();
    });

    it('prevents event propagation on button clicks', () => {
      const mockOnViewProduct = jest.fn();
      const mockOnAddToCart = jest.fn();
      
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={mockOnAddToCart}
          onViewProduct={mockOnViewProduct}
        />
      );

      const addToCartButton = screen.getByText('Add to Cart');
      const quickViewButton = screen.getByLabelText('Quick View');

      fireEvent.click(addToCartButton);
      fireEvent.click(quickViewButton);

      // Should only call the specific handlers, not trigger card click
      expect(mockOnAddToCart).toHaveBeenCalledTimes(1);
      expect(mockOnViewProduct).toHaveBeenCalledTimes(1);
    });
  });

  describe('Accessibility', () => {
    it('has proper ARIA labels', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByLabelText('Quick View')).toBeInTheDocument();
      expect(screen.getByAltText('Test Product')).toBeInTheDocument();
    });

    it('has proper button roles', () => {
      renderWithProviders(
        <ProductCard
          product={mockProduct}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      const addToCartButton = screen.getByRole('button', { name: /add to cart/i });
      expect(addToCartButton).toBeInTheDocument();
    });
  });

  describe('Edge Cases', () => {
    it('handles product with no rating', () => {
      const productWithoutRating = { ...mockProduct, average_rating: undefined };
      
      renderWithProviders(
        <ProductCard
          product={productWithoutRating}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.queryByText(/\(\d+\)/)).not.toBeInTheDocument();
    });

    it('handles product with undefined stock quantity', () => {
      const productWithoutStock = { ...mockProduct, stock_quantity: undefined };
      
      renderWithProviders(
        <ProductCard
          product={productWithoutStock}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.queryByText(/In Stock|Only \d+ left/)).not.toBeInTheDocument();
    });

    it('calculates discount percentage correctly', () => {
      const productWithDiscount = {
        ...mockProduct,
        price: 100,
        sale_price: 75,
        on_sale: true,
      };
      
      renderWithProviders(
        <ProductCard
          product={productWithDiscount}
          onAddToCart={jest.fn()}
          onViewProduct={jest.fn()}
        />
      );

      expect(screen.getByText('-25%')).toBeInTheDocument();
    });
  });
});



