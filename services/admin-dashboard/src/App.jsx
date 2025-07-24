import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Models from './pages/Models';
import Services from './pages/Services';
import System from './pages/System';
import Network from './pages/Network';
import Settings from './pages/Settings';
import Layout from './components/Layout';
import ErrorBoundary from './components/ErrorBoundary';
import LoadingScreen from './components/LoadingScreen';
import { SystemProvider, useSystem } from './contexts/SystemContext';
import { ThemeProvider } from './contexts/ThemeContext';

function AppContent() {
  const { loading, error } = useSystem();
  
  if (loading) {
    return <LoadingScreen />;
  }
  
  if (error) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="bg-red-900 text-white p-8 rounded-lg">
          <h1 className="text-xl font-bold mb-2">Connection Error</h1>
          <p>{error}</p>
          <p className="mt-4 text-sm">Please check that all services are running.</p>
        </div>
      </div>
    );
  }
  
  return (
    <Router>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/models" element={<Models />} />
          <Route path="/services" element={<Services />} />
          <Route path="/system" element={<System />} />
          <Route path="/network" element={<Network />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </Layout>
    </Router>
  );
}

function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <SystemProvider>
          <AppContent />
        </SystemProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;