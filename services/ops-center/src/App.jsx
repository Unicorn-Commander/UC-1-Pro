import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation, Navigate } from 'react-router-dom';
import PublicLanding from './pages/PublicLanding';
import Dashboard from './pages/Dashboard';
import AIModelManagement from './pages/AIModelManagement';
import Services from './pages/Services';
import System from './pages/System';
import Network from './pages/Network';
import Settings from './pages/Settings';
import StorageBackup from './pages/StorageBackup';
import Extensions from './pages/Extensions';
import Logs from './pages/Logs';
import Security from './pages/Security';
import Login from './pages/Login';
import Layout from './components/Layout';
import ErrorBoundary from './components/ErrorBoundary';
import LoadingScreen from './components/LoadingScreen';
import OnboardingTour from './components/OnboardingTour';
import HelpPanel from './components/HelpPanel';
import { SystemProvider, useSystem } from './contexts/SystemContext';
import { ThemeProvider } from './contexts/ThemeContext';

// Protected Route wrapper for admin pages
function ProtectedRoute({ children }) {
  const token = localStorage.getItem('authToken');
  
  if (!token) {
    return <Navigate to="/admin/login" replace />;
  }
  
  return children;
}

// Admin content wrapper with SystemProvider
function AdminContent({ children }) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    // Simple check if backend is available
    fetch('/api/v1/system/status')
      .then(res => {
        if (!res.ok) throw new Error('Backend not available');
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);
  
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
    <SystemProvider>
      {children}
    </SystemProvider>
  );
}

function AppRoutes() {
  const location = useLocation();
  const [showHelp, setShowHelp] = useState(false);
  
  // Keyboard shortcut for help (only on admin pages)
  useEffect(() => {
    const handleKeyPress = (e) => {
      if (e.key === '?' && !e.target.matches('input, textarea, select') && location.pathname.startsWith('/admin')) {
        setShowHelp(!showHelp);
      }
    };
    
    window.addEventListener('keydown', handleKeyPress);
    return () => window.removeEventListener('keydown', handleKeyPress);
  }, [showHelp, location.pathname]);
  
  const getCurrentPage = () => {
    const path = location.pathname.slice(1);
    return path || 'dashboard';
  };
  
  return (
    <>
      <Routes>
        {/* Public Landing Page - NO SystemProvider */}
        <Route path="/" element={<PublicLanding />} />
        
        {/* Admin Login - NO SystemProvider */}
        <Route path="/admin/login" element={<Login />} />
        
        {/* Admin Dashboard - Protected Routes WITH SystemProvider */}
        <Route path="/admin/*" element={
          <ProtectedRoute>
            <AdminContent>
              <Layout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/models" element={<AIModelManagement />} />
                  <Route path="/services" element={<Services />} />
                  <Route path="/system" element={<System />} />
                  <Route path="/network" element={<Network />} />
                  <Route path="/storage" element={<StorageBackup />} />
                  <Route path="/extensions" element={<Extensions />} />
                  <Route path="/logs" element={<Logs />} />
                  <Route path="/security" element={<Security />} />
                  <Route path="/settings" element={<Settings />} />
                </Routes>
              </Layout>
            </AdminContent>
          </ProtectedRoute>
        } />
      </Routes>
      
      {/* Help Panel - only show on admin pages */}
      {location.pathname.startsWith('/admin') && (
        <HelpPanel 
          isOpen={showHelp} 
          onClose={() => setShowHelp(false)}
          currentPage={getCurrentPage()}
        />
      )}
    </>
  );
}

function App() {
  const [showOnboarding, setShowOnboarding] = useState(false);
  
  useEffect(() => {
    // Check if user needs onboarding (only on admin pages)
    const hasCompletedTour = localStorage.getItem('uc1-tour-completed');
    if (!hasCompletedTour && window.location.pathname.startsWith('/admin')) {
      setTimeout(() => setShowOnboarding(true), 1000);
    }
  }, []);
  
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <Router>
          <AppRoutes />
          {showOnboarding && (
            <OnboardingTour onComplete={() => setShowOnboarding(false)} />
          )}
        </Router>
      </ThemeProvider>
    </ErrorBoundary>
  );
}

export default App;
