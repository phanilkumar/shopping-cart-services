import React, { useState } from 'react';
import { Box, Container, Paper, Tabs, Tab } from '@mui/material';
import LoginForm from '../components/auth/LoginForm';
import RegisterForm from '../components/auth/RegisterForm';
import OtpLoginForm from '../components/auth/OtpLoginForm';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`auth-tabpanel-${index}`}
      aria-labelledby={`auth-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 2 }}>{children}</Box>}
    </div>
  );
}

const AuthPage: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleSwitchToRegister = () => {
    setTabValue(1);
  };

  const handleSwitchToLogin = () => {
    setTabValue(0);
  };

  const handleSwitchToOtpLogin = () => {
    setTabValue(1);
  };

  const handleSwitchToEmailLogin = () => {
    setTabValue(0);
  };

  const handleAuthSuccess = () => {
    // For login success, redirect to dashboard
    // For registration, the congratulations popup will handle the flow
    console.log('Auth success - App.tsx will handle redirect');
  };

  const handleRegistrationSuccess = () => {
    // Registration success is handled by the congratulations popup
    // No automatic redirect needed
    console.log('Registration success - showing congratulations popup');
  };

  return (
    <Container maxWidth="sm">
      <Box sx={{ marginTop: 2, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <Paper elevation={2} sx={{ width: '100%' }}>
          <Tabs
            value={tabValue}
            onChange={handleTabChange}
            variant="fullWidth"
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="Email Login" />
            <Tab label="OTP Login" />
            <Tab label="Register" />
          </Tabs>

          <TabPanel value={tabValue} index={0}>
            <LoginForm
              onSuccess={handleAuthSuccess}
              onSwitchToRegister={handleSwitchToRegister}
            />
          </TabPanel>

          <TabPanel value={tabValue} index={1}>
            <OtpLoginForm
              onSuccess={handleAuthSuccess}
              onSwitchToEmailLogin={handleSwitchToEmailLogin}
            />
          </TabPanel>

          <TabPanel value={tabValue} index={2}>
            <RegisterForm
              onSuccess={handleRegistrationSuccess}
              onSwitchToLogin={handleSwitchToLogin}
            />
          </TabPanel>
        </Paper>
      </Box>
    </Container>
  );
};

export default AuthPage;
