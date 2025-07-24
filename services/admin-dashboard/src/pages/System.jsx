import React from 'react';
import { motion } from 'framer-motion';
import { 
  CpuChipIcon, 
  CircleStackIcon,
  ServerIcon,
  BoltIcon
} from '@heroicons/react/24/outline';
import { useSystem } from '../contexts/SystemContext';

export default function System() {
  const { systemStatus } = useSystem();

  if (!systemStatus || !systemStatus.cpu || !systemStatus.memory || !systemStatus.disk) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 mb-4">
            <svg className="animate-spin h-12 w-12 text-primary-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">Loading System Data</h2>
          <p className="text-gray-600 dark:text-gray-400">Please wait while we gather system information...</p>
        </div>
      </div>
    );
  }

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

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          System Overview
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Monitor system resources and performance
        </p>
      </div>

      {/* System Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">CPU Usage</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {systemStatus.cpu.percent.toFixed(1)}%
              </p>
              <p className="text-xs text-gray-500 mt-1">
                {systemStatus.cpu?.cores || 0} cores @ {systemStatus.cpu?.freq_current || 0}MHz
              </p>
            </div>
            <CpuChipIcon className="h-10 w-10 text-primary-600 dark:text-primary-400" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Memory</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {formatBytes(systemStatus.memory.used)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                of {formatBytes(systemStatus.memory?.total || 0)} ({systemStatus.memory?.percent?.toFixed(1) || 0}%)
              </p>
            </div>
            <CircleStackIcon className="h-10 w-10 text-green-600 dark:text-green-400" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Storage</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {formatBytes(systemStatus.disk.used)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                of {formatBytes(systemStatus.disk?.total || 0)} ({systemStatus.disk?.percent?.toFixed(1) || 0}%)
              </p>
            </div>
            <ServerIcon className="h-10 w-10 text-purple-600 dark:text-purple-400" />
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.3 }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Uptime</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {formatUptime(systemStatus.uptime || 0)}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                Load: {systemStatus.load_average?.join(', ') || 'N/A'}
              </p>
            </div>
            <BoltIcon className="h-10 w-10 text-yellow-600 dark:text-yellow-400" />
          </div>
        </motion.div>
      </div>

      {/* GPU Information */}
      {systemStatus.gpu && Array.isArray(systemStatus.gpu) && systemStatus.gpu.length > 0 && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
            GPU Information
          </h2>
          {systemStatus.gpu.map((gpu, index) => (
            <div key={index} className="border-b dark:border-gray-700 pb-4 mb-4 last:border-0 last:pb-0 last:mb-0">
              <h3 className="font-medium text-gray-900 dark:text-white">{gpu.name}</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-3">
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Utilization</p>
                  <p className="text-lg font-semibold text-gray-900 dark:text-white">
                    {gpu.utilization || 0}%
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Memory</p>
                  <p className="text-lg font-semibold text-gray-900 dark:text-white">
                    {formatBytes(gpu.memory_used || 0)} / {formatBytes(gpu.memory_total || 0)}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Temperature</p>
                  <p className="text-lg font-semibold text-gray-900 dark:text-white">
                    {gpu.temperature || 0}°C
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Power</p>
                  <p className="text-lg font-semibold text-gray-900 dark:text-white">
                    {gpu.power_draw || 0}W / {gpu.power_limit || 0}W
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Process List */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Top Processes
        </h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead>
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                  Process
                </th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                  CPU %
                </th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                  Memory
                </th>
                <th className="px-4 py-2 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase">
                  Status
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {systemStatus.processes && Array.isArray(systemStatus.processes) && systemStatus.processes.map((process, index) => (
                <tr key={index}>
                  <td className="px-4 py-2 text-sm text-gray-900 dark:text-white">
                    {process.name}
                  </td>
                  <td className="px-4 py-2 text-sm text-gray-900 dark:text-white">
                    {process.cpu_percent?.toFixed(1) || 0}%
                  </td>
                  <td className="px-4 py-2 text-sm text-gray-900 dark:text-white">
                    {formatBytes((process.memory_mb || 0) * 1024 * 1024)}
                  </td>
                  <td className="px-4 py-2 text-sm text-gray-900 dark:text-white">
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