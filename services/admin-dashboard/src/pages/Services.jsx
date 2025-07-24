import React from 'react';
import { motion } from 'framer-motion';
import { 
  PlayIcon, 
  StopIcon, 
  ArrowPathIcon,
  ChartBarIcon,
  ClockIcon,
  CpuChipIcon
} from '@heroicons/react/24/outline';
import { useSystem } from '../contexts/SystemContext';

export default function Services() {
  const { services, controlService } = useSystem();

  const getStatusColor = (status) => {
    switch (status) {
      case 'running':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'stopped':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
      case 'error':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
      case 'starting':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
    }
  };

  const getActionButton = (service) => {
    if (service.status === 'running') {
      return (
        <button
          onClick={() => controlService(service.name, 'stop')}
          className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 flex items-center gap-1"
        >
          <StopIcon className="h-4 w-4" />
          Stop
        </button>
      );
    } else if (service.status === 'stopped') {
      return (
        <button
          onClick={() => controlService(service.name, 'start')}
          className="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 flex items-center gap-1"
        >
          <PlayIcon className="h-4 w-4" />
          Start
        </button>
      );
    } else {
      return (
        <button
          onClick={() => controlService(service.name, 'restart')}
          className="px-3 py-1 bg-yellow-600 text-white rounded hover:bg-yellow-700 flex items-center gap-1"
        >
          <ArrowPathIcon className="h-4 w-4" />
          Restart
        </button>
      );
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          Service Management
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Monitor and control all UC-1 Pro services
        </p>
      </div>

      <div className="grid gap-6">
        {services.map((service, index) => (
          <motion.div
            key={service.name}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.05 }}
            className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                    {service.display_name}
                  </h3>
                  <span className={`px-2 py-1 text-xs rounded-full ${getStatusColor(service.status)}`}>
                    {service.status}
                  </span>
                </div>
                
                <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
                  {service.description}
                </p>

                <div className="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-4">
                  <div className="flex items-center gap-2 text-sm">
                    <CpuChipIcon className="h-4 w-4 text-gray-400" />
                    <span className="text-gray-600 dark:text-gray-400">
                      CPU: {service.cpu_percent?.toFixed(1) || 0}%
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <ChartBarIcon className="h-4 w-4 text-gray-400" />
                    <span className="text-gray-600 dark:text-gray-400">
                      Memory: {service.memory_mb ? `${service.memory_mb}MB` : 'N/A'}
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <ClockIcon className="h-4 w-4 text-gray-400" />
                    <span className="text-gray-600 dark:text-gray-400">
                      Uptime: {service.uptime || 'N/A'}
                    </span>
                  </div>
                  <div className="text-sm text-gray-600 dark:text-gray-400">
                    Port: {service.port || 'N/A'}
                  </div>
                </div>

                {service.health_check && (
                  <div className="mt-3 text-sm">
                    <span className="text-gray-600 dark:text-gray-400">
                      Health: {service.health_check.status}
                    </span>
                    {service.health_check.message && (
                      <span className="ml-2 text-gray-500">
                        ({service.health_check.message})
                      </span>
                    )}
                  </div>
                )}
              </div>

              <div className="flex gap-2 ml-4">
                {getActionButton(service)}
                <button
                  onClick={() => controlService(service.name, 'restart')}
                  className="px-3 py-1 bg-gray-600 text-white rounded hover:bg-gray-700"
                >
                  <ArrowPathIcon className="h-4 w-4" />
                </button>
              </div>
            </div>

            {service.logs && service.logs.length > 0 && (
              <div className="mt-4 border-t dark:border-gray-700 pt-4">
                <h4 className="text-sm font-medium text-gray-900 dark:text-white mb-2">
                  Recent Logs
                </h4>
                <div className="bg-gray-50 dark:bg-gray-900 rounded p-3 text-xs font-mono overflow-x-auto">
                  {service.logs.slice(-5).map((log, i) => (
                    <div key={i} className="text-gray-600 dark:text-gray-400">
                      {log}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </motion.div>
        ))}
      </div>
    </div>
  );
}