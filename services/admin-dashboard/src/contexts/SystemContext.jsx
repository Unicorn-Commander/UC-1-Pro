import React, { createContext, useContext, useState, useEffect } from 'react';

const SystemContext = createContext();

export function useSystem() {
  const context = useContext(SystemContext);
  if (!context) {
    throw new Error('useSystem must be used within a SystemProvider');
  }
  return context;
}

export function SystemProvider({ children }) {
  const [systemStatus, setSystemStatus] = useState(null);
  const [services, setServices] = useState([]);
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [wsConnected, setWsConnected] = useState(false);

  // Fetch initial data
  useEffect(() => {
    fetchSystemStatus();
    fetchServices();
    fetchModels();
  }, []);

  // Setup WebSocket connection
  useEffect(() => {
    let ws;
    let reconnectInterval;

    const connect = () => {
      ws = new WebSocket(`ws://${window.location.host}/ws`);

      ws.onopen = () => {
        console.log('WebSocket connected');
        setWsConnected(true);
      };

      ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        handleWebSocketMessage(data);
      };

      ws.onclose = () => {
        console.log('WebSocket disconnected');
        setWsConnected(false);
        // Reconnect after 5 seconds
        reconnectInterval = setTimeout(connect, 5000);
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
      };
    };

    connect();

    return () => {
      if (ws) ws.close();
      if (reconnectInterval) clearTimeout(reconnectInterval);
    };
  }, []);

  const handleWebSocketMessage = (data) => {
    switch (data.type) {
      case 'system_update':
        setSystemStatus(data.data);
        break;
      case 'service_update':
        setServices(prev => 
          prev.map(s => s.name === data.data.name ? { ...s, ...data.data } : s)
        );
        break;
      case 'model_update':
        setModels(prev => 
          prev.map(m => m.id === data.data.id ? { ...m, ...data.data } : m)
        );
        break;
      default:
        console.log('Unknown WebSocket message type:', data.type);
    }
  };

  const fetchSystemStatus = async () => {
    try {
      const response = await fetch('/api/v1/system/status');
      if (!response.ok) throw new Error('Failed to fetch system status');
      const data = await response.json();
      setSystemStatus(data);
    } catch (err) {
      setError(err.message);
    }
  };

  const fetchServices = async () => {
    try {
      const response = await fetch('/api/v1/services');
      if (!response.ok) throw new Error('Failed to fetch services');
      const data = await response.json();
      setServices(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const fetchModels = async () => {
    try {
      const response = await fetch('/api/v1/models');
      if (!response.ok) throw new Error('Failed to fetch models');
      const data = await response.json();
      setModels(data);
    } catch (err) {
      setError(err.message);
    }
  };

  const controlService = async (serviceName, action) => {
    try {
      const response = await fetch(`/api/v1/services/${serviceName}/${action}`, {
        method: 'POST',
      });
      if (!response.ok) throw new Error(`Failed to ${action} service`);
      const data = await response.json();
      // Update will come through WebSocket
      return data;
    } catch (err) {
      setError(err.message);
      throw err;
    }
  };

  const value = {
    systemStatus,
    services,
    models,
    loading,
    error,
    wsConnected,
    controlService,
    refreshSystem: fetchSystemStatus,
    refreshServices: fetchServices,
    refreshModels: fetchModels,
  };

  return (
    <SystemContext.Provider value={value}>
      {children}
    </SystemContext.Provider>
  );
}