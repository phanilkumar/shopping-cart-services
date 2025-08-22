import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import { userService, User, LoginCredentials, CreateUserData, UpdateUserData } from '../services/api/userAPI';

// User State Interface
interface UserState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  success: string | null;
}

// User Action Types
type UserAction =
  | { type: 'SET_LOADING'; payload: boolean }
  | { type: 'SET_USER'; payload: User | null }
  | { type: 'SET_ERROR'; payload: string | null }
  | { type: 'SET_SUCCESS'; payload: string | null }
  | { type: 'LOGOUT' }
  | { type: 'CLEAR_ERROR' }
  | { type: 'CLEAR_SUCCESS' };

// Initial State
const initialState: UserState = {
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,
  success: null,
};

// User Reducer
const userReducer = (state: UserState, action: UserAction): UserState => {
  switch (action.type) {
    case 'SET_LOADING':
      return { ...state, isLoading: action.payload };
    case 'SET_USER':
      return {
        ...state,
        user: action.payload,
        isAuthenticated: !!action.payload,
        isLoading: false,
        error: null,
        // Don't clear success message when setting user
      };
    case 'SET_ERROR':
      return { ...state, error: action.payload, isLoading: false };
    case 'SET_SUCCESS':
      return { ...state, success: action.payload, isLoading: false };
    case 'LOGOUT':
      return {
        ...state,
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
        success: null,
      };
    case 'CLEAR_ERROR':
      return { ...state, error: null };
    case 'CLEAR_SUCCESS':
      return { ...state, success: null };
    default:
      return state;
  }
};

// User Context Interface
interface UserContextType {
  state: UserState;
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (userData: CreateUserData) => Promise<void>;
  logout: () => Promise<void>;
  updateProfile: (userData: UpdateUserData) => Promise<void>;
  changePassword: (currentPassword: string, newPassword: string, confirmPassword: string) => Promise<void>;
  forgotPassword: (email: string) => Promise<void>;
  resetPassword: (token: string, password: string, passwordConfirmation: string) => Promise<void>;
  sendOtp: (phone: string) => Promise<void>;
  verifyOtp: (phone: string, otp: string) => Promise<void>;
  loginWithOtp: (phone: string, otp: string) => Promise<void>;
  clearError: () => void;
  clearSuccess: () => void;
  refreshUser: () => Promise<void>;
}

// Create Context
const UserContext = createContext<UserContextType | undefined>(undefined);

// User Provider Props
interface UserProviderProps {
  children: ReactNode;
}

// User Provider Component
export const UserProvider: React.FC<UserProviderProps> = ({ children }) => {
  const [state, dispatch] = useReducer(userReducer, initialState);

  // Check if user is already authenticated on mount
  useEffect(() => {
    const checkAuth = async () => {
      try {
        if (userService.isAuthenticated()) {
          const user = await userService.getCurrentUser();
          dispatch({ type: 'SET_USER', payload: user });
        } else {
          dispatch({ type: 'SET_LOADING', payload: false });
        }
      } catch (error) {
        console.error('Auth check failed:', error);
        dispatch({ type: 'SET_LOADING', payload: false });
      }
    };

    checkAuth();
  }, []);

  // Login function
  const login = async (credentials: LoginCredentials) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.login(credentials);
      
      // Store tokens
      localStorage.setItem('authToken', response.data.token);
      localStorage.setItem('authRefreshToken', response.data.refresh_token);
      
      // Store user data
      userService.setStoredUser(response.data.user);
      
      dispatch({ type: 'SET_USER', payload: response.data.user });
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Login failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    }
  };

  // Register function
  const register = async (userData: CreateUserData) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.register(userData);
      
      // Don't automatically authenticate after registration
      // Just store the success message and clear the form
      dispatch({ type: 'SET_SUCCESS', payload: 'Registration successful! Please login with your credentials.' });
      
      // Clear the form data by resetting to initial state
      return response;
    } catch (error: any) {
      let errorMessage = 'Registration failed';
      
      if (error.response?.data?.errors && Array.isArray(error.response.data.errors)) {
        // Handle array of error messages from backend
        errorMessage = error.response.data.errors.join(', ');
      } else if (error.response?.data?.message) {
        // Handle single error message
        errorMessage = error.response.data.message;
      }
      
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    }
  };

  // Logout function
  const logout = async () => {
    try {
      await userService.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      dispatch({ type: 'LOGOUT' });
    }
  };

  // Update profile function
  const updateProfile = async (userData: UpdateUserData) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.updateProfile(userData);
      
      // Update stored user data
      userService.setStoredUser(response.data.user);
      
      dispatch({ type: 'SET_USER', payload: response.data.user });
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Profile update failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    }
  };

  // Change password function
  const changePassword = async (currentPassword: string, newPassword: string, confirmPassword: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      await userService.changePassword(currentPassword, newPassword, confirmPassword);
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Password change failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Forgot password function
  const forgotPassword = async (email: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      await userService.forgotPassword(email);
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Password reset request failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Reset password function
  const resetPassword = async (token: string, password: string, passwordConfirmation: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      await userService.resetPassword(token, password, passwordConfirmation);
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Password reset failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Send OTP function
  const sendOtp = async (phone: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.sendOtp(phone);
      dispatch({ type: 'SET_SUCCESS', payload: response.message });
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to send OTP';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Verify OTP function
  const verifyOtp = async (phone: string, otp: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.verifyOtp(phone, otp);
      dispatch({ type: 'SET_SUCCESS', payload: response.message });
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'OTP verification failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Login with OTP function
  const loginWithOtp = async (phone: string, otp: string) => {
    try {
      dispatch({ type: 'SET_LOADING', payload: true });
      dispatch({ type: 'CLEAR_ERROR' });

      const response = await userService.loginWithOtp(phone, otp);
      
      // Store tokens
      localStorage.setItem('authToken', response.data.token);
      localStorage.setItem('authRefreshToken', response.data.refresh_token);
      
      // Store user data
      userService.setStoredUser(response.data.user);
      
      dispatch({ type: 'SET_USER', payload: response.data.user });
      dispatch({ type: 'SET_SUCCESS', payload: 'Login successful!' });
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'OTP login failed';
      dispatch({ type: 'SET_ERROR', payload: errorMessage });
      throw error;
    } finally {
      dispatch({ type: 'SET_LOADING', payload: false });
    }
  };

  // Clear error function
  const clearError = () => {
    dispatch({ type: 'CLEAR_ERROR' });
  };

  // Clear success function
  const clearSuccess = () => {
    dispatch({ type: 'CLEAR_SUCCESS' });
  };

  // Refresh user data function
  const refreshUser = async () => {
    try {
      if (userService.isAuthenticated()) {
        const user = await userService.getCurrentUser();
        userService.setStoredUser(user);
        dispatch({ type: 'SET_USER', payload: user });
      }
    } catch (error) {
      console.error('Failed to refresh user:', error);
      // If refresh fails, logout the user
      dispatch({ type: 'LOGOUT' });
    }
  };

  const value: UserContextType = {
    state,
    login,
    register,
    logout,
    updateProfile,
    changePassword,
    forgotPassword,
    resetPassword,
    sendOtp,
    verifyOtp,
    loginWithOtp,
    clearError,
    clearSuccess,
    refreshUser,
  };

  return <UserContext.Provider value={value}>{children}</UserContext.Provider>;
};

// Custom hook to use User Context
export const useUser = (): UserContextType => {
  const context = useContext(UserContext);
  if (context === undefined) {
    throw new Error('useUser must be used within a UserProvider');
  }
  return context;
};

// UserProvider is already exported above as a named export
