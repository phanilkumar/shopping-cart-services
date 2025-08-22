import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Typography,
  Paper,
  Alert,
  CircularProgress,
  Link,
  Container,
} from '@mui/material';
import { useUser } from '../../contexts/UserContext';
import { CreateUserData } from '../../services/api/userAPI';
import CongratulationsPopup from './CongratulationsPopup';

interface RegisterFormProps {
  onSuccess?: () => void;
  onSwitchToLogin?: () => void;
}

const RegisterForm: React.FC<RegisterFormProps> = ({ onSuccess, onSwitchToLogin }) => {
  const { register, state } = useUser();
  const [formData, setFormData] = useState<CreateUserData>({
    email: '',
    password: '',
    password_confirmation: '',
    first_name: '',
    last_name: '',
    phone: '',
  });
  const [errors, setErrors] = useState<Partial<CreateUserData>>({});
  const [showCongratulations, setShowCongratulations] = useState(false);
  const [registeredEmail, setRegisteredEmail] = useState('');

  const handleInputChange = (field: keyof CreateUserData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value,
    }));
    
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: undefined,
      }));
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Partial<CreateUserData> = {};

    if (!formData.first_name) {
      newErrors.first_name = 'First name is required';
    }

    if (!formData.last_name) {
      newErrors.last_name = 'Last name is required';
    }

    if (!formData.email) {
      newErrors.email = 'Email is required';
    }

    if (!formData.phone) {
      newErrors.phone = 'Phone number is required';
    } else if (!/^[6-9]\d{9}$/.test(formData.phone)) {
      newErrors.phone = 'Please enter a valid 10-digit mobile number';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    }

    if (!formData.password_confirmation) {
      newErrors.password_confirmation = 'Please confirm your password';
    } else if (formData.password !== formData.password_confirmation) {
      newErrors.password_confirmation = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      await register(formData);
      // Show congratulations popup
      setRegisteredEmail(formData.email);
      setShowCongratulations(true);
      
      // Clear the form
      setFormData({
        email: '',
        password: '',
        password_confirmation: '',
        first_name: '',
        last_name: '',
        phone: '',
      });
      setErrors({});
    } catch (error) {
      console.error('Registration failed:', error);
    }
  };

  const handleCloseCongratulations = () => {
    setShowCongratulations(false);
  };

  const handleLoginFromCongratulations = () => {
    setShowCongratulations(false);
    onSwitchToLogin?.();
  };

  return (
    <Container maxWidth="sm">
      <Box sx={{ marginTop: 4, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Paper elevation={2} sx={{ padding: 3, width: '100%', maxWidth: 400 }}>
          <Typography variant="h5" align="center" gutterBottom>
            Create Account
          </Typography>

          {state.error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {state.error}
            </Alert>
          )}

          {state.success && (
            <Alert severity="success" sx={{ mb: 2 }}>
              {state.success}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit}>
            <TextField
              margin="normal"
              required
              fullWidth
              label="First Name"
              name="first_name"
              value={formData.first_name}
              onChange={handleInputChange('first_name')}
              error={!!errors.first_name}
              helperText={errors.first_name}
              disabled={state.isLoading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              label="Last Name"
              name="last_name"
              value={formData.last_name}
              onChange={handleInputChange('last_name')}
              error={!!errors.last_name}
              helperText={errors.last_name}
              disabled={state.isLoading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              label="Email"
              name="email"
              type="email"
              value={formData.email}
              onChange={handleInputChange('email')}
              error={!!errors.email}
              helperText={errors.email}
              disabled={state.isLoading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              label="Mobile Number"
              name="phone"
              placeholder="9876543210"
              value={formData.phone}
              onChange={handleInputChange('phone')}
              error={!!errors.phone}
              helperText={errors.phone || "Enter 10-digit mobile number"}
              disabled={state.isLoading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              label="Password"
              type="password"
              name="password"
              value={formData.password}
              onChange={handleInputChange('password')}
              error={!!errors.password}
              helperText={errors.password}
              disabled={state.isLoading}
            />

            <TextField
              margin="normal"
              required
              fullWidth
              label="Confirm Password"
              type="password"
              name="password_confirmation"
              value={formData.password_confirmation}
              onChange={handleInputChange('password_confirmation')}
              error={!!errors.password_confirmation}
              helperText={errors.password_confirmation}
              disabled={state.isLoading}
            />

            <Button
              type="submit"
              fullWidth
              variant="contained"
              sx={{ mt: 3, mb: 2 }}
              disabled={state.isLoading}
            >
              {state.isLoading ? <CircularProgress size={20} /> : 'Create Account'}
            </Button>

            <Box sx={{ textAlign: 'center' }}>
              <Link
                component="button"
                variant="body2"
                onClick={onSwitchToLogin}
                sx={{ cursor: 'pointer' }}
              >
                Already have account? Login
              </Link>
            </Box>
          </Box>
        </Paper>
      </Box>
      
      {/* Congratulations Popup */}
      <CongratulationsPopup
        open={showCongratulations}
        onClose={handleCloseCongratulations}
        onLogin={handleLoginFromCongratulations}
        userEmail={registeredEmail}
      />
    </Container>
  );
};

export default RegisterForm;
