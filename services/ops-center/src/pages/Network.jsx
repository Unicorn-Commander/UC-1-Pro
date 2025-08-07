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
  const [savedNetworks, setSavedNetworks] = useState([]);
  const [networkDiagnostics, setNetworkDiagnostics] = useState(null);
  const [showDiagnostics, setShowDiagnostics] = useState(false);
  const [scanError, setScanError] = useState(null);
  const [connectionHistory, setConnectionHistory] = useState([]);
  const [showAdvanced, setShowAdvanced] = useState(false);

  useEffect(() => {
    fetchNetworkStatus();
    scanWifiNetworks();
    fetchSavedNetworks();
    fetchConnectionHistory();
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
    setScanError(null);
    try {
      const response = await fetch('/api/v1/network/wifi/scan');
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || 'Failed to scan WiFi networks');
      }
      const data = await response.json();
      setWifiNetworks(data);
      
      // Save scan timestamp
      const timestamp = new Date().toLocaleTimeString();
      setScanError(null);
    } catch (error) {
      console.error('WiFi scan error:', error);
      setScanError(error.message);
      
      // Provide helpful troubleshooting info
      if (error.message.includes('Permission denied')) {
        setScanError('Permission denied. WiFi scanning requires root privileges.');
      } else if (error.message.includes('No such device')) {
        setScanError('WiFi adapter not found. Check if WiFi hardware is available.');
      } else if (error.message.includes('Network is unreachable')) {
        setScanError('WiFi adapter is disabled. Enable WiFi to scan for networks.');
      } else {
        setScanError(`Scan failed: ${error.message}`);
      }
    } finally {
      setScanning(false);
    }
  };
  
  const fetchSavedNetworks = async () => {
    try {
      const response = await fetch('/api/v1/network/wifi/saved');
      if (response.ok) {
        const data = await response.json();
        setSavedNetworks(data);
      }
    } catch (error) {
      console.error('Failed to fetch saved networks:', error);
    }
  };
  
  const fetchConnectionHistory = async () => {
    try {
      const response = await fetch('/api/v1/network/history');
      if (response.ok) {
        const data = await response.json();
        setConnectionHistory(data);
      }
    } catch (error) {
      console.error('Failed to fetch connection history:', error);
    }
  };
  
  const runNetworkDiagnostics = async () => {
    setShowDiagnostics(true);
    try {
      const response = await fetch('/api/v1/network/diagnostics');
      if (response.ok) {
        const data = await response.json();
        setNetworkDiagnostics(data);
      }
    } catch (error) {
      console.error('Network diagnostics failed:', error);
      setNetworkDiagnostics({ error: 'Failed to run diagnostics' });
    }
  };
  
  const forgetNetwork = async (ssid) => {
    if (!confirm(`Are you sure you want to forget the network "${ssid}"?`)) return;
    
    try {
      const response = await fetch(`/api/v1/network/wifi/forget/${encodeURIComponent(ssid)}`, {
        method: 'DELETE'
      });
      
      if (response.ok) {
        alert(`Network "${ssid}" has been forgotten`);
        fetchSavedNetworks();
        fetchNetworkStatus();
      } else {
        const error = await response.json();
        alert(error.detail || 'Failed to forget network');
      }
    } catch (error) {
      console.error('Error forgetting network:', error);
      alert('Failed to forget network');
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
              <p>Scanning for WiFi networks...</p>
              <p className="text-sm mt-2">This may take a few moments</p>
            </div>
          )}
          
          {scanError && (
            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <ExclamationTriangleIcon className="h-5 w-5 text-red-500 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-medium text-red-800 dark:text-red-200">WiFi Scan Failed</h4>
                  <p className="text-sm text-red-700 dark:text-red-300 mt-1">{scanError}</p>
                  <div className="mt-3 space-y-1 text-xs text-red-600 dark:text-red-400">
                    <p><strong>Troubleshooting tips:</strong></p>
                    <ul className="list-disc list-inside space-y-1">
                      <li>Ensure WiFi adapter is enabled</li>
                      <li>Check if 'iw' and 'wireless-tools' are installed</li>
                      <li>Verify the admin service has network permissions</li>
                      <li>Try running: sudo iw dev [interface] scan</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          )}
          
          {!scanning && wifiNetworks.length === 0 && !scanError && (
            <div className="text-center py-8">
              <WifiIcon className="h-12 w-12 text-gray-400 mx-auto mb-3" />
              <p className="text-gray-500">No WiFi networks found</p>
              <p className="text-sm text-gray-400 mt-1">Click "Scan Networks" to search for available networks</p>
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
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-1">
                    {getSignalIcon(network.signal_strength)}
                    <span className="text-xs text-gray-500">
                      {getSignalStrength(network.signal_strength)}
                    </span>
                  </div>
                  <span className="text-xs text-gray-400">
                    {network.frequency ? `${(network.frequency / 1000).toFixed(1)}GHz` : ''}
                  </span>
                  <span className="text-xs text-gray-400">
                    {network.security}
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

      {/* Saved Networks & Advanced Features */}
      {(savedNetworks.length > 0 || showAdvanced) && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Saved Networks */}
          {savedNetworks.length > 0 && (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white flex items-center gap-2">
                <CogIcon className="h-5 w-5" />
                Saved Networks ({savedNetworks.length})
              </h2>
              <div className="space-y-3">
                {savedNetworks.map((network) => (
                  <div key={network.ssid} className="flex items-center justify-between p-3 border dark:border-gray-700 rounded-lg">
                    <div className="flex items-center gap-3">
                      <WifiIcon className="h-4 w-4 text-gray-500" />
                      <span className="font-medium text-gray-900 dark:text-white">{network.ssid}</span>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => connectToWifi(network)}
                        className="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                      >
                        Connect
                      </button>
                      <button
                        onClick={() => forgetNetwork(network.ssid)}
                        className="px-3 py-1 text-sm bg-red-600 text-white rounded hover:bg-red-700"
                      >
                        Forget
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
          
          {/* Network Diagnostics */}
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
              Network Diagnostics
            </h2>
            <div className="space-y-3">
              <button
                onClick={runNetworkDiagnostics}
                className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center justify-center gap-2"
              >
                <ExclamationTriangleIcon className="h-4 w-4" />
                Run Diagnostics
              </button>
              
              {networkDiagnostics && (
                <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <h4 className="font-medium mb-2">Diagnostic Results:</h4>
                  <div className="space-y-2 text-sm">
                    {networkDiagnostics.ping_gateway && (
                      <div className="flex justify-between">
                        <span>Gateway Ping:</span>
                        <span className={networkDiagnostics.ping_gateway.success ? 'text-green-600' : 'text-red-600'}>
                          {networkDiagnostics.ping_gateway.success ? '✓ Success' : '✗ Failed'}
                        </span>
                      </div>
                    )}
                    {networkDiagnostics.dns_lookup && (
                      <div className="flex justify-between">
                        <span>DNS Lookup:</span>
                        <span className={networkDiagnostics.dns_lookup.success ? 'text-green-600' : 'text-red-600'}>
                          {networkDiagnostics.dns_lookup.success ? '✓ Success' : '✗ Failed'}
                        </span>
                      </div>
                    )}
                    {networkDiagnostics.internet_access && (
                      <div className="flex justify-between">
                        <span>Internet Access:</span>
                        <span className={networkDiagnostics.internet_access.success ? 'text-green-600' : 'text-red-600'}>
                          {networkDiagnostics.internet_access.success ? '✓ Connected' : '✗ No Access'}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Advanced Network Information */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Advanced Network Information
          </h2>
          <button
            onClick={() => setShowAdvanced(!showAdvanced)}
            className="px-3 py-1 text-sm bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600"
          >
            {showAdvanced ? 'Hide' : 'Show'} Advanced
          </button>
        </div>
        
        {showAdvanced && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Interface Details */}
            <div>
              <h3 className="font-medium mb-3 text-gray-900 dark:text-white">Network Interfaces</h3>
              <div className="space-y-3 text-sm">
                {networkStatus?.ethernet?.interface && (
                  <div className="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="font-medium">Ethernet Interface</div>
                    <div className="mt-1 space-y-1 text-xs text-gray-600 dark:text-gray-400">
                      <div>Interface: {networkStatus.ethernet.interface}</div>
                      <div>MAC: {networkStatus.ethernet.mac || 'Unknown'}</div>
                      <div>MTU: {networkStatus.ethernet.mtu || '1500'}</div>
                    </div>
                  </div>
                )}
                {networkStatus?.wifi?.interface && (
                  <div className="p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div className="font-medium">WiFi Interface</div>
                    <div className="mt-1 space-y-1 text-xs text-gray-600 dark:text-gray-400">
                      <div>Interface: {networkStatus.wifi.interface}</div>
                      <div>MAC: {networkStatus.wifi.mac || 'Unknown'}</div>
                      <div>Driver: {networkStatus.wifi.driver || 'Unknown'}</div>
                    </div>
                  </div>
                )}
              </div>
            </div>
            
            {/* Connection History */}
            {connectionHistory.length > 0 && (
              <div>
                <h3 className="font-medium mb-3 text-gray-900 dark:text-white">Recent Connections</h3>
                <div className="space-y-2 text-sm">
                  {connectionHistory.slice(0, 5).map((conn, index) => (
                    <div key={index} className="flex justify-between p-2 bg-gray-50 dark:bg-gray-700 rounded">
                      <span>{conn.ssid || conn.interface}</span>
                      <span className="text-gray-500 text-xs">{conn.timestamp}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
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