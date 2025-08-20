import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Tabs,
  Tab,
  Alert,
  CircularProgress,
  InputAdornment,
  IconButton
} from '@mui/material';
import {
  Phone as PhoneIcon,
  Email as EmailIcon,
  Visibility,
  VisibilityOff,
  Send as SendIcon
} from '@mui/icons-material';
import { useFormik } from 'formik';
import * as Yup from 'yup';

interface LoginFormProps {
  onEmailLogin: (values: EmailLoginValues) => void;
  onPhoneLogin: (values: PhoneLoginValues) => void;
  onOtpVerification: (values: OtpVerificationValues) => void;
  loading?: boolean;
  error?: string;
  success?: string;
}

interface EmailLoginValues {
  email: string;
  password: string;
}

interface PhoneLoginValues {
  phone: string;
}

interface OtpVerificationValues {
  phone: string;
  otp: string;
}

const LoginForm: React.FC<LoginFormProps> = ({
  onEmailLogin,
  onPhoneLogin,
  onOtpVerification,
  loading = false,
  error,
  success
}) => {
  const [activeTab, setActiveTab] = useState(0);
  const [showPassword, setShowPassword] = useState(false);
  const [otpSent, setOtpSent] = useState(false);
  const [phoneNumber, setPhoneNumber] = useState('');

  // Email login form
  const emailForm = useFormik<EmailLoginValues>({
    initialValues: {
      email: '',
      password: ''
    },
    validationSchema: Yup.object({
      email: Yup.string()
        .email('Invalid email address')
        .required('Email is required'),
      password: Yup.string()
        .min(6, 'Password must be at least 6 characters')
        .required('Password is required')
    }),
    onSubmit: (values) => {
      onEmailLogin(values);
    }
  });

  // Phone login form
  const phoneForm = useFormik<PhoneLoginValues>({
    initialValues: {
      phone: ''
    },
    validationSchema: Yup.object({
      phone: Yup.string()
        .matches(/^[6-9]\d{9}$/, 'Invalid Indian phone number')
        .required('Phone number is required')
    }),
    onSubmit: (values) => {
      setPhoneNumber(values.phone);
      onPhoneLogin(values);
      setOtpSent(true);
    }
  });

  // OTP verification form
  const otpForm = useFormik<OtpVerificationValues>({
    initialValues: {
      phone: phoneNumber,
      otp: ''
    },
    validationSchema: Yup.object({
      otp: Yup.string()
        .matches(/^\d{6}$/, 'OTP must be 6 digits')
        .required('OTP is required')
    }),
    onSubmit: (values) => {
      onOtpVerification({ ...values, phone: phoneNumber });
    }
  });

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
    setOtpSent(false);
    setPhoneNumber('');
  };

  const handleResendOtp = () => {
    onPhoneLogin({ phone: phoneNumber });
  };

  const formatPhoneNumber = (value: string) => {
    // Remove all non-digits
    const phoneNumber = value.replace(/\D/g, '');
    
    // Format as Indian phone number
    if (phoneNumber.length <= 10) {
      return phoneNumber;
    }
    return phoneNumber.slice(0, 10);
  };

  return (
    <Box
      sx={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
        padding: 2
      }}
    >
      <Card sx={{ maxWidth: 400, width: '100%', boxShadow: 3 }}>
        <CardContent sx={{ p: 4 }}>
          <Typography variant="h4" component="h1" gutterBottom align="center" color="primary">
            🇮🇳 Welcome Back
          </Typography>
          
          <Typography variant="body2" color="text.secondary" align="center" sx={{ mb: 3 }}>
            Login with your email or Indian phone number
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mb: 2 }}>
              {success}
            </Alert>
          )}

          <Tabs
            value={activeTab}
            onChange={handleTabChange}
            variant="fullWidth"
            sx={{ mb: 3 }}
          >
            <Tab 
              icon={<EmailIcon />} 
              label="Email" 
              iconPosition="start"
            />
            <Tab 
              icon={<PhoneIcon />} 
              label="Phone" 
              iconPosition="start"
            />
          </Tabs>

          {/* Email Login Tab */}
          {activeTab === 0 && (
            <form onSubmit={emailForm.handleSubmit}>
              <TextField
                fullWidth
                id="email"
                name="email"
                label="Email Address"
                type="email"
                value={emailForm.values.email}
                onChange={emailForm.handleChange}
                onBlur={emailForm.handleBlur}
                error={emailForm.touched.email && Boolean(emailForm.errors.email)}
                helperText={emailForm.touched.email && emailForm.errors.email}
                sx={{ mb: 2 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon color="action" />
                    </InputAdornment>
                  )
                }}
              />

              <TextField
                fullWidth
                id="password"
                name="password"
                label="Password"
                type={showPassword ? 'text' : 'password'}
                value={emailForm.values.password}
                onChange={emailForm.handleChange}
                onBlur={emailForm.handleBlur}
                error={emailForm.touched.password && Boolean(emailForm.errors.password)}
                helperText={emailForm.touched.password && emailForm.errors.password}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon color="action" />
                    </InputAdornment>
                  ),
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        onClick={() => setShowPassword(!showPassword)}
                        edge="end"
                      >
                        {showPassword ? <VisibilityOff /> : <Visibility />}
                      </IconButton>
                    </InputAdornment>
                  )
                }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading || !emailForm.isValid}
                sx={{ mb: 2 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Login with Email'}
              </Button>
            </form>
          )}

          {/* Phone Login Tab */}
          {activeTab === 1 && !otpSent && (
            <form onSubmit={phoneForm.handleSubmit}>
              <TextField
                fullWidth
                id="phone"
                name="phone"
                label="Indian Phone Number"
                type="tel"
                value={phoneForm.values.phone}
                onChange={(e) => {
                  const formatted = formatPhoneNumber(e.target.value);
                  phoneForm.setFieldValue('phone', formatted);
                }}
                onBlur={phoneForm.handleBlur}
                error={phoneForm.touched.phone && Boolean(phoneForm.errors.phone)}
                helperText={phoneForm.touched.phone && phoneForm.errors.phone || "Enter 10-digit mobile number"}
                sx={{ mb: 3 }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PhoneIcon color="action" />
                    </InputAdornment>
                  ),
                  placeholder: "9876543210"
                }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading || !phoneForm.isValid}
                sx={{ mb: 2 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Send OTP'}
              </Button>
            </form>
          )}

          {/* OTP Verification */}
          {activeTab === 1 && otpSent && (
            <form onSubmit={otpForm.handleSubmit}>
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                OTP sent to +91 {phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, '***$2$3')}
              </Typography>

              <TextField
                fullWidth
                id="otp"
                name="otp"
                label="Enter 6-digit OTP"
                type="text"
                value={otpForm.values.otp}
                onChange={otpForm.handleChange}
                onBlur={otpForm.handleBlur}
                error={otpForm.touched.otp && Boolean(otpForm.errors.otp)}
                helperText={otpForm.touched.otp && otpForm.errors.otp}
                sx={{ mb: 2 }}
                inputProps={{
                  maxLength: 6,
                  pattern: '[0-9]*'
                }}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PhoneIcon color="action" />
                    </InputAdornment>
                  )
                }}
              />

              <Button
                type="submit"
                fullWidth
                variant="contained"
                size="large"
                disabled={loading || !otpForm.isValid}
                sx={{ mb: 2 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Verify OTP'}
              </Button>

              <Button
                fullWidth
                variant="outlined"
                size="small"
                onClick={handleResendOtp}
                disabled={loading}
                startIcon={<SendIcon />}
              >
                Resend OTP
              </Button>
            </form>
          )}

          <Box sx={{ mt: 3, textAlign: 'center' }}>
            <Typography variant="body2" color="text.secondary">
              Don't have an account?{' '}
              <Button color="primary" variant="text" size="small">
                Sign up
              </Button>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoginForm;

