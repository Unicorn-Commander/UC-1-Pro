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
  FireIcon
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
  const maxDataPoints = 30; // Keep last 30 data points

  // Use ref to maintain historical data across re-renders
  const dataRef = useRef(historicalData);

  useEffect(() => {
    if (!systemStatus || !autoRefresh) return;

    const interval = setInterval(() => {
      updateHistoricalData();
    }, refreshInterval);

    return () => clearInterval(interval);
  }, [systemStatus, autoRefresh, refreshInterval]);

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
    </div>
  );
}