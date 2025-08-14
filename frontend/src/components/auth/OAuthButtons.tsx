import React from 'react';
import { Box, Button, Typography, Divider } from '@mui/material';
import { Google, Facebook, GitHub, Twitter, LinkedIn } from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';

const OAuthButtons: React.FC = () => {
  const { oauthLogin, isLoading } = useAuth();

  const handleOAuthLogin = async (provider: string) => {
    try {
      await oauthLogin(provider);
    } catch (error) {
      console.error(`${provider} login failed:`, error);
    }
  };

  const oauthProviders = [
    { name: 'Google', icon: <Google />, color: '#DB4437', provider: 'google' },
    { name: 'Facebook', icon: <Facebook />, color: '#4267B2', provider: 'facebook' },
    { name: 'GitHub', icon: <GitHub />, color: '#333', provider: 'github' },
    { name: 'Twitter', icon: <Twitter />, color: '#1DA1F2', provider: 'twitter' },
    { name: 'LinkedIn', icon: <LinkedIn />, color: '#0077B5', provider: 'linkedin' },
  ];

  return (
    <Box sx={{ mt: 2 }}>
      <Divider sx={{ my: 2 }}>
        <Typography variant="body2" color="text.secondary">
          Or continue with
        </Typography>
      </Divider>
      
      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
        {oauthProviders.map((provider) => (
          <Button
            key={provider.provider}
            variant="outlined"
            startIcon={provider.icon}
            onClick={() => handleOAuthLogin(provider.provider)}
            disabled={isLoading}
            sx={{
              borderColor: provider.color,
              color: provider.color,
              '&:hover': {
                borderColor: provider.color,
                backgroundColor: `${provider.color}10`,
              },
            }}
          >
            Continue with {provider.name}
          </Button>
        ))}
      </Box>
      
      <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
        Note: OAuth providers are currently using mock data for demonstration
      </Typography>
    </Box>
  );
};

export default OAuthButtons;
