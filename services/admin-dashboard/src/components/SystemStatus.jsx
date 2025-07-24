import React, { useEffect, useState } from 'react';
import { Line } from 'recharts';
import { motion } from 'framer-motion';
import { useSystem } from '../contexts/SystemContext';

const MetricCard = ({ title, value, unit, color, icon }) => {
  return (
    <motion.div
      className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6"
      whileHover={{ scale: 1.02 }}
      transition={{ type: "spring", stiffness: 300 }}
    >
      <div className="flex items-center justify-between mb-2">
        <span className="text-gray-600 dark:text-gray-400 text-sm font-medium">{title}</span>
        <span className="text-2xl">{icon}</span>
      </div>
      <div className="flex items-baseline">
        <span className={`text-3xl font-bold ${color}`}>{value}</span>
        <span className="ml-1 text-gray-600 dark:text-gray-400 text-sm">{unit}</span>
      </div>
    </motion.div>
  );
};

export default function SystemStatus() {
  const { systemStatus } = useSystem();

  // Don't render if data isn't ready
  if (!systemStatus || !systemStatus.cpu || !systemStatus.memory) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 animate-pulse">
            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
          </div>
        ))}
      </div>
    );
  }

  // Helper function to format bytes to GB
  const formatBytesToGB = (bytes) => {
    if (!bytes) return '0';
    return (bytes / (1024 ** 3)).toFixed(1);
  };

  // Get GPU data (use first GPU if available)
  const gpuData = systemStatus.gpu && Array.isArray(systemStatus.gpu) && systemStatus.gpu.length > 0 
    ? systemStatus.gpu[0] 
    : null;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <MetricCard
        title="GPU Usage"
        value={gpuData?.utilization || 0}
        unit="%"
        color="text-blue-600 dark:text-blue-400"
        icon="🎮"
      />
      <MetricCard
        title="GPU Memory"
        value={formatBytesToGB(gpuData?.memory_used)}
        unit={`/ ${formatBytesToGB(gpuData?.memory_total)}GB`}
        color="text-purple-600 dark:text-purple-400"
        icon="💾"
      />
      <MetricCard
        title="CPU Usage"
        value={systemStatus.cpu?.percent?.toFixed(1) || 0}
        unit="%"
        color="text-green-600 dark:text-green-400"
        icon="💻"
      />
      <MetricCard
        title="System Memory"
        value={formatBytesToGB(systemStatus.memory?.used)}
        unit={`/ ${formatBytesToGB(systemStatus.memory?.total)}GB`}
        color="text-orange-600 dark:text-orange-400"
        icon="🧠"
      />
    </div>
  );
}