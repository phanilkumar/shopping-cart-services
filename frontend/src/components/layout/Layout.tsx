import React, { ReactNode } from 'react';
import { Box, Container } from '@mui/material';

interface LayoutProps {
  children: ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <Box sx={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Container maxWidth="lg" sx={{ flex: 1, py: 2 }}>
        {children}
      </Container>
    </Box>
  );
};

export default Layout;
