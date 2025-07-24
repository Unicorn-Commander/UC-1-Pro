import React from 'react';
import { motion } from 'framer-motion';
import ServiceCard from '../components/ServiceCard';
import SystemStatus from '../components/SystemStatus';
import { useSystem } from '../contexts/SystemContext';

// Generate services with dynamic URLs based on current host
const getServices = () => {
  const host = window.location.hostname;
  
  return [
  {
    id: 'open-webui',
    name: 'Chat UI',
    icon: '💬',
    description: 'Main AI chat interface',
    url: `http://${host}:8080',
    port: 8080,
    status: 'healthy'
  },
  {
    id: 'vllm',
    name: 'vLLM API',
    icon: '🤖',
    description: 'Large language model inference',
    url: `http://${host}:8000/docs',
    port: 8000,
    status: 'healthy'
  },
  {
    id: 'searxng',
    name: 'Search',
    icon: '🔍',
    description: 'Private search engine',
    url: `http://${host}:8888',
    port: 8888,
    status: 'healthy'
  },
  {
    id: 'docs',
    name: 'Documentation',
    icon: '📚',
    description: 'System documentation',
    url: `http://${host}:8081',
    port: 8081,
    status: 'healthy'
  },
  {
    id: 'whisperx',
    name: 'WhisperX',
    icon: '🎤',
    description: 'Speech-to-text',
    url: `http://${host}:9000',
    port: 9000,
    status: 'healthy'
  },
  {
    id: 'kokoro',
    name: 'Kokoro TTS',
    icon: '🔊',
    description: 'Text-to-speech',
    url: `http://${host}:8880',
    port: 8880,
    status: 'healthy'
  },
  {
    id: 'embeddings',
    name: 'Embeddings',
    icon: '🔢',
    description: 'Text embeddings',
    url: `http://${host}:8082',
    port: 8082,
    status: 'healthy'
  },
  {
    id: 'reranker',
    name: 'Reranker',
    icon: '📊',
    description: 'Search reranking',
    url: `http://${host}:8083',
    port: 8083,
    status: 'healthy'
  },
  {
    id: 'prometheus',
    name: 'Metrics',
    icon: '📈',
    description: 'System monitoring',
    url: `http://${host}:9090',
    port: 9090,
    status: 'healthy'
  },
  {
    id: 'portainer',
    name: 'Portainer',
    icon: '🐳',
    description: 'Container management',
    url: `http://${host}:9444',
    port: 9444,
    status: 'healthy'
  },
  {
    id: 'gpu-metrics',
    name: 'GPU Monitor',
    icon: '🎮',
    description: 'NVIDIA GPU metrics',
    url: `http://${host}:9835/metrics',
    port: 9835,
    status: 'healthy'
  },
  {
    id: 'tika',
    name: 'Document OCR',
    icon: '📄',
    description: 'Text extraction',
    url: `http://${host}:9998',
    port: 9998,
    status: 'healthy'
  }
  ];
};

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
    opacity: 1
  }
};

export default function Dashboard() {
  const { systemStatus } = useSystem();
  const services = getServices();

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          UC-1 Pro Dashboard
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Manage your AI infrastructure from one place
        </p>
      </div>

      {/* System Status */}
      <SystemStatus />

      {/* Service Cards */}
      <div>
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
          Services
        </h2>
        <motion.div
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
          variants={containerVariants}
          initial="hidden"
          animate="visible"
        >
          {services.map((service) => (
            <motion.div key={service.id} variants={itemVariants}>
              <ServiceCard service={service} />
            </motion.div>
          ))}
        </motion.div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          Quick Actions
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button className="p-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors">
            <span className="text-2xl mb-2 block">🔄</span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Restart All Services</span>
          </button>
          <button className="p-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors">
            <span className="text-2xl mb-2 block">💾</span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Backup System</span>
          </button>
          <button className="p-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors">
            <span className="text-2xl mb-2 block">🔍</span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Check for Updates</span>
          </button>
        </div>
      </div>
    </div>
  );
}