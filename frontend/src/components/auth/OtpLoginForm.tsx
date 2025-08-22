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
  Grid,
} from '@mui/material';
import { useUser } from '../../contexts/UserContext';

interface OtpLoginFormProps {
  onSuccess?: () => void;
  onSwitchToEmailLogin?: () => void;
}

const OtpLoginForm: React.FC<OtpLoginFormProps> = ({ onSuccess, onSwitchToEmailLogin }) => {
  const { sendOtp, loginWithOtp, state } = useUser();
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [errors, setErrors] = useState<{ phone?: string; otp?: string }>({});

  const validatePhone = (phone: string): boolean => {
    const phoneRegex = /^[6-9]\d{9}$/;
    if (!phone) {
      setErrors(prev => ({ ...prev, phone: 'Phone number is required' }));
      return false;
    }
    if (!phoneRegex.test(phone)) {
      setErrors(prev => ({ ...prev, phone: 'Please enter a valid 10-digit phone number' }));
      return false;
    }
    setErrors(prev => ({ ...prev, phone: undefined }));
    return true;
  };

  const validateOtp = (otp: string): boolean => {
    if (!otp) {
      setErrors(prev => ({ ...prev, otp: 'OTP is required' }));
      return false;
    }
    if (otp.length !== 6) {
      setErrors(prev => ({ ...prev, otp: 'OTP must be 6 digits' }));
      return false;
    }
    setErrors(prev => ({ ...prev, otp: undefined }));
    return true;
  };

  const handleSendOtp = async () => {
    if (!validatePhone(phone)) {
      return;
    }

    try {
      await sendOtp(phone);
      setOtpSent(true);
    } catch (error) {
      console.error('Failed to send OTP:', error);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    
    if (!validatePhone(phone) || !validateOtp(otp)) {
      return;
    }

    try {
      await loginWithOtp(phone, otp);
      onSuccess?.();
    } catch (error) {
      console.error('OTP login failed:', error);
    }
  };

  const handlePhoneChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    setPhone(value);
    if (errors.phone) {
      validatePhone(value);
    }
  };

  const handleOtpChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    setOtp(value);
    if (errors.otp) {
      validateOtp(value);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box sx={{ marginTop: 4, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Paper elevation={2} sx={{ padding: 3, width: '100%', maxWidth: 400 }}>
          <Typography variant="h5" align="center" gutterBottom>
            Login with OTP
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
              label="Phone Number"
              name="phone"
              autoComplete="tel"
              value={phone}
              onChange={handlePhoneChange}
              error={!!errors.phone}
              helperText={errors.phone || "Enter 10-digit mobile number"}
              disabled={state.isLoading || otpSent}
              placeholder="9876543210"
            />

            {!otpSent ? (
              <Button
                type="button"
                fullWidth
                variant="contained"
                sx={{ mt: 3, mb: 2 }}
                onClick={handleSendOtp}
                disabled={state.isLoading || !phone}
              >
                {state.isLoading ? <CircularProgress size={20} /> : 'Send OTP'}
              </Button>
            ) : (
              <>
                <TextField
                  margin="normal"
                  required
                  fullWidth
                  label="OTP"
                  name="otp"
                  autoComplete="one-time-code"
                  value={otp}
                  onChange={handleOtpChange}
                  error={!!errors.otp}
                  helperText={errors.otp || "Enter 6-digit OTP sent to your phone"}
                  disabled={state.isLoading}
                  placeholder="123456"
                  inputProps={{ maxLength: 6 }}
                />

                <Button
                  type="submit"
                  fullWidth
                  variant="contained"
                  sx={{ mt: 3, mb: 2 }}
                  disabled={state.isLoading || !otp}
                >
                  {state.isLoading ? <CircularProgress size={20} /> : 'Login with OTP'}
                </Button>

                <Button
                  type="button"
                  fullWidth
                  variant="outlined"
                  sx={{ mb: 2 }}
                  onClick={() => {
                    setOtpSent(false);
                    setOtp('');
                    setErrors({});
                  }}
                  disabled={state.isLoading}
                >
                  Send New OTP
                </Button>
              </>
            )}

            <Box sx={{ textAlign: 'center', mt: 2 }}>
              <Link
                component="button"
                variant="body2"
                onClick={onSwitchToEmailLogin}
                sx={{ cursor: 'pointer' }}
              >
                Login with Email & Password
              </Link>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default OtpLoginForm;



