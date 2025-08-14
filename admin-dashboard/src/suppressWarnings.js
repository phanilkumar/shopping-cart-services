// Suppress React Router future flag warnings
// These warnings are informational and don't affect functionality
// They will be resolved when upgrading to React Router v7

// Suppress console warnings for React Router future flags
const originalWarn = console.warn;
console.warn = (...args) => {
  const message = args[0];
  if (typeof message === 'string' && 
      (message.includes('React Router Future Flag Warning') || 
       message.includes('v7_startTransition') || 
       message.includes('v7_relativeSplatPath'))) {
    return; // Suppress these specific warnings
  }
  originalWarn.apply(console, args);
};

