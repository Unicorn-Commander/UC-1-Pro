import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useSystem } from '../contexts/SystemContext';
import SystemMetricsCard from '../components/SystemMetricsCard';
import ServiceStatusCard from '../components/ServiceStatusCard';
import ActivityFeed from '../components/ActivityFeed';
import QuickActions from '../components/QuickActions';
import AlertsBanner from '../components/AlertsBanner';
import PerformanceChart from '../components/PerformanceChart';
import { 
  CpuChipIcon, 
  CircleStackIcon,
  ServerStackIcon,
  SignalIcon,
  ChartBarIcon,
  BoltIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1
    }
  }
};

const itemVariants = {
  hidden: { y: 20, opacity: 0 },
  visible: {
    y: 0,
    opacity: 1,
    transition: {
      duration: 0.5
    }
  }
};

// Core services for quick status overview
const CORE_SERVICES = [
  { id: 'vllm', name: 'AI Model', icon: '🤖', critical: true },
  { id: 'open-webui', name: 'Chat UI', icon: '💬', critical: true },
  { id: 'whisperx', name: 'Speech-to-Text', icon: '🎤', critical: false },
  { id: 'kokoro', name: 'Text-to-Speech', icon: '🗣️', critical: false },
  { id: 'embeddings', name: 'Embeddings', icon: '🧮', critical: false },
  { id: 'searxng', name: 'Search', icon: '🔍', critical: false }
];

export default function Dashboard() {
  const { systemStatus, services, wsConnected, activeModel } = useSystem();
  const [alerts, setAlerts] = useState([]);
  const [performanceData, setPerformanceData] = useState([]);
  const [systemHealth, setSystemHealth] = useState('excellent');
  
  // Calculate system health score
  useEffect(() => {
    if (!systemStatus) return;
    
    let healthScore = 100;
    const criticalServices = services.filter(s => CORE_SERVICES.find(cs => cs.id === s.name && cs.critical));
    const healthyServices = criticalServices.filter(s => s.status === 'healthy');
    
    // Deduct points for service issues
    const serviceHealth = (healthyServices.length / criticalServices.length) * 40;
    
    // Deduct points for resource usage
    const cpuHealth = systemStatus.cpu?.percent > 80 ? 20 : systemStatus.cpu?.percent > 60 ? 10 : 0;
    const memoryHealth = systemStatus.memory?.percent > 85 ? 20 : systemStatus.memory?.percent > 70 ? 10 : 0;
    const gpuHealth = systemStatus.gpu?.[0]?.utilization > 90 ? 15 : systemStatus.gpu?.[0]?.utilization > 75 ? 5 : 0;
    
    healthScore = Math.max(0, healthScore - (40 - serviceHealth) - cpuHealth - memoryHealth - gpuHealth);
    
    if (healthScore >= 90) setSystemHealth('excellent');
    else if (healthScore >= 75) setSystemHealth('good');
    else if (healthScore >= 60) setSystemHealth('warning');
    else setSystemHealth('critical');
    
  }, [systemStatus, services]);
  
  // Update performance data for charts
  useEffect(() => {
    if (!systemStatus) return;
    
    const now = new Date();
    const dataPoint = {
      time: now.toLocaleTimeString(),
      cpu: systemStatus.cpu?.percent || 0,
      memory: systemStatus.memory?.percent || 0,
      gpu: systemStatus.gpu?.[0]?.utilization || 0,
      timestamp: now.getTime()
    };
    
    setPerformanceData(prev => {
      const updated = [...prev, dataPoint];
      // Keep only last 20 data points
      return updated.slice(-20);
    });
  }, [systemStatus]);
  
  // Generate alerts based on system status
  useEffect(() => {
    if (!systemStatus) return;
    
    const newAlerts = [];
    
    // CPU alerts
    if (systemStatus.cpu?.percent > 90) {
      newAlerts.push({
        id: 'cpu-high',
        type: 'error',
        title: 'High CPU Usage',
        message: `CPU usage is at ${systemStatus.cpu.percent}%`,
        timestamp: new Date()
      });
    }
    
    // Memory alerts
    if (systemStatus.memory?.percent > 90) {
      newAlerts.push({
        id: 'memory-high',
        type: 'error',
        title: 'High Memory Usage',
        message: `Memory usage is at ${systemStatus.memory.percent}%`,
        timestamp: new Date()
      });
    }
    
    // GPU alerts
    if (systemStatus.gpu?.[0]?.utilization > 95) {
      newAlerts.push({
        id: 'gpu-high',
        type: 'warning',
        title: 'High GPU Usage',
        message: `GPU utilization is at ${systemStatus.gpu[0].utilization}%`,
        timestamp: new Date()
      });
    }
    
    // Service alerts - only for services that should be running
    const downServices = services.filter(s => 
      s.status !== 'healthy' && 
      s.status !== 'not_created' && // Ignore uninstalled extensions
      s.status !== 'unknown' && // Ignore services with unknown status (Docker not available)
      s.category === 'core' // Focus on core services
    );
    
    // Only show alert if we have services and some are actually down
    if (services.length > 0 && downServices.length > 0) {
      newAlerts.push({
        id: 'services-down',
        type: 'error',
        title: 'Core Services Not Healthy',
        message: `${downServices.length} core service(s) are not running properly`,
        timestamp: new Date()
      });
    }
    
    setAlerts(newAlerts);
  }, [systemStatus, services]);
  
  const healthColor = {
    excellent: 'text-green-600',
    good: 'text-blue-600', 
    warning: 'text-yellow-600',
    critical: 'text-red-600'
  }[systemHealth];
  
  const healthIcon = {
    excellent: CheckCircleIcon,
    good: CheckCircleIcon,
    warning: ExclamationTriangleIcon,
    critical: ExclamationTriangleIcon
  }[systemHealth];
  
  const HealthIcon = healthIcon;
  
  if (!systemStatus) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }
  
  return (
    <motion.div 
      className="space-y-6"
      variants={containerVariants}
      initial="hidden"
      animate="visible"
    >
      {/* Header */}
      <motion.div variants={itemVariants} className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            System Overview
          </h1>
          <div className="flex items-center gap-2 mt-2">
            <HealthIcon className={`h-5 w-5 ${healthColor}`} />
            <span className={`font-medium ${healthColor} capitalize`}>
              System Health: {systemHealth}
            </span>
            <span className="text-gray-500 dark:text-gray-400">•</span>
            <span className="text-gray-600 dark:text-gray-400">
              {wsConnected ? '🟢 Connected' : '🔴 Disconnected'}
            </span>
          </div>
        </div>
        
        <div className="text-right">
          <div className="text-sm text-gray-600 dark:text-gray-400">
            Active Model
          </div>
          <div className="font-medium text-gray-900 dark:text-white">
            {activeModel || 'No model loaded'}
          </div>
        </div>
      </motion.div>
      
      {/* Alerts Banner */}
      {alerts.length > 0 && (
        <motion.div variants={itemVariants}>
          <AlertsBanner alerts={alerts} onDismiss={(id) => 
            setAlerts(prev => prev.filter(alert => alert.id !== id))
          } />
        </motion.div>
      )}
      
      {/* Quick Actions */}
      <motion.div variants={itemVariants}>
        <QuickActions systemStatus={systemStatus} services={services} />
      </motion.div>
      
      {/* System Metrics Row */}
      <motion.div variants={itemVariants} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <SystemMetricsCard
          title="CPU Usage"
          value={`${systemStatus.cpu?.percent || 0}%`}
          icon={CpuChipIcon}
          color={systemStatus.cpu?.percent > 80 ? 'red' : systemStatus.cpu?.percent > 60 ? 'yellow' : 'green'}
          trend={performanceData.length > 1 ? 
            (performanceData[performanceData.length - 1].cpu - performanceData[performanceData.length - 2].cpu) : 0
          }
          details={`${systemStatus.cpu?.cores || 0} cores`}
        />
        
        <SystemMetricsCard
          title="Memory Usage"
          value={`${systemStatus.memory?.percent || 0}%`}
          icon={CircleStackIcon}
          color={systemStatus.memory?.percent > 85 ? 'red' : systemStatus.memory?.percent > 70 ? 'yellow' : 'green'}
          trend={performanceData.length > 1 ? 
            (performanceData[performanceData.length - 1].memory - performanceData[performanceData.length - 2].memory) : 0
          }
          details={`${((systemStatus.memory?.used || 0) / (1024**3)).toFixed(1)}GB / ${((systemStatus.memory?.total || 0) / (1024**3)).toFixed(1)}GB`}
        />
        
        <SystemMetricsCard
          title="GPU Usage"
          value={`${systemStatus.gpu?.[0]?.utilization || 0}%`}
          icon={BoltIcon}
          color={systemStatus.gpu?.[0]?.utilization > 90 ? 'red' : systemStatus.gpu?.[0]?.utilization > 75 ? 'yellow' : 'green'}
          trend={performanceData.length > 1 ? 
            (performanceData[performanceData.length - 1].gpu - performanceData[performanceData.length - 2].gpu) : 0
          }
          details={systemStatus.gpu?.[0]?.name || 'No GPU detected'}
        />
        
        <SystemMetricsCard
          title="Active Services"
          value={`${services.filter(s => s.status === 'healthy' || s.status === 'running').length}/${services.filter(s => s.status !== 'not_created').length}`}
          icon={ServerStackIcon}
          color={services.filter(s => s.category === 'core' && s.status !== 'healthy' && s.status !== 'running' && s.status !== 'not_created').length > 0 ? 'red' : 'green'}
          trend={0}
          details={`${services.filter(s => s.category === 'core' && (s.status === 'healthy' || s.status === 'running')).length} core running`}
        />
      </motion.div>
      
      {/* Performance Chart */}
      <motion.div variants={itemVariants}>
        <PerformanceChart data={performanceData} />
      </motion.div>
      
      {/* Service Status Grid */}
      <motion.div variants={itemVariants}>
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Service Status</h2>
            <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
              <div className="w-2 h-2 bg-green-500 rounded-full"></div>
              <span>Healthy</span>
              <div className="w-2 h-2 bg-yellow-500 rounded-full ml-3"></div>
              <span>Warning</span>
              <div className="w-2 h-2 bg-red-500 rounded-full ml-3"></div>
              <span>Error</span>
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {CORE_SERVICES.map(coreService => {
              const service = services.find(s => s.name === coreService.id);
              return (
                <ServiceStatusCard
                  key={coreService.id}
                  service={{
                    ...coreService,
                    status: service?.status || 'unknown',
                    port: service?.port,
                    description: service?.description
                  }}
                />
              );
            })}
          </div>
        </div>
      </motion.div>
      
      {/* Activity Feed */}
      <motion.div variants={itemVariants}>
        <ActivityFeed alerts={alerts} services={services} />
      </motion.div>
    </motion.div>
  );
}