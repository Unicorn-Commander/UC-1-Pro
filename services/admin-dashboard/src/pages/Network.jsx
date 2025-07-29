import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  WifiIcon, 
  GlobeAltIcon,
  SignalIcon,
  LockClosedIcon,
  CheckCircleIcon,
  XCircleIcon,
  ArrowPathIcon,
  CogIcon,
  PencilIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';

export default function Network() {
  const [networkStatus, setNetworkStatus] = useState(null);
  const [wifiNetworks, setWifiNetworks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedNetwork, setSelectedNetwork] = useState(null);
  const [wifiPassword, setWifiPassword] = useState('');
  const [connecting, setConnecting] = useState(false);
  const [scanning, setScanning] = useState(false);
  const [showNetworkConfig, setShowNetworkConfig] = useState(false);
  const [networkConfig, setNetworkConfig] = useState({
    method: 'dhcp',
    address: '',
    netmask: '255.255.255.0',
    gateway: '',
    dns1: '',
    dns2: ''
  });

  useEffect(() => {
    fetchNetworkStatus();
    scanWifiNetworks();
  }, []);

  const fetchNetworkStatus = async () => {
    try {
      const response = await fetch('/api/v1/network/status');
      if (!response.ok) throw new Error('Failed to fetch network status');
      const data = await response.json();
      setNetworkStatus(data);
    } catch (error) {
      console.error('Network status error:', error);
    } finally {
      setLoading(false);
    }
  };

  const scanWifiNetworks = async () => {
    setScanning(true);
    try {
      const response = await fetch('/api/v1/network/wifi/scan');
      if (!response.ok) throw new Error('Failed to scan WiFi networks');
      const data = await response.json();
      setWifiNetworks(data);
    } catch (error) {
      console.error('WiFi scan error:', error);
      // Show user-friendly error
      alert('Failed to scan WiFi networks. Make sure WiFi is enabled.');
    } finally {
      setScanning(false);
    }
  };

  const connectToWifi = async () => {
    if (!selectedNetwork) return;
    
    // Check if password is required
    if (selectedNetwork.security !== 'Open' && !wifiPassword) {
      alert('Please enter the WiFi password');
      return;
    }
    
    setConnecting(true);
    try {
      const response = await fetch('/api/v1/network/wifi/connect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ssid: selectedNetwork.ssid,
          password: wifiPassword,
        }),
      });
      
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.detail || 'Failed to connect to WiFi');
      }
      
      await fetchNetworkStatus();
      setSelectedNetwork(null);
      setWifiPassword('');
      alert('Successfully connected to WiFi!');
    } catch (error) {
      console.error('WiFi connection error:', error);
      alert(error.message || 'Failed to connect to WiFi. Please check your password.');
    } finally {
      setConnecting(false);
    }
  };

  const getSignalStrength = (strength) => {
    // WiFi signal strength is typically 0-100 in nmcli
    if (strength > 75) return 'Excellent';
    if (strength > 50) return 'Good';
    if (strength > 25) return 'Fair';
    return 'Poor';
  };

  const getSignalIcon = (strength) => {
    const quality = getSignalStrength(strength);
    const color = quality === 'Excellent' ? 'text-green-600' : 
                  quality === 'Good' ? 'text-yellow-600' : 
                  quality === 'Fair' ? 'text-orange-600' : 'text-red-600';
    
    return <SignalIcon className={`h-5 w-5 ${color}`} />;
  };

  const disconnectWifi = async () => {
    try {
      const response = await fetch('/api/v1/network/wifi/disconnect', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const data = await response.json();
      
      if (response.ok) {
        alert('WiFi disconnected');
        await fetchNetworkStatus();
        await scanWifiNetworks();
      } else {
        alert(data.detail || 'Failed to disconnect WiFi');
      }
    } catch (error) {
      console.error('WiFi disconnect error:', error);
      alert('Failed to disconnect WiFi');
    }
  };

  if (loading) {
    return <div>Loading network information...</div>;
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          Network Configuration
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Manage network connections and settings
        </p>
      </div>


      {/* Current Network Status */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Current Connection
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Ethernet Status */}
          <div className="border dark:border-gray-700 rounded-lg p-4">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                <GlobeAltIcon className="h-5 w-5" />
                Ethernet
              </h3>
              {networkStatus?.ethernet?.connected ? (
                <CheckCircleIcon className="h-5 w-5 text-green-600" />
              ) : (
                <XCircleIcon className="h-5 w-5 text-gray-400" />
              )}
            </div>
            {networkStatus?.ethernet?.connected ? (
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">IP Address:</span>
                  <span className="text-gray-900 dark:text-white font-mono">
                    {networkStatus.ethernet.ip_address}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">Speed:</span>
                  <span className="text-gray-900 dark:text-white">
                    {networkStatus.ethernet.speed} Mbps
                  </span>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500">Not connected</p>
            )}
          </div>

          {/* WiFi Status */}
          <div className="border dark:border-gray-700 rounded-lg p-4">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                <WifiIcon className="h-5 w-5" />
                WiFi
              </h3>
              {networkStatus?.wifi?.connected ? (
                <CheckCircleIcon className="h-5 w-5 text-green-600" />
              ) : (
                <XCircleIcon className="h-5 w-5 text-gray-400" />
              )}
            </div>
            {networkStatus?.wifi?.connected ? (
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">Network:</span>
                  <span className="text-gray-900 dark:text-white">
                    {networkStatus.wifi.ssid}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">IP Address:</span>
                  <span className="text-gray-900 dark:text-white font-mono">
                    {networkStatus.wifi.ip_address}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600 dark:text-gray-400">Signal:</span>
                  <span className="text-gray-900 dark:text-white flex items-center gap-2">
                    {getSignalIcon(networkStatus.wifi.signal)}
                    {getSignalStrength(networkStatus.wifi.signal)}
                  </span>
                </div>
                {networkStatus.wifi.ip && (
                  <div className="flex justify-between">
                    <span className="text-gray-600 dark:text-gray-400">IP:</span>
                    <span className="text-gray-900 dark:text-white font-mono">
                      {networkStatus.wifi.ip}
                    </span>
                  </div>
                )}
                <div className="mt-3">
                  <button
                    onClick={disconnectWifi}
                    className="w-full px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 text-sm"
                  >
                    Disconnect
                  </button>
                </div>
              </div>
            ) : (
              <p className="text-sm text-gray-500">Not connected</p>
            )}
          </div>
        </div>
      </div>

      {/* WiFi Networks */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Available WiFi Networks
          </h2>
          <div className="flex gap-2">
            <button
              onClick={() => setShowNetworkConfig(true)}
              className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 flex items-center gap-2"
              title="Configure network settings"
            >
              <CogIcon className="h-5 w-5" />
              Configure
            </button>
            <button
              onClick={scanWifiNetworks}
              disabled={scanning}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
            >
              <ArrowPathIcon className={`h-5 w-5 ${scanning ? 'animate-spin' : ''}`} />
              {scanning ? 'Scanning...' : 'Scan Networks'}
            </button>
          </div>
        </div>

        <div className="space-y-3">
          {scanning && wifiNetworks.length === 0 && (
            <div className="text-center py-8 text-gray-500">
              <ArrowPathIcon className="h-8 w-8 animate-spin mx-auto mb-2" />
              Scanning for WiFi networks...
            </div>
          )}
          
          {!scanning && wifiNetworks.length === 0 && (
            <div className="text-center py-8 text-gray-500">
              No WiFi networks found. Click "Scan Networks" to search.
            </div>
          )}
          
          {wifiNetworks.map((network, index) => (
            <motion.div
              key={network.ssid}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              className={`
                border dark:border-gray-700 rounded-lg p-4 cursor-pointer
                ${selectedNetwork?.ssid === network.ssid ? 'border-blue-500' : ''}
                hover:border-blue-400 transition-colors
              `}
              onClick={() => setSelectedNetwork(network)}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  {network.security && <LockClosedIcon className="h-4 w-4 text-gray-400" />}
                  <span className="font-medium text-gray-900 dark:text-white">
                    {network.ssid}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  {getSignalIcon(network.signal_strength)}
                  <span className="text-sm text-gray-500">
                    {network.signal_strength} dBm
                  </span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* WiFi Connection Form */}
        {selectedNetwork && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            className="mt-6 border-t dark:border-gray-700 pt-6"
          >
            <h3 className="font-medium text-gray-900 dark:text-white mb-4">
              Connect to {selectedNetwork.ssid}
            </h3>
            <div className="flex gap-4">
              <input
                type="password"
                value={wifiPassword}
                onChange={(e) => setWifiPassword(e.target.value)}
                placeholder="Enter WiFi password"
                className="flex-1 px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
              <button
                onClick={connectToWifi}
                disabled={!wifiPassword || connecting}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              >
                {connecting ? 'Connecting...' : 'Connect'}
              </button>
              <button
                onClick={() => {
                  setSelectedNetwork(null);
                  setWifiPassword('');
                }}
                className="px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
              >
                Cancel
              </button>
            </div>
          </motion.div>
        )}
      </div>

      {/* Bluetooth Status */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Bluetooth
        </h2>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-gray-600 dark:text-gray-400">
              Status: {networkStatus?.bluetooth?.enabled ? 'Enabled' : 'Disabled'}
            </p>
            {networkStatus?.bluetooth?.enabled && (
              <p className="text-sm text-gray-500 mt-1">
                {networkStatus.bluetooth.devices.length} connected devices
              </p>
            )}
          </div>
          <button
            className={`px-4 py-2 rounded-lg ${
              networkStatus?.bluetooth?.enabled
                ? 'bg-red-600 hover:bg-red-700'
                : 'bg-green-600 hover:bg-green-700'
            } text-white`}
          >
            {networkStatus?.bluetooth?.enabled ? 'Disable' : 'Enable'}
          </button>
        </div>
      </div>

      {/* Network Configuration Modal */}
      {showNetworkConfig && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-semibold mb-4">Network Configuration</h3>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium mb-2">Configuration Method</label>
                <select
                  value={networkConfig.method}
                  onChange={(e) => setNetworkConfig({...networkConfig, method: e.target.value})}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="dhcp">DHCP (Automatic)</option>
                  <option value="static">Static IP</option>
                </select>
              </div>
              
              {networkConfig.method === 'static' && (
                <>
                  <div>
                    <label className="block text-sm font-medium mb-2">IP Address</label>
                    <input
                      type="text"
                      value={networkConfig.address}
                      onChange={(e) => setNetworkConfig({...networkConfig, address: e.target.value})}
                      placeholder="192.168.1.100"
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Subnet Mask</label>
                    <input
                      type="text"
                      value={networkConfig.netmask}
                      onChange={(e) => setNetworkConfig({...networkConfig, netmask: e.target.value})}
                      placeholder="255.255.255.0"
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Gateway</label>
                    <input
                      type="text"
                      value={networkConfig.gateway}
                      onChange={(e) => setNetworkConfig({...networkConfig, gateway: e.target.value})}
                      placeholder="192.168.1.1"
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Primary DNS</label>
                    <input
                      type="text"
                      value={networkConfig.dns1}
                      onChange={(e) => setNetworkConfig({...networkConfig, dns1: e.target.value})}
                      placeholder="8.8.8.8"
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-2">Secondary DNS</label>
                    <input
                      type="text"
                      value={networkConfig.dns2}
                      onChange={(e) => setNetworkConfig({...networkConfig, dns2: e.target.value})}
                      placeholder="8.8.4.4"
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                </>
              )}
            </div>
            
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowNetworkConfig(false)}
                className="px-4 py-2 text-gray-600 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200"
              >
                Cancel
              </button>
              <button
                onClick={async () => {
                  // Apply network configuration
                  try {
                    // Get the interface name based on what's being configured
                    const interfaceName = networkStatus?.ethernet?.interface || 'eth0';
                    const configData = {
                      interface: interfaceName,
                      method: networkConfig.method,
                      address: networkConfig.address,
                      netmask: networkConfig.netmask,
                      gateway: networkConfig.gateway,
                      dns: [networkConfig.dns1, networkConfig.dns2].filter(Boolean)
                    };
                    
                    const response = await fetch('/api/v1/network/configure', {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify(configData)
                    });
                    
                    const data = await response.json();
                    
                    if (response.ok) {
                      alert('Network configuration applied successfully!');
                      setShowNetworkConfig(false);
                      fetchNetworkStatus();
                    } else {
                      throw new Error(data.detail || 'Failed to apply configuration');
                    }
                  } catch (error) {
                    alert(error.message || 'Failed to apply network configuration');
                  }
                }}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Apply
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}