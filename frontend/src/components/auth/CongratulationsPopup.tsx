import React from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  CheckCircleOutline,
} from '@mui/material';

interface CongratulationsPopupProps {
  open: boolean;
  onClose: () => void;
  onLogin: () => void;
  userEmail: string;
}

const CongratulationsPopup: React.FC<CongratulationsPopupProps> = ({
  open,
  onClose,
  onLogin,
  userEmail,
}) => {
  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 2,
          p: 1,
        },
      }}
    >
      <DialogTitle sx={{ textAlign: 'center', pb: 1 }}>
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <CheckCircleOutline
            sx={{
              fontSize: 64,
              color: 'success.main',
              mb: 2,
            }}
          />
          <Typography variant="h5" component="h2" gutterBottom>
            🎉 Congratulations!
          </Typography>
        </Box>
      </DialogTitle>
      
      <DialogContent sx={{ textAlign: 'center', pb: 2 }}>
        <Typography variant="body1" sx={{ mb: 2 }}>
          Your account has been successfully created!
        </Typography>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
          Account registered with: <strong>{userEmail}</strong>
        </Typography>
        <Typography variant="body1" sx={{ mb: 2 }}>
          You can now login with your email and password to access your account.
        </Typography>
      </DialogContent>
      
      <DialogActions sx={{ justifyContent: 'center', pb: 3, px: 3 }}>
        <Button
          variant="outlined"
          onClick={onClose}
          sx={{ mr: 2 }}
        >
          Close
        </Button>
        <Button
          variant="contained"
          onClick={onLogin}
          sx={{ minWidth: 120 }}
        >
          Login Now
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default CongratulationsPopup;
