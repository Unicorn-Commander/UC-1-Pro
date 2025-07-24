import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Models from './pages/Models';
import Services from './pages/Services';
import System from './pages/System';
import Network from './pages/Network';
import Settings from './pages/Settings';
import Layout from './components/Layout';
import { SystemProvider } from './contexts/SystemContext';

function App() {
  return (
    <SystemProvider>
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
    </SystemProvider>
  );
}

export default App;