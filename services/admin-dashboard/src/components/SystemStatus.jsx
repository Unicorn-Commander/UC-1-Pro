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
  const { systemStatus, updateSystemStatus } = useSystem();
  const [gpuHistory, setGpuHistory] = useState([]);

  useEffect(() => {
    const interval = setInterval(() => {
      updateSystemStatus();
    }, 5000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <MetricCard
        title="GPU Usage"
        value={systemStatus.gpu.usage}
        unit="%"
        color="text-blue-600 dark:text-blue-400"
        icon="🎮"
      />
      <MetricCard
        title="GPU Memory"
        value={systemStatus.gpu.memory.used}
        unit={`/ ${systemStatus.gpu.memory.total}GB`}
        color="text-purple-600 dark:text-purple-400"
        icon="💾"
      />
      <MetricCard
        title="CPU Usage"
        value={systemStatus.cpu.usage}
        unit="%"
        color="text-green-600 dark:text-green-400"
        icon="💻"
      />
      <MetricCard
        title="System Memory"
        value={systemStatus.memory.used}
        unit={`/ ${systemStatus.memory.total}GB`}
        color="text-orange-600 dark:text-orange-400"
        icon="🧠"
      />
    </div>
  );
}