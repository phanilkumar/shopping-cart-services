import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { toast } from 'react-hot-toast';

export interface CartItem {
  id: string;
  product_id: string;
  name: string;
  price: number;
  sale_price?: number;
  image_url?: string;
  quantity: number;
  sku: string;
  available_quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
  itemCount: number;
  isLoading: boolean;
}

export interface CartContextType {
  items: CartItem[];
  total: number;
  itemCount: number;
  cartItemsCount: number; // Added this property
  isLoading: boolean;
  addItem: (item: CartItem) => void;
  updateQuantity: (id: string, quantity: number) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
  setCart: (items: CartItem[]) => void;
  isInCart: (productId: string) => boolean;
  getItemQuantity: (productId: string) => number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: CartItem }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'CLEAR_CART' }
  | { type: 'SET_CART'; payload: CartItem[] }
  | { type: 'SET_LOADING'; payload: boolean };

const initialState: CartState = {
  items: [],
  total: 0,
  itemCount: 0,
  isLoading: false,
};

const cartReducer = (state: CartState, action: CartAction): CartState => {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingItem = state.items.find(item => item.id === action.payload.id);
      
      if (existingItem) {
        const newQuantity = existingItem.quantity + action.payload.quantity;
        if (newQuantity > existingItem.available_quantity) {
          toast.error(`Only ${existingItem.available_quantity} items available`);
          return state;
        }
        
        const updatedItems = state.items.map(item =>
          item.id === action.payload.id
            ? { ...item, quantity: newQuantity }
            : item
        );
        
        const newTotal = updatedItems.reduce((sum, item) => {
          const price = item.sale_price || item.price;
          return sum + (price * item.quantity);
        }, 0);
        
        const newItemCount = updatedItems.reduce((sum, item) => sum + item.quantity, 0);
        
        return {
          ...state,
          items: updatedItems,
          total: newTotal,
          itemCount: newItemCount,
        };
      } else {
        const newItems = [...state.items, action.payload];
        const newTotal = newItems.reduce((sum, item) => {
          const price = item.sale_price || item.price;
          return sum + (price * item.quantity);
        }, 0);
        
        const newItemCount = newItems.reduce((sum, item) => sum + item.quantity, 0);
        
        return {
          ...state,
          items: newItems,
          total: newTotal,
          itemCount: newItemCount,
        };
      }
    }
    
    case 'UPDATE_QUANTITY': {
      const updatedItems = state.items.map(item =>
        item.id === action.payload.id
          ? { ...item, quantity: action.payload.quantity }
          : item
      );
      
      const newTotal = updatedItems.reduce((sum, item) => {
        const price = item.sale_price || item.price;
        return sum + (price * item.quantity);
      }, 0);
      
      const newItemCount = updatedItems.reduce((sum, item) => sum + item.quantity, 0);
      
      return {
        ...state,
        items: updatedItems,
        total: newTotal,
        itemCount: newItemCount,
      };
    }
    
    case 'REMOVE_ITEM': {
      const updatedItems = state.items.filter(item => item.id !== action.payload);
      const newTotal = updatedItems.reduce((sum, item) => {
        const price = item.sale_price || item.price;
        return sum + (price * item.quantity);
      }, 0);
      
      const newItemCount = updatedItems.reduce((sum, item) => sum + item.quantity, 0);
      
      return {
        ...state,
        items: updatedItems,
        total: newTotal,
        itemCount: newItemCount,
      };
    }
    
    case 'CLEAR_CART':
      return {
        ...state,
        items: [],
        total: 0,
        itemCount: 0,
      };
    
    case 'SET_CART': {
      const newTotal = action.payload.reduce((sum, item) => {
        const price = item.sale_price || item.price;
        return sum + (price * item.quantity);
      }, 0);
      
      const newItemCount = action.payload.reduce((sum, item) => sum + item.quantity, 0);
      
      return {
        ...state,
        items: action.payload,
        total: newTotal,
        itemCount: newItemCount,
      };
    }
    
    case 'SET_LOADING':
      return {
        ...state,
        isLoading: action.payload,
      };
    
    default:
      return state;
  }
};

const CartContext = createContext<CartContextType | undefined>(undefined);

export const useCart = () => {
  const context = useContext(CartContext);
  if (context === undefined) {
    throw new Error('useCart must be used within a CartProvider');
  }
  return context;
};

interface CartProviderProps {
  children: ReactNode;
}

export const CartProvider: React.FC<CartProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(cartReducer, initialState);

  // Load cart from localStorage on mount
  useEffect(() => {
    const savedCart = localStorage.getItem('cart');
    if (savedCart) {
      try {
        const cartItems = JSON.parse(savedCart);
        dispatch({ type: 'SET_CART', payload: cartItems });
      } catch (error) {
        console.error('Failed to load cart from localStorage:', error);
      }
    }
  }, []);

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(state.items));
  }, [state.items]);

  const addItem = (item: CartItem) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
    toast.success(`${item.name} added to cart`);
  };

  const updateQuantity = (id: string, quantity: number) => {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { id, quantity } });
  };

  const removeItem = (id: string) => {
    const item = state.items.find(item => item.id === id);
    dispatch({ type: 'REMOVE_ITEM', payload: id });
    if (item) {
      toast.success(`${item.name} removed from cart`);
    }
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
    toast.success('Cart cleared');
  };

  const setCart = (items: CartItem[]) => {
    dispatch({ type: 'SET_CART', payload: items });
  };

  const isInCart = (productId: string) => {
    return state.items.some(item => item.product_id === productId);
  };

  const getItemQuantity = (productId: string) => {
    const item = state.items.find(item => item.product_id === productId);
    return item ? item.quantity : 0;
  };

  const value: CartContextType = {
    items: state.items,
    total: state.total,
    itemCount: state.itemCount,
    cartItemsCount: state.itemCount, // Added this property
    isLoading: state.isLoading,
    addItem,
    updateQuantity,
    removeItem,
    clearCart,
    setCart,
    isInCart,
    getItemQuantity,
  };

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

