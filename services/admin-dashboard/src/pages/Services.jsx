import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { useSystem } from '../contexts/SystemContext';
import LogsViewer from '../components/LogsViewer';
import ServiceDetailsModal from '../components/ServiceDetailsModal';
import {
  PlayIcon,
  StopIcon,
  ArrowPathIcon,
  Cog6ToothIcon,
  DocumentTextIcon,
  GlobeAltIcon,
  CpuChipIcon,
  CircleStackIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  ExclamationTriangleIcon,
  PauseIcon,
  ServerIcon,
  InformationCircleIcon
} from '@heroicons/react/24/outline';
import { CpuChipIcon as CpuChipSolid } from '@heroicons/react/24/solid';

// Service URLs for "Open UI" buttons
const serviceUrls = {
  'vllm': 'http://localhost:8000/docs',
  'open-webui': 'http://localhost:8080',
  'searxng': 'http://localhost:8888',
  'prometheus': 'http://localhost:9090',
  'grafana': 'http://localhost:3000',
  'portainer': 'http://localhost:9443',
  'comfyui': 'http://localhost:8188',
  'n8n': 'http://localhost:5678',
  'qdrant': 'http://localhost:6333/dashboard',
  'admin-dashboard': 'http://localhost:8084'
};

// Helper functions
const getStatusConfig = (status) => {
  switch (status) {
    case 'healthy':
    case 'running':
      return {
        icon: CheckCircleIcon,
        color: 'text-green-500',
        bg: 'bg-green-50 dark:bg-green-900/20',
        border: 'border-green-200 dark:border-green-800',
        pulse: true,
        label: 'Running'
      };
    case 'starting':
    case 'restarting':
      return {
        icon: ClockIcon,
        color: 'text-blue-500',
        bg: 'bg-blue-50 dark:bg-blue-900/20',
        border: 'border-blue-200 dark:border-blue-800',
        pulse: true,
        label: 'Starting'
      };
    case 'stopped':
    case 'exited':
      return {
        icon: XCircleIcon,
        color: 'text-gray-400',
        bg: 'bg-gray-50 dark:bg-gray-900/20',
        border: 'border-gray-200 dark:border-gray-800',
        pulse: false,
        label: 'Stopped'
      };
    case 'paused':
      return {
        icon: PauseIcon,
        color: 'text-yellow-500',
        bg: 'bg-yellow-50 dark:bg-yellow-900/20',
        border: 'border-yellow-200 dark:border-yellow-800',
        pulse: false,
        label: 'Paused'
      };
    default:
      return {
        icon: ExclamationTriangleIcon,
        color: 'text-red-500',
        bg: 'bg-red-50 dark:bg-red-900/20',
        border: 'border-red-200 dark:border-red-800',
        pulse: false,
        label: status || 'Unknown'
      };
  }
};

const formatMemory = (memoryMb) => {
  if (!memoryMb || memoryMb === 0) return '0 MB';
  if (memoryMb > 1024) {
    return `${(memoryMb / 1024).toFixed(1)} GB`;
  }
  return `${Math.round(memoryMb)} MB`;
};

const isRunning = (status) => {
  return status === 'healthy' || status === 'running';
};

export default function Services() {
  const { services, controlService, wsConnected } = useSystem();
  const [loading, setLoading] = useState({});
  const [logsViewerOpen, setLogsViewerOpen] = useState(false);
  const [selectedContainer, setSelectedContainer] = useState(null);
  const [detailsModalOpen, setDetailsModalOpen] = useState(false);
  const [selectedService, setSelectedService] = useState(null);

  const handleServiceAction = async (containerName, action) => {
    setLoading(prev => ({ ...prev, [`${containerName}-${action}`]: true }));
    
    try {
      await controlService(containerName, action);
      // Refresh services after action
      setTimeout(() => {
        window.location.reload();
      }, 2000);
    } catch (error) {
      console.error(`Failed to ${action} service ${containerName}:`, error);
    } finally {
      setTimeout(() => {
        setLoading(prev => ({ ...prev, [`${containerName}-${action}`]: false }));
      }, 1000);
    }
  };


  const handleViewLogs = (containerName) => {
    setSelectedContainer(containerName);
    setLogsViewerOpen(true);
  };

  const handleViewDetails = (service) => {
    setSelectedService(service);
    setDetailsModalOpen(true);
  };

  // Group services by category
  const coreServices = services.filter(s => s.category === 'core');
  const extensionServices = services.filter(s => s.category === 'extension');

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Service Management
          </h1>
          <div className="flex items-center gap-4 mt-2 text-sm">
            <span className="text-gray-600 dark:text-gray-400">
              {services.length} Total Services
            </span>
            <span className="text-green-600 dark:text-green-400">
              {services.filter(s => isRunning(s.status)).length} Running
            </span>
            <div className="flex items-center gap-1">
              <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`}></div>
              <span className="text-gray-600 dark:text-gray-400">
                {wsConnected ? 'Live Updates' : 'Disconnected'}
              </span>
            </div>
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-gray-100 dark:bg-gray-700 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
          >
            <ArrowPathIcon className="h-5 w-5" />
          </button>
        </div>
      </div>

      {/* Core Services Section */}
      {coreServices.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-4">
            Core Services
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {coreServices.map((service, index) => (
              <ServiceCard
                key={service.container_name || service.name}
                service={service}
                index={index}
                loading={loading}
                onAction={handleServiceAction}
                onViewLogs={handleViewLogs}
                onViewDetails={handleViewDetails}
                serviceUrls={serviceUrls}
              />
            ))}
          </div>
        </div>
      )}

      {/* Extension Services Section */}
      {extensionServices.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold text-gray-800 dark:text-gray-200 mb-4">
            Extension Services
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {extensionServices.map((service, index) => (
              <ServiceCard
                key={service.container_name || service.name}
                service={service}
                index={index + coreServices.length}
                loading={loading}
                onAction={handleServiceAction}
                onViewLogs={handleViewLogs}
                onViewDetails={handleViewDetails}
                serviceUrls={serviceUrls}
              />
            ))}
          </div>
        </div>
      )}

      {/* Empty State */}
      {services.length === 0 && (
        <div className="text-center py-12 text-gray-500 dark:text-gray-400">
          <ServerIcon className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No services found</p>
          <p className="text-sm mt-2">Check your Docker connection</p>
        </div>
      )}

      {/* Modals */}
      <LogsViewer 
        containerName={selectedContainer}
        isOpen={logsViewerOpen}
        onClose={() => {
          setLogsViewerOpen(false);
          setSelectedContainer(null);
        }}
      />
      
      <ServiceDetailsModal
        service={selectedService}
        isOpen={detailsModalOpen}
        onClose={() => {
          setDetailsModalOpen(false);
          setSelectedService(null);
        }}
        onViewLogs={handleViewLogs}
      />
    </div>
  );
}

function ServiceCard({ service, index, loading, onAction, onViewLogs, onViewDetails, serviceUrls }) {
  const statusConfig = getStatusConfig(service.status);
  const StatusIcon = statusConfig.icon;
  const serviceUrl = serviceUrls[service.name];
  const containerName = service.container_name || service.name;
  const isServiceRunning = service.status === 'healthy' || service.status === 'running';

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: index * 0.05 }}
      className={`relative bg-white dark:bg-gray-800 rounded-xl shadow-sm border ${statusConfig.border} p-6 hover:shadow-md transition-shadow`}
    >
      {/* Status Indicator */}
      <div className="absolute top-4 right-4">
        <div className={`flex items-center gap-2 px-2 py-1 rounded-full ${statusConfig.bg}`}>
          <StatusIcon className={`h-4 w-4 ${statusConfig.color} ${statusConfig.pulse ? 'animate-pulse' : ''}`} />
          <span className={`text-xs font-medium ${statusConfig.color}`}>
            {statusConfig.label}
          </span>
        </div>
      </div>

      {/* Service Icon and Name */}
      <div className="mb-4">
        <div className="h-12 w-12 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center mb-3">
          {service.gpu_enabled ? (
            <CpuChipSolid className="h-6 w-6 text-white" />
          ) : (
            <ServerIcon className="h-6 w-6 text-white" />
          )}
        </div>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
          {service.display_name}
        </h3>
        {service.extension && (
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Extension: {service.extension}
          </p>
        )}
      </div>

      {/* Metrics */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1">
            <CpuChipIcon className="h-4 w-4" />
            CPU
          </span>
          <span className="font-medium text-gray-900 dark:text-white">
            {service.cpu_percent ? `${service.cpu_percent.toFixed(1)}%` : '0%'}
          </span>
        </div>
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1">
            <CircleStackIcon className="h-4 w-4" />
            RAM
          </span>
          <span className="font-medium text-gray-900 dark:text-white">
            {formatMemory(service.memory_mb)}
          </span>
        </div>
        {service.port && (
          <div className="flex items-center justify-between text-sm">
            <span className="text-gray-500 dark:text-gray-400 flex items-center gap-1">
              <GlobeAltIcon className="h-4 w-4" />
              Port
            </span>
            <span className="font-medium text-gray-900 dark:text-white">
              {service.port}
            </span>
          </div>
        )}
      </div>

      {/* Action Buttons */}
      <div className="grid grid-cols-3 gap-2">
        {!isServiceRunning ? (
          <button
            onClick={() => onAction(containerName, 'start')}
            disabled={loading[`${containerName}-start`]}
            className="flex items-center justify-center gap-1 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
          >
            {loading[`${containerName}-start`] ? (
              <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
            ) : (
              <>
                <PlayIcon className="h-4 w-4" />
                Start
              </>
            )}
          </button>
        ) : (
          <button
            onClick={() => onAction(containerName, 'stop')}
            disabled={loading[`${containerName}-stop`]}
            className="flex items-center justify-center gap-1 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
          >
            {loading[`${containerName}-stop`] ? (
              <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
            ) : (
              <>
                <StopIcon className="h-4 w-4" />
                Stop
              </>
            )}
          </button>
        )}
        
        <button
          onClick={() => onAction(containerName, 'restart')}
          disabled={loading[`${containerName}-restart`] || !isServiceRunning}
          className="flex items-center justify-center gap-1 px-3 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm font-medium"
        >
          {loading[`${containerName}-restart`] ? (
            <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent" />
          ) : (
            <>
              <ArrowPathIcon className="h-4 w-4" />
              Restart
            </>
          )}
        </button>

        {serviceUrl && isServiceRunning && (
          <a
            href={serviceUrl.replace('localhost', window.location.hostname)}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center gap-1 px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium"
          >
            <GlobeAltIcon className="h-4 w-4" />
            Open
          </a>
        )}
      </div>

      {/* Additional Actions */}
      <div className="mt-3 pt-3 border-t dark:border-gray-700 flex gap-2">
        <button
          onClick={() => onViewLogs(containerName)}
          className="flex-1 flex items-center justify-center gap-1 px-2 py-1.5 text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        >
          <DocumentTextIcon className="h-3.5 w-3.5" />
          Logs
        </button>
        <button
          onClick={() => onViewDetails(service)}
          className="flex-1 flex items-center justify-center gap-1 px-2 py-1.5 text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
        >
          <InformationCircleIcon className="h-3.5 w-3.5" />
          Details
        </button>
      </div>
    </motion.div>
  );
}