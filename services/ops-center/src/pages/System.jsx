import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { 
  CpuChipIcon, 
  CircleStackIcon,
  ServerIcon,
  BoltIcon,
  ArrowPathIcon,
  ChartBarIcon,
  ClockIcon,
  FireIcon,
  ComputerDesktopIcon,
  RectangleStackIcon,
  WifiIcon,
  ArrowTopRightOnSquareIcon
} from '@heroicons/react/24/outline';
import { useSystem } from '../contexts/SystemContext';
import { useTheme } from '../contexts/ThemeContext';
import { LineChart, Line, AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function System() {
  const { systemStatus } = useSystem();
  const { currentTheme } = useTheme();
  const [historicalData, setHistoricalData] = useState({
    cpu: [],
    memory: [],
    gpu: [],
    disk: [],
    network: []
  });
  const [refreshInterval, setRefreshInterval] = useState(2000); // 2 seconds
  const [autoRefresh, setAutoRefresh] = useState(true);
  const [selectedGpu, setSelectedGpu] = useState(0);
  const [processes, setProcesses] = useState([]);
  const [hardwareInfo, setHardwareInfo] = useState(null);
  const [selectedView, setSelectedView] = useState('overview'); // overview, processes, hardware, networks
  const maxDataPoints = 30; // Keep last 30 data points

  // Use ref to maintain historical data across re-renders
  const dataRef = useRef(historicalData);

  useEffect(() => {
    // Fetch hardware info on mount
    fetchHardwareInfo();
    
    if (!systemStatus || !autoRefresh) return;

    const interval = setInterval(() => {
      updateHistoricalData();
      if (selectedView === 'processes') {
        fetchProcesses();
      }
    }, refreshInterval);

    return () => clearInterval(interval);
  }, [systemStatus, autoRefresh, refreshInterval, selectedView]);

  const fetchHardwareInfo = async () => {
    try {
      const response = await fetch('/api/v1/system/hardware');
      if (response.ok) {
        const data = await response.json();
        setHardwareInfo(data);
      }
    } catch (error) {
      console.error('Failed to fetch hardware info:', error);
    }
  };

  const fetchProcesses = async () => {
    try {
      const response = await fetch('/api/v1/system/status');
      if (response.ok) {
        const data = await response.json();
        if (data.processes) {
          setProcesses(data.processes);
        }
      }
    } catch (error) {
      console.error('Failed to fetch processes:', error);
    }
  };

  const updateHistoricalData = () => {
    if (!systemStatus) return;

    const timestamp = new Date().toLocaleTimeString();
    
    // Update CPU history
    const newCpuData = [...dataRef.current.cpu, {
      time: timestamp,
      usage: systemStatus.cpu?.percent || 0,
      temp: systemStatus.cpu?.temp || 0
    }].slice(-maxDataPoints);

    // Update Memory history
    const newMemoryData = [...dataRef.current.memory, {
      time: timestamp,
      used: ((systemStatus.memory?.used || 0) / (1024 * 1024 * 1024)).toFixed(2),
      percent: systemStatus.memory?.percent || 0
    }].slice(-maxDataPoints);

    // Update GPU history
    const newGpuData = [...dataRef.current.gpu];
    if (systemStatus.gpu && systemStatus.gpu.length > 0) {
      const gpuDataPoint = {
        time: timestamp,
        utilization: systemStatus.gpu[selectedGpu]?.utilization || 0,
        memory: ((systemStatus.gpu[selectedGpu]?.memory_used || 0) / (1024 * 1024 * 1024)).toFixed(2),
        temp: systemStatus.gpu[selectedGpu]?.temperature || 0,
        power: systemStatus.gpu[selectedGpu]?.power_draw || 0
      };
      newGpuData.push(gpuDataPoint);
    }
    const gpuHistory = newGpuData.slice(-maxDataPoints);

    // Update Disk I/O
    const newDiskData = [...dataRef.current.disk, {
      time: timestamp,
      read: Math.random() * 100, // Placeholder - would need real disk I/O stats
      write: Math.random() * 100
    }].slice(-maxDataPoints);

    // Update Network
    const newNetworkData = [...dataRef.current.network, {
      time: timestamp,
      in: Math.random() * 1000, // Placeholder - would need real network stats
      out: Math.random() * 500
    }].slice(-maxDataPoints);

    const newData = {
      cpu: newCpuData,
      memory: newMemoryData,
      gpu: gpuHistory,
      disk: newDiskData,
      network: newNetworkData
    };

    dataRef.current = newData;
    setHistoricalData(newData);
  };

  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatUptime = (seconds) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${minutes}m`;
  };

  if (!systemStatus || !systemStatus.cpu || !systemStatus.memory || !systemStatus.disk) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 mb-4">
            <svg className={`animate-spin h-12 w-12 ${currentTheme === 'unicorn' ? 'text-unicorn-purple' : 'text-primary-600'}`} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
          <h2 className={`text-xl font-semibold mb-2 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>Loading System Data</h2>
          <p className={currentTheme === 'unicorn' ? 'text-purple-200/80' : 'text-gray-600 dark:text-gray-400'}>Please wait while we gather system information...</p>
        </div>
      </div>
    );
  }

  const chartTheme = {
    backgroundColor: currentTheme === 'unicorn' ? 'transparent' : undefined,
    textColor: currentTheme === 'unicorn' ? '#fff' : '#374151',
    gridColor: currentTheme === 'unicorn' ? 'rgba(255,255,255,0.1)' : '#e5e7eb',
    tooltipBackground: currentTheme === 'unicorn' ? 'rgba(0,0,0,0.8)' : '#fff',
    tooltipBorder: currentTheme === 'unicorn' ? '#fff' : '#e5e7eb',
  };

  // Process data for charts
  const cpuCoreData = systemStatus.cpu?.per_cpu?.map((usage, index) => ({
    name: `Core ${index}`,
    usage: usage || 0
  })) || [];

  const memoryBreakdown = [
    { name: 'Used', value: systemStatus.memory?.used || 0, color: '#10b981' },
    { name: 'Available', value: systemStatus.memory?.available || 0, color: '#6366f1' },
    { name: 'Cached', value: (systemStatus.memory?.total - systemStatus.memory?.used - systemStatus.memory?.available) || 0, color: '#f59e0b' }
  ];

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className={`text-3xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
            System Monitoring
          </h1>
          <p className={`mt-2 ${currentTheme === 'unicorn' ? 'text-purple-200/80' : 'text-gray-600 dark:text-gray-400'}`}>
            Real-time system performance monitoring
          </p>
        </div>
        
        {/* Auto-refresh controls */}
        <div className="flex items-center gap-4">
          <select
            value={refreshInterval}
            onChange={(e) => setRefreshInterval(Number(e.target.value))}
            className={`px-3 py-2 rounded-lg ${
              currentTheme === 'unicorn' 
                ? 'bg-white/10 border-white/20 text-white' 
                : 'bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600'
            }`}
          >
            <option value={1000}>1 second</option>
            <option value={2000}>2 seconds</option>
            <option value={5000}>5 seconds</option>
            <option value={10000}>10 seconds</option>
          </select>
          
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`px-4 py-2 rounded-lg flex items-center gap-2 ${
              autoRefresh
                ? currentTheme === 'unicorn' 
                  ? 'bg-unicorn-purple text-white' 
                  : 'bg-green-600 text-white'
                : currentTheme === 'unicorn'
                  ? 'bg-white/20 text-white'
                  : 'bg-gray-600 text-white'
            }`}
          >
            <ArrowPathIcon className={`h-5 w-5 ${autoRefresh ? 'animate-spin' : ''}`} />
            {autoRefresh ? 'Auto-refresh On' : 'Auto-refresh Off'}
          </button>
        </div>
      </div>

      {/* View Selector */}
      <div className="flex gap-1 p-1 bg-gray-700/30 rounded-lg w-fit">
        {[
          { id: 'overview', name: 'Overview', icon: ChartBarIcon },
          { id: 'hardware', name: 'Hardware', icon: ComputerDesktopIcon },
          { id: 'processes', name: 'Processes', icon: RectangleStackIcon },
          { id: 'network', name: 'Network', icon: WifiIcon }
        ].map(({ id, name, icon: Icon }) => (
          <button
            key={id}
            onClick={() => setSelectedView(id)}
            className={`px-4 py-2 rounded-md text-sm transition-all flex items-center gap-2 ${
              selectedView === id
                ? 'bg-blue-500 text-white shadow-sm'
                : 'text-gray-400 hover:text-white hover:bg-blue-500/20'
            }`}
          >
            <Icon className="h-4 w-4" />
            {name}
          </button>
        ))}
      </div>

      {selectedView === 'overview' && (
        <>
      {/* System Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>CPU Usage</p>
              <p className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                {systemStatus.cpu.percent.toFixed(1)}%
              </p>
              <p className={`text-xs mt-1 ${currentTheme === 'unicorn' ? 'text-purple-200/60' : 'text-gray-500'}`}>
                {systemStatus.cpu?.cores || 0} cores @ {systemStatus.cpu?.freq_current || 0}MHz
              </p>
            </div>
            <CpuChipIcon className={`h-10 w-10 ${currentTheme === 'unicorn' ? 'text-unicorn-blue' : 'text-primary-600 dark:text-primary-400'}`} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Memory</p>
              <p className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                {formatBytes(systemStatus.memory?.used || 0)}
              </p>
              <p className={`text-xs mt-1 ${currentTheme === 'unicorn' ? 'text-purple-200/60' : 'text-gray-500'}`}>
                of {formatBytes(systemStatus.memory?.total || 0)} ({systemStatus.memory?.percent?.toFixed(1) || 0}%)
              </p>
            </div>
            <CircleStackIcon className={`h-10 w-10 ${currentTheme === 'unicorn' ? 'text-unicorn-green' : 'text-green-600 dark:text-green-400'}`} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Storage</p>
              <p className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                {formatBytes(systemStatus.disk?.used || 0)}
              </p>
              <p className={`text-xs mt-1 ${currentTheme === 'unicorn' ? 'text-purple-200/60' : 'text-gray-500'}`}>
                of {formatBytes(systemStatus.disk?.total || 0)} ({systemStatus.disk?.percent?.toFixed(1) || 0}%)
              </p>
            </div>
            <ServerIcon className={`h-10 w-10 ${currentTheme === 'unicorn' ? 'text-unicorn-purple' : 'text-purple-600 dark:text-purple-400'}`} />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.3 }}
          className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}
        >
          <div className="flex items-center justify-between">
            <div>
              <p className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Uptime</p>
              <p className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                {formatUptime(systemStatus.uptime || 0)}
              </p>
              <p className={`text-xs mt-1 ${currentTheme === 'unicorn' ? 'text-purple-200/60' : 'text-gray-500'}`}>
                Load: {systemStatus.load_average?.join(', ') || 'N/A'}
              </p>
            </div>
            <BoltIcon className={`h-10 w-10 ${currentTheme === 'unicorn' ? 'text-unicorn-gold' : 'text-yellow-600 dark:text-yellow-400'}`} />
          </div>
        </motion.div>
      </div>

      {/* Real-time Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CPU Usage Chart */}
        <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
          <h2 className={`text-lg font-semibold mb-4 flex items-center gap-2 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
            <CpuChipIcon className="h-5 w-5" />
            CPU Usage History
          </h2>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={historicalData.cpu}>
              <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
              <XAxis 
                dataKey="time" 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
              />
              <YAxis 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
                domain={[0, 100]}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: chartTheme.tooltipBackground,
                  border: `1px solid ${chartTheme.tooltipBorder}`,
                  borderRadius: '8px'
                }}
              />
              <Area 
                type="monotone" 
                dataKey="usage" 
                stroke="#3b82f6" 
                fill="#3b82f6" 
                fillOpacity={0.3} 
                name="CPU %"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Memory Usage Chart */}
        <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
          <h2 className={`text-lg font-semibold mb-4 flex items-center gap-2 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
            <CircleStackIcon className="h-5 w-5" />
            Memory Usage History
          </h2>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={historicalData.memory}>
              <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
              <XAxis 
                dataKey="time" 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
              />
              <YAxis 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
                domain={[0, 100]}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: chartTheme.tooltipBackground,
                  border: `1px solid ${chartTheme.tooltipBorder}`,
                  borderRadius: '8px'
                }}
              />
              <Line 
                type="monotone" 
                dataKey="percent" 
                stroke="#10b981" 
                strokeWidth={2}
                dot={false}
                name="Memory %"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* GPU Charts */}
      {systemStatus.gpu && Array.isArray(systemStatus.gpu) && systemStatus.gpu.length > 0 && (
        <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
          <div className="flex justify-between items-center mb-4">
            <h2 className={`text-lg font-semibold flex items-center gap-2 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
              <FireIcon className="h-5 w-5" />
              GPU Performance
            </h2>
            {systemStatus.gpu.length > 1 && (
              <select
                value={selectedGpu}
                onChange={(e) => setSelectedGpu(Number(e.target.value))}
                className={`px-3 py-1 rounded-lg text-sm ${
                  currentTheme === 'unicorn' 
                    ? 'bg-white/10 border-white/20 text-white' 
                    : 'bg-gray-100 dark:bg-gray-700 border-gray-300 dark:border-gray-600'
                }`}
              >
                {systemStatus.gpu.map((gpu, index) => (
                  <option key={index} value={index}>
                    {gpu.name}
                  </option>
                ))}
              </select>
            )}
          </div>

          <div className="grid grid-cols-2 gap-6">
            {/* GPU Utilization */}
            <div>
              <h3 className={`text-sm font-medium mb-2 ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>
                GPU Utilization & Temperature
              </h3>
              <ResponsiveContainer width="100%" height={200}>
                <LineChart data={historicalData.gpu}>
                  <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
                  <XAxis 
                    dataKey="time" 
                    stroke={chartTheme.textColor}
                    tick={{ fill: chartTheme.textColor }}
                  />
                  <YAxis 
                    stroke={chartTheme.textColor}
                    tick={{ fill: chartTheme.textColor }}
                    domain={[0, 100]}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: chartTheme.tooltipBackground,
                      border: `1px solid ${chartTheme.tooltipBorder}`,
                      borderRadius: '8px'
                    }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="utilization" 
                    stroke="#f59e0b" 
                    strokeWidth={2}
                    dot={false}
                    name="Utilization %"
                  />
                  <Line 
                    type="monotone" 
                    dataKey="temp" 
                    stroke="#ef4444" 
                    strokeWidth={2}
                    dot={false}
                    name="Temperature °C"
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* GPU Memory & Power */}
            <div>
              <h3 className={`text-sm font-medium mb-2 ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>
                GPU Memory & Power
              </h3>
              <ResponsiveContainer width="100%" height={200}>
                <LineChart data={historicalData.gpu}>
                  <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
                  <XAxis 
                    dataKey="time" 
                    stroke={chartTheme.textColor}
                    tick={{ fill: chartTheme.textColor }}
                  />
                  <YAxis 
                    stroke={chartTheme.textColor}
                    tick={{ fill: chartTheme.textColor }}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: chartTheme.tooltipBackground,
                      border: `1px solid ${chartTheme.tooltipBorder}`,
                      borderRadius: '8px'
                    }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="memory" 
                    stroke="#8b5cf6" 
                    strokeWidth={2}
                    dot={false}
                    name="Memory GB"
                  />
                  <Line 
                    type="monotone" 
                    dataKey="power" 
                    stroke="#06b6d4" 
                    strokeWidth={2}
                    dot={false}
                    name="Power W"
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
      )}

      {/* Additional System Info */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CPU Cores Breakdown */}
        <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
          <h2 className={`text-lg font-semibold mb-4 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
            CPU Cores Usage
          </h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={cpuCoreData}>
              <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
              <XAxis 
                dataKey="name" 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
              />
              <YAxis 
                stroke={chartTheme.textColor}
                tick={{ fill: chartTheme.textColor }}
                domain={[0, 100]}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: chartTheme.tooltipBackground,
                  border: `1px solid ${chartTheme.tooltipBorder}`,
                  borderRadius: '8px'
                }}
              />
              <Bar dataKey="usage" fill="#3b82f6" />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Memory Breakdown */}
        <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
          <h2 className={`text-lg font-semibold mb-4 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
            Memory Breakdown
          </h2>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie
                data={memoryBreakdown}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {memoryBreakdown.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: chartTheme.tooltipBackground,
                  border: `1px solid ${chartTheme.tooltipBorder}`,
                  borderRadius: '8px'
                }}
                formatter={(value) => formatBytes(value)}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Process List */}
      <div className={currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20 rounded-lg shadow-xl p-6' : 'bg-white dark:bg-gray-800 rounded-lg shadow p-6'}>
        <h2 className={`text-lg font-semibold mb-4 ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
          Top Processes
        </h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead>
              <tr>
                <th className={`px-4 py-2 text-left text-xs font-medium uppercase ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                  Process
                </th>
                <th className={`px-4 py-2 text-left text-xs font-medium uppercase ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                  PID
                </th>
                <th className={`px-4 py-2 text-left text-xs font-medium uppercase ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                  CPU %
                </th>
                <th className={`px-4 py-2 text-left text-xs font-medium uppercase ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                  Memory
                </th>
                <th className={`px-4 py-2 text-left text-xs font-medium uppercase ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {systemStatus.processes && Array.isArray(systemStatus.processes) && systemStatus.processes.map((process, index) => (
                <tr key={index} className="hover:bg-gray-50 dark:hover:bg-gray-700/50">
                  <td className={`px-4 py-2 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                    {process.name}
                  </td>
                  <td className={`px-4 py-2 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                    {process.pid}
                  </td>
                  <td className={`px-4 py-2 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                    {process.cpu_percent?.toFixed(1) || 0}%
                  </td>
                  <td className={`px-4 py-2 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                    {formatBytes((process.memory_mb || 0) * 1024 * 1024)}
                  </td>
                  <td className={`px-4 py-2 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      process.status === 'running' 
                        ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                        : 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
                    }`}>
                      {process.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
        </>
      )}

      {/* Hardware View */}
      {selectedView === 'hardware' && (
        <div className="space-y-6">
          {hardwareInfo && (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {/* CPU Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <CpuChipIcon className="h-5 w-5 text-blue-500" />
                  CPU Information
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Model:</span>
                    <span className={`${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} font-mono`}>
                      {hardwareInfo.cpu.model}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Cores:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.cpu.cores} ({hardwareInfo.cpu.threads} threads)
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Base Frequency:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.cpu.baseFreq}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Max Frequency:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.cpu.maxFreq}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* GPU Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <FireIcon className="h-5 w-5 text-red-500" />
                  GPU Information
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Model:</span>
                    <span className={`${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} font-mono text-xs`}>
                      {hardwareInfo.gpu.model}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>VRAM:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.gpu.vram}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Driver:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.gpu.driver}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>CUDA:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.gpu.cuda}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* Memory Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <CircleStackIcon className="h-5 w-5 text-green-500" />
                  Memory Information
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Total:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.memory.total} {hardwareInfo.memory.type}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Configuration:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.memory.slots}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* iGPU Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <ComputerDesktopIcon className="h-5 w-5 text-purple-500" />
                  iGPU Information
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Model:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.igpu.model}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Driver:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.igpu.driver}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* Storage Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <ServerIcon className="h-5 w-5 text-indigo-500" />
                  Storage Information
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Primary:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.storage.primary}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Secondary:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.storage.secondary}
                    </span>
                  </div>
                </div>
              </motion.div>

              {/* OS Details */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
              >
                <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
                  <BoltIcon className="h-5 w-5 text-orange-500" />
                  Operating System
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>OS:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.os.name} {hardwareInfo.os.version}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Kernel:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.os.kernel}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className={currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}>Desktop:</span>
                    <span className={currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}>
                      {hardwareInfo.os.desktop}
                    </span>
                  </div>
                </div>
              </motion.div>
            </div>
          )}
        </div>
      )}

      {/* Processes View */}
      {selectedView === 'processes' && (
        <div className="space-y-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl overflow-hidden`}
          >
            <div className="p-6 border-b border-gray-200 dark:border-gray-700">
              <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} flex items-center gap-2`}>
                <RectangleStackIcon className="h-5 w-5 text-blue-500" />
                Top Processes (by CPU Usage)
              </h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className={currentTheme === 'unicorn' ? 'bg-white/5' : 'bg-gray-50 dark:bg-gray-700/50'}>
                    <th className={`px-6 py-3 text-left text-xs font-medium uppercase tracking-wider ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                      Process
                    </th>
                    <th className={`px-6 py-3 text-left text-xs font-medium uppercase tracking-wider ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                      PID
                    </th>
                    <th className={`px-6 py-3 text-left text-xs font-medium uppercase tracking-wider ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                      CPU %
                    </th>
                    <th className={`px-6 py-3 text-left text-xs font-medium uppercase tracking-wider ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                      Memory
                    </th>
                    <th className={`px-6 py-3 text-left text-xs font-medium uppercase tracking-wider ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-500 dark:text-gray-400'}`}>
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                  {processes.slice(0, 15).map((process, index) => (
                    <motion.tr
                      key={`${process.pid}-${index}`}
                      initial={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{ delay: index * 0.05 }}
                      className="hover:bg-gray-50 dark:hover:bg-gray-700/50"
                    >
                      <td className={`px-6 py-4 text-sm font-medium ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                        {process.name}
                      </td>
                      <td className={`px-6 py-4 text-sm ${currentTheme === 'unicorn' ? 'text-purple-200' : 'text-gray-600 dark:text-gray-400'}`}>
                        {process.pid}
                      </td>
                      <td className={`px-6 py-4 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                        <div className="flex items-center gap-2">
                          <div className={`w-12 h-2 rounded-full ${currentTheme === 'unicorn' ? 'bg-white/20' : 'bg-gray-200 dark:bg-gray-700'}`}>
                            <div 
                              className={`h-full rounded-full ${
                                process.cpu_percent > 50 ? 'bg-red-500' : 
                                process.cpu_percent > 25 ? 'bg-yellow-500' : 'bg-green-500'
                              }`}
                              style={{ width: `${Math.min(process.cpu_percent || 0, 100)}%` }}
                            />
                          </div>
                          <span>{(process.cpu_percent || 0).toFixed(1)}%</span>
                        </div>
                      </td>
                      <td className={`px-6 py-4 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                        {formatBytes((process.memory_mb || 0) * 1024 * 1024)}
                      </td>
                      <td className={`px-6 py-4 text-sm ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          process.status === 'running' 
                            ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                            : process.status === 'sleeping'
                            ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                            : 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200'
                        }`}>
                          {process.status}
                        </span>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </div>
          </motion.div>
        </div>
      )}

      {/* Storage View */}
      {selectedView === 'storage' && (
        <div className="space-y-6">
          {/* Storage Overview */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
          >
            <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-6 flex items-center gap-2`}>
              <ServerIcon className="h-5 w-5 text-purple-500" />
              Storage Overview
            </h3>
            
            {storageDetails ? (
              <div className="space-y-6">
                {/* Main Storage Stats */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className={`p-4 rounded-lg ${currentTheme === 'unicorn' ? 'bg-white/5' : 'bg-gray-50 dark:bg-gray-700/50'}`}>
                    <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Total Space</div>
                    <div className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                      {formatBytes(storageDetails.total_space)}
                    </div>
                  </div>
                  <div className={`p-4 rounded-lg ${currentTheme === 'unicorn' ? 'bg-white/5' : 'bg-gray-50 dark:bg-gray-700/50'}`}>
                    <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Used Space</div>
                    <div className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                      {formatBytes(storageDetails.used_space)}
                    </div>
                    <div className="text-xs text-orange-500">
                      {((storageDetails.used_space / storageDetails.total_space) * 100).toFixed(1)}%
                    </div>
                  </div>
                  <div className={`p-4 rounded-lg ${currentTheme === 'unicorn' ? 'bg-white/5' : 'bg-gray-50 dark:bg-gray-700/50'}`}>
                    <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>Free Space</div>
                    <div className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                      {formatBytes(storageDetails.free_space)}
                    </div>
                  </div>
                </div>

                {/* Storage Volumes */}
                <div>
                  <h4 className={`font-medium ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4`}>
                    Volume Details ({storageDetails.volumes?.length || 0} volumes)
                  </h4>
                  <div className="space-y-3">
                    {storageDetails.volumes?.map((volume, index) => (
                      <div key={volume.name} className={`p-4 rounded-lg border ${currentTheme === 'unicorn' ? 'bg-white/5 border-white/10' : 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'}`}>
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-3">
                            <div className={`w-3 h-3 rounded-full ${volume.health === 'healthy' ? 'bg-green-500' : volume.health === 'warning' ? 'bg-yellow-500' : 'bg-red-500'}`} />
                            <div>
                              <div className={`font-medium ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                                {volume.name}
                              </div>
                              <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>
                                {volume.type} • {volume.path}
                              </div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className={`font-medium ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                              {formatBytes(volume.size)}
                            </div>
                            <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>
                              {volume.last_accessed}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ) : (
              <div className="text-center py-8">
                <div className="inline-flex items-center justify-center w-16 h-16 mb-4">
                  <div className={`animate-spin h-8 w-8 border-2 border-dashed rounded-full ${currentTheme === 'unicorn' ? 'border-purple-300' : 'border-gray-400'}`} />
                </div>
                <p className={`${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'}`}>
                  Loading storage information...
                </p>
              </div>
            )}
          </motion.div>

          {/* Disk I/O Performance */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
          >
            <h4 className={`font-medium ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
              <ChartBarIcon className="h-5 w-5 text-blue-500" />
              Disk I/O Performance
            </h4>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'} mb-2`}>
                  Current Read Rate
                </div>
                <div className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                  {formatBytes(diskIoStats.read)}/s
                </div>
              </div>
              <div>
                <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'} mb-2`}>
                  Current Write Rate
                </div>
                <div className={`text-2xl font-bold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'}`}>
                  {formatBytes(diskIoStats.write)}/s
                </div>
              </div>
            </div>
            
            {/* Historical Disk I/O Chart */}
            {historicalData.disk.length > 0 && (
              <div className="mt-6">
                <h5 className={`text-sm font-medium ${currentTheme === 'unicorn' ? 'text-purple-200' : 'text-gray-700 dark:text-gray-300'} mb-3`}>
                  Historical Disk I/O (MB/s)
                </h5>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={historicalData.disk}>
                      <CartesianGrid strokeDasharray="3 3" stroke={chartTheme.gridColor} />
                      <XAxis dataKey="time" stroke={chartTheme.textColor} fontSize={12} />
                      <YAxis stroke={chartTheme.textColor} fontSize={12} />
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: chartTheme.tooltipBackground,
                          border: `1px solid ${chartTheme.tooltipBorder}`,
                          borderRadius: '8px'
                        }}
                      />
                      <Legend />
                      <Area type="monotone" dataKey="read" stackId="1" stroke="#10b981" fill="#10b981" fillOpacity={0.3} name="Read" />
                      <Area type="monotone" dataKey="write" stackId="1" stroke="#f59e0b" fill="#f59e0b" fillOpacity={0.3} name="Write" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}
          </motion.div>
        </div>
      )}

      {/* Network View */}
      {selectedView === 'network' && (
        <div className="space-y-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className={`${currentTheme === 'unicorn' ? 'bg-white/10 backdrop-blur-lg border border-white/20' : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'} rounded-xl p-6`}
          >
            <h3 className={`text-lg font-semibold ${currentTheme === 'unicorn' ? 'text-white' : 'text-gray-900 dark:text-white'} mb-4 flex items-center gap-2`}>
              <WifiIcon className="h-5 w-5 text-blue-500" />
              Network Configuration
            </h3>
            <div className="text-center py-8">
              <p className={`${currentTheme === 'unicorn' ? 'text-purple-200/70' : 'text-gray-600 dark:text-gray-400'} mb-4`}>
                Network management features coming soon...
              </p>
              <button 
                onClick={() => window.location.href = '/admin/network'}
                className="inline-flex items-center gap-2 px-4 py-2 bg-blue-500/20 text-blue-400 rounded-lg hover:bg-blue-500/30 transition-colors"
              >
                <ArrowTopRightOnSquareIcon className="h-4 w-4" />
                Go to Network Settings
              </button>
            </div>
          </motion.div>
        </div>
      )}
    </div>
  );
}