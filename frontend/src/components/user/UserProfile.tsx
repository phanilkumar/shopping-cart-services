import React, { useState } from 'react';
import {
  Box,
  TextField,
  Button,
  Typography,
  Paper,
  Alert,
  CircularProgress,
  Container,
  Grid,
  Avatar,
  Divider,
  Chip,
} from '@mui/material';
import {
  Person as PersonIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  CalendarToday as CalendarIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { useUser } from '../../contexts/UserContext';
import { UpdateUserData } from '../../services/api/userAPI';

const UserProfile: React.FC = () => {
  const { state, updateProfile, logout } = useUser();
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState<UpdateUserData>({
    first_name: state.user?.first_name || '',
    last_name: state.user?.last_name || '',
    email: state.user?.email || '',
    phone: state.user?.phone || '',
  });
  const [errors, setErrors] = useState<Partial<UpdateUserData>>({});

  const handleInputChange = (field: keyof UpdateUserData) => (
    event: React.ChangeEvent<HTMLInputElement>
  ) => {
    setFormData(prev => ({
      ...prev,
      [field]: event.target.value,
    }));
    
    // Clear field error when user starts typing
    if (errors[field]) {
      setErrors(prev => ({
        ...prev,
        [field]: undefined,
      }));
    }
  };

  const validateForm = (): boolean => {
    const newErrors: Partial<UpdateUserData> = {};

    if (!formData.first_name) {
      newErrors.first_name = 'First name is required';
    }

    if (!formData.last_name) {
      newErrors.last_name = 'Last name is required';
    }

    if (!formData.email) {
      newErrors.email = 'Email is required';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email is invalid';
    }

    if (!formData.phone) {
      newErrors.phone = 'Phone number is required';
    } else if (!/^\+91[6-9]\d{9}$/.test(formData.phone)) {
      newErrors.phone = 'Please enter a valid Indian phone number with +91 prefix (e.g., +919876543210)';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSave = async () => {
    if (!validateForm()) {
      return;
    }

    try {
      await updateProfile(formData);
      setIsEditing(false);
    } catch (error) {
      console.error('Profile update failed:', error);
    }
  };

  const handleCancel = () => {
    setFormData({
      first_name: state.user?.first_name || '',
      last_name: state.user?.last_name || '',
      email: state.user?.email || '',
      phone: state.user?.phone || '',
    });
    setErrors({});
    setIsEditing(false);
  };

  const handleLogout = async () => {
    await logout();
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const getStatusColor = (status: number) => {
    switch (status) {
      case 1: // active
        return 'success';
      case 0: // inactive
        return 'error';
      case 2: // pending
        return 'warning';
      case 3: // suspended
        return 'error';
      default:
        return 'default';
    }
  };

  const getRoleColor = (role: number) => {
    switch (role) {
      case 1: // admin
        return 'error';
      case 2: // moderator
        return 'warning';
      case 0: // user
        return 'primary';
      default:
        return 'default';
    }
  };

  const getStatusLabel = (status: number) => {
    switch (status) {
      case 1: return 'active';
      case 0: return 'inactive';
      case 2: return 'pending';
      case 3: return 'suspended';
      default: return 'unknown';
    }
  };

  const getRoleLabel = (role: number) => {
    switch (role) {
      case 1: return 'admin';
      case 2: return 'moderator';
      case 0: return 'user';
      default: return 'unknown';
    }
  };

  if (!state.user) {
    return (
      <Container maxWidth="md">
        <Box sx={{ mt: 4, textAlign: 'center' }}>
          <CircularProgress />
          <Typography variant="h6" sx={{ mt: 2 }}>
            Loading profile...
          </Typography>
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="md">
      <Box sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          User Profile
        </Typography>

        {state.error && (
          <Alert severity="error" sx={{ mb: 3 }}>
            {state.error}
          </Alert>
        )}

        <Paper elevation={3} sx={{ p: 4 }}>
          {/* Profile Header */}
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 4 }}>
            <Avatar
              sx={{
                width: 80,
                height: 80,
                bgcolor: 'primary.main',
                fontSize: '2rem',
              }}
            >
              {state.user.first_name.charAt(0).toUpperCase()}
            </Avatar>
            <Box sx={{ ml: 3 }}>
              <Typography variant="h5" component="h2">
                {state.user.full_name}
              </Typography>
              <Box sx={{ mt: 1 }}>
                <Chip
                  label={getStatusLabel(state.user.status)}
                  color={getStatusColor(state.user.status) as any}
                  size="small"
                  sx={{ mr: 1 }}
                />
                <Chip
                  label={getRoleLabel(state.user.role)}
                  color={getRoleColor(state.user.role) as any}
                  size="small"
                />
              </Box>
            </Box>
          </Box>

          <Divider sx={{ mb: 4 }} />

          {/* Profile Form */}
          <Box component="form">
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="First Name"
                  value={formData.first_name}
                  onChange={handleInputChange('first_name')}
                  error={!!errors.first_name}
                  helperText={errors.first_name}
                  disabled={!isEditing || state.isLoading}
                  InputProps={{
                    startAdornment: <PersonIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Last Name"
                  value={formData.last_name}
                  onChange={handleInputChange('last_name')}
                  error={!!errors.last_name}
                  helperText={errors.last_name}
                  disabled={!isEditing || state.isLoading}
                  InputProps={{
                    startAdornment: <PersonIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Email"
                  type="email"
                  value={formData.email}
                  onChange={handleInputChange('email')}
                  error={!!errors.email}
                  helperText={errors.email}
                  disabled={!isEditing || state.isLoading}
                  InputProps={{
                    startAdornment: <EmailIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Phone Number"
                  value={formData.phone}
                  onChange={handleInputChange('phone')}
                  error={!!errors.phone}
                  helperText={errors.phone}
                  disabled={!isEditing || state.isLoading}
                  InputProps={{
                    startAdornment: <PhoneIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
            </Grid>

            {/* Read-only Information */}
            <Grid container spacing={3} sx={{ mt: 1 }}>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Member Since"
                  value={formatDate(state.user.created_at)}
                  disabled
                  InputProps={{
                    startAdornment: <CalendarIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Last Login"
                  value={state.user.last_login_at ? formatDate(state.user.last_login_at) : 'Never'}
                  disabled
                  InputProps={{
                    startAdornment: <CalendarIcon color="action" sx={{ mr: 1 }} />,
                  }}
                />
              </Grid>
            </Grid>

            {/* Action Buttons */}
            <Box sx={{ mt: 4, display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
              {!isEditing ? (
                <Button
                  variant="contained"
                  startIcon={<EditIcon />}
                  onClick={() => setIsEditing(true)}
                >
                  Edit Profile
                </Button>
              ) : (
                <>
                  <Button
                    variant="outlined"
                    startIcon={<CancelIcon />}
                    onClick={handleCancel}
                    disabled={state.isLoading}
                  >
                    Cancel
                  </Button>
                  <Button
                    variant="contained"
                    startIcon={<SaveIcon />}
                    onClick={handleSave}
                    disabled={state.isLoading}
                  >
                    {state.isLoading ? <CircularProgress size={20} /> : 'Save Changes'}
                  </Button>
                </>
              )}
              <Button
                variant="outlined"
                color="error"
                onClick={handleLogout}
                disabled={state.isLoading}
              >
                Logout
              </Button>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default UserProfile;
