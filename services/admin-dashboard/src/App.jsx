import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Models from './pages/Models';
import Services from './pages/Services';
import Network from './pages/Network';
import Storage from './pages/Storage';
import Settings from './pages/Settings';
import Layout from './components/Layout';
import { ThemeProvider } from './contexts/ThemeContext';
import { SystemProvider } from './contexts/SystemContext';

function App() {
  return (
    <ThemeProvider>
      <SystemProvider>
        <Router>
          <Layout>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/models" element={<Models />} />
              <Route path="/services" element={<Services />} />
              <Route path="/network" element={<Network />} />
              <Route path="/storage" element={<Storage />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </Layout>
        </Router>
      </SystemProvider>
    </ThemeProvider>
  );
}

export default App;