import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { apiService, User, OAuthUser, LoginCredentials, RegisterData } from '../../services/api';

// Combined user type for both Auth and OAuth services
export type CombinedUser = User | OAuthUser;

export interface AuthState {
  user: CombinedUser | null;
  authToken: string | null;
  authRefreshToken: string | null;
  oauthToken: string | null;
  oauthRefreshToken: string | null;
  authMethod: 'auth' | 'oauth' | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

const initialState: AuthState = {
  user: null,
  authToken: localStorage.getItem('authToken'),
  authRefreshToken: localStorage.getItem('authRefreshToken'),
  oauthToken: localStorage.getItem('oauthToken'),
  oauthRefreshToken: localStorage.getItem('oauthRefreshToken'),
  authMethod: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
};

// Initialize auth method on app start
const initializeAuthMethod = () => {
  const authToken = localStorage.getItem('authToken');
  const oauthToken = localStorage.getItem('oauthToken');
  
  if (authToken) return 'auth';
  if (oauthToken) return 'oauth';
  return null;
};

initialState.authMethod = initializeAuthMethod();
initialState.isAuthenticated = !!(initialState.authToken || initialState.oauthToken);

// Async thunks
export const login = createAsyncThunk(
  'auth/login',
  async (credentials: LoginCredentials, { rejectWithValue }) => {
    try {
      const response = await apiService.auth.login(credentials);
      return {
        ...response,
        authMethod: 'auth' as const,
      };
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Login failed');
    }
  }
);

export const register = createAsyncThunk(
  'auth/register',
  async (userData: RegisterData, { rejectWithValue }) => {
    try {
      const response = await apiService.auth.register(userData);
      return {
        ...response,
        authMethod: 'auth' as const,
      };
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Registration failed');
    }
  }
);

export const oauthLogin = createAsyncThunk(
  'auth/oauthLogin',
  async (provider: string, { rejectWithValue }) => {
    try {
      const response = await apiService.oauth.handleCallback(provider);
      return {
        ...response,
        authMethod: 'oauth' as const,
      };
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'OAuth login failed');
    }
  }
);

export const refreshToken = createAsyncThunk(
  'auth/refreshToken',
  async (_, { getState, rejectWithValue }) => {
    try {
      const state = getState() as { auth: AuthState };
      const { authMethod, authRefreshToken, oauthRefreshToken } = state.auth;
      
      if (authMethod === 'auth' && authRefreshToken) {
        const response = await apiService.auth.refreshToken(authRefreshToken);
        return {
          ...response,
          authMethod: 'auth' as const,
        };
      } else if (authMethod === 'oauth' && oauthRefreshToken) {
        const response = await apiService.oauth.handleCallback('google'); // Default provider
        return {
          ...response,
          authMethod: 'oauth' as const,
        };
      }
      
      throw new Error('No refresh token available');
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Token refresh failed');
    }
  }
);

export const logout = createAsyncThunk(
  'auth/logout',
  async (_, { rejectWithValue }) => {
    try {
      await apiService.user.logout();
      return null;
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Logout failed');
    }
  }
);

export const getCurrentUser = createAsyncThunk(
  'auth/getCurrentUser',
  async (_, { getState, rejectWithValue }) => {
    try {
      const user = await apiService.user.getCurrentUser();
      if (!user) {
        throw new Error('No user found');
      }
      
      const authMethod = apiService.user.getAuthMethod();
      return { user, authMethod };
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Failed to get user');
    }
  }
);

export const updateProfile = createAsyncThunk(
  'auth/updateProfile',
  async (userData: Partial<RegisterData>, { getState, rejectWithValue }) => {
    try {
      const state = getState() as { auth: AuthState };
      const { authMethod } = state.auth;
      
      if (authMethod === 'auth') {
        const response = await apiService.auth.updateProfile(userData);
        return response.data.user;
      } else if (authMethod === 'oauth') {
        const response = await apiService.oauth.updateProfile(userData);
        return response.data.user;
      }
      
      throw new Error('No authentication method found');
    } catch (error: any) {
      return rejectWithValue(error.response?.data?.message || 'Profile update failed');
    }
  }
);

const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    setAuthToken: (state, action: PayloadAction<string>) => {
      state.authToken = action.payload;
      state.authMethod = 'auth';
      state.isAuthenticated = true;
      localStorage.setItem('authToken', action.payload);
    },
    setOAuthToken: (state, action: PayloadAction<string>) => {
      state.oauthToken = action.payload;
      state.authMethod = 'oauth';
      state.isAuthenticated = true;
      localStorage.setItem('oauthToken', action.payload);
    },
    updateUser: (state, action: PayloadAction<Partial<CombinedUser>>) => {
      if (state.user) {
        state.user = { ...state.user, ...action.payload };
      }
    },
  },
  extraReducers: (builder) => {
    // Login
    builder
      .addCase(login.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(login.fulfilled, (state, action) => {
        state.isLoading = false;
        state.isAuthenticated = true;
        state.user = action.payload.data.user;
        state.authToken = action.payload.data.token;
        state.authRefreshToken = action.payload.data.refresh_token;
        state.authMethod = action.payload.authMethod;
        localStorage.setItem('authToken', action.payload.data.token);
        localStorage.setItem('authRefreshToken', action.payload.data.refresh_token);
        localStorage.setItem('user', JSON.stringify(action.payload.data.user));
      })
      .addCase(login.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });

    // Register
    builder
      .addCase(register.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(register.fulfilled, (state, action) => {
        state.isLoading = false;
        state.isAuthenticated = true;
        state.user = action.payload.data.user;
        state.authToken = action.payload.data.token;
        state.authRefreshToken = action.payload.data.refresh_token;
        state.authMethod = action.payload.authMethod;
        localStorage.setItem('authToken', action.payload.data.token);
        localStorage.setItem('authRefreshToken', action.payload.data.refresh_token);
        localStorage.setItem('user', JSON.stringify(action.payload.data.user));
      })
      .addCase(register.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });

    // OAuth Login
    builder
      .addCase(oauthLogin.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(oauthLogin.fulfilled, (state, action) => {
        state.isLoading = false;
        state.isAuthenticated = true;
        state.user = action.payload.data.user;
        state.oauthToken = action.payload.data.token;
        state.oauthRefreshToken = action.payload.data.refresh_token;
        state.authMethod = action.payload.authMethod;
        localStorage.setItem('oauthToken', action.payload.data.token);
        localStorage.setItem('oauthRefreshToken', action.payload.data.refresh_token);
        localStorage.setItem('oauthUser', JSON.stringify(action.payload.data.user));
      })
      .addCase(oauthLogin.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });

    // Refresh Token
    builder
      .addCase(refreshToken.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(refreshToken.fulfilled, (state, action) => {
        state.isLoading = false;
        if (action.payload.authMethod === 'auth') {
          state.authToken = action.payload.data.token;
          state.authRefreshToken = action.payload.data.refresh_token;
          localStorage.setItem('authToken', action.payload.data.token);
          localStorage.setItem('authRefreshToken', action.payload.data.refresh_token);
        } else if (action.payload.authMethod === 'oauth') {
          state.oauthToken = action.payload.data.token;
          state.oauthRefreshToken = action.payload.data.refresh_token;
          localStorage.setItem('oauthToken', action.payload.data.token);
          localStorage.setItem('oauthRefreshToken', action.payload.data.refresh_token);
        }
      })
      .addCase(refreshToken.rejected, (state) => {
        state.isLoading = false;
        state.isAuthenticated = false;
        state.user = null;
        state.authToken = null;
        state.authRefreshToken = null;
        state.oauthToken = null;
        state.oauthRefreshToken = null;
        state.authMethod = null;
        localStorage.removeItem('authToken');
        localStorage.removeItem('authRefreshToken');
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('user');
        localStorage.removeItem('oauthUser');
      });

    // Logout
    builder
      .addCase(logout.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(logout.fulfilled, (state) => {
        state.isLoading = false;
        state.isAuthenticated = false;
        state.user = null;
        state.authToken = null;
        state.authRefreshToken = null;
        state.oauthToken = null;
        state.oauthRefreshToken = null;
        state.authMethod = null;
        localStorage.removeItem('authToken');
        localStorage.removeItem('authRefreshToken');
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('user');
        localStorage.removeItem('oauthUser');
      })
      .addCase(logout.rejected, (state) => {
        state.isLoading = false;
        state.isAuthenticated = false;
        state.user = null;
        state.authToken = null;
        state.authRefreshToken = null;
        state.oauthToken = null;
        state.oauthRefreshToken = null;
        state.authMethod = null;
        localStorage.removeItem('authToken');
        localStorage.removeItem('authRefreshToken');
        localStorage.removeItem('oauthToken');
        localStorage.removeItem('oauthRefreshToken');
        localStorage.removeItem('user');
        localStorage.removeItem('oauthUser');
      });

    // Get Current User
    builder
      .addCase(getCurrentUser.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(getCurrentUser.fulfilled, (state, action) => {
        state.isLoading = false;
        state.isAuthenticated = true;
        state.user = action.payload.user;
        state.authMethod = action.payload.authMethod;
      })
      .addCase(getCurrentUser.rejected, (state) => {
        state.isLoading = false;
        state.isAuthenticated = false;
        state.user = null;
        state.authMethod = null;
      });

    // Update Profile
    builder
      .addCase(updateProfile.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(updateProfile.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload;
        localStorage.setItem('user', JSON.stringify(action.payload));
      })
      .addCase(updateProfile.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as string;
      });
  },
});

export const { clearError, setAuthToken, setOAuthToken, updateUser } = authSlice.actions;
export default authSlice.reducer;

