import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import {
  MagnifyingGlassIcon,
  ChatBubbleLeftRightIcon,
  CodeBracketIcon,
  DocumentTextIcon,
  ChartBarIcon,
  CogIcon,
  ArrowRightIcon,
  GlobeAltIcon,
  CpuChipIcon,
  ServerIcon,
  SpeakerWaveIcon
} from '@heroicons/react/24/outline';
import { ColonelLogo, MagicUnicornLogo } from '../components/Logos';

export default function PublicLanding() {
  const navigate = useNavigate();
  const searchInputRef = useRef(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentHost, setCurrentHost] = useState('localhost');

  useEffect(() => {
    // Auto-focus search input when page loads
    if (searchInputRef.current) {
      searchInputRef.current.focus();
    }
    
    // Get current hostname for service links
    setCurrentHost(window.location.hostname);
  }, []);

  const handleSearch = (e) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      // Open Center-Deep with the search query
      window.open(`http://${currentHost}:8888/search?q=${encodeURIComponent(searchQuery)}`, '_blank');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleSearch(e);
    }
  };

  // Service quick access cards
  const services = [
    {
      title: 'Open-WebUI',
      description: 'Chat with AI models and explore advanced language capabilities',
      icon: ChatBubbleLeftRightIcon,
      url: `http://${currentHost}:8080`,
      color: 'from-blue-500 to-blue-700',
      textColor: 'text-blue-100'
    },
    {
      title: 'Center-Deep Search',
      description: 'Advanced AI-powered search platform with tool servers',
      icon: MagnifyingGlassIcon,
      iconImage: '/Center-Deep.png',
      url: `http://${currentHost}:8888`,
      color: 'from-green-500 to-green-700',
      textColor: 'text-green-100'
    },
    {
      title: 'Bolt.diy',
      description: 'AI-powered development environment for rapid prototyping',
      icon: CodeBracketIcon,
      url: `http://${currentHost}:5173`,
      color: 'from-purple-500 to-purple-700',
      textColor: 'text-purple-100'
    },
    {
      title: 'User Documentation',
      description: 'End-user guides and application documentation',
      icon: DocumentTextIcon,
      url: `http://${currentHost}:8081`,
      color: 'from-orange-500 to-orange-700',
      textColor: 'text-orange-100'
    },
    {
      title: 'Grafana Monitoring',
      description: 'System performance dashboards and real-time metrics',
      icon: ChartBarIcon,
      url: `http://${currentHost}:3000`,
      color: 'from-red-500 to-red-700',
      textColor: 'text-red-100'
    },
    {
      title: 'Portainer',
      description: 'Docker container management and orchestration',
      icon: ServerIcon,
      url: `http://${currentHost}:9444`,
      color: 'from-indigo-500 to-indigo-700',
      textColor: 'text-indigo-100'
    },
    {
      title: 'Unicorn Orator',
      description: 'Professional AI voice synthesis platform with 50+ voice options',
      icon: null,
      iconImage: '/Unicorn_Orator.png',
      url: `http://${currentHost}:8880/web`,
      color: 'from-pink-500 to-pink-700',
      textColor: 'text-pink-100'
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900">
      {/* Header */}
      <header className="pt-8 pb-4">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            {/* Logo and Title - Compact on Desktop */}
            <div className="flex flex-col md:flex-row items-center justify-center gap-4 md:gap-8 mb-4">
              <ColonelLogo className="w-20 h-20 md:w-24 md:h-24 drop-shadow-2xl animate-pulse" />
              <div className="text-center md:text-left">
                <div className="flex flex-col md:flex-row md:items-baseline md:gap-3">
                  <h1 className="text-4xl md:text-5xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 animate-gradient">
                    Unicorn Commander
                  </h1>
                  <div className="text-2xl md:text-3xl text-purple-200 font-bold tracking-widest sparkle-text">
                    PRO
                  </div>
                </div>
                <p className="text-lg text-purple-200/80 mt-1">
                  Your AI Infrastructure Command Center
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </header>

      {/* Search Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 mb-12"
      >
        <div className="bg-white/10 backdrop-blur-xl rounded-2xl shadow-2xl border border-white/20 p-8">
          <form onSubmit={handleSearch} className="relative">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-4 top-1/2 transform -translate-y-1/2 h-6 w-6 text-purple-300" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={handleKeyPress}
                className="w-full pl-12 pr-16 py-4 text-lg bg-white/10 border border-white/20 rounded-xl text-white placeholder-purple-300 focus:outline-none focus:ring-2 focus:ring-purple-400 focus:border-transparent transition-all duration-200"
                placeholder="Search the web with Center-Deep..."
              />
              <button
                type="submit"
                className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-gradient-to-r from-purple-600 to-blue-600 text-white px-6 py-2 rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all duration-200 flex items-center gap-2"
              >
                <span>Search</span>
                <ArrowRightIcon className="h-4 w-4" />
              </button>
            </div>
          </form>
          <p className="text-center text-purple-300/70 text-sm mt-3">
            Powered by Center-Deep • AI-Enhanced • Private • Secure
          </p>
        </div>
      </motion.div>

      {/* Services Grid */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.4 }}
        className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mb-12"
      >
        <h2 className="text-3xl font-bold text-white text-center mb-8">
          Quick Access
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {services.map((service, index) => (
            <motion.div
              key={service.title}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 * index }}
            >
              <a
                href={service.url}
                target="_blank"
                rel="noopener noreferrer"
                className="block group"
              >
                <div className={`bg-gradient-to-br ${service.color} rounded-2xl shadow-xl hover:shadow-2xl transform hover:scale-105 transition-all duration-300 border border-white/10 backdrop-blur-sm overflow-hidden`}>
                  <div className="p-6">
                    <div className="flex items-center gap-4 mb-4">
                      <div className="flex-shrink-0">
                        {service.iconImage ? (
                          <img src={service.iconImage} alt={service.title} className="h-16 w-16 object-contain rounded-lg bg-white/10 p-2" />
                        ) : (
                          <div className="h-16 w-16 rounded-lg bg-white/10 flex items-center justify-center">
                            <service.icon className="h-10 w-10 text-white" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1">
                        <h3 className="text-xl font-bold text-white flex items-center gap-2">
                          {service.title}
                          <ArrowRightIcon className="h-4 w-4 text-white/70 group-hover:text-white group-hover:translate-x-1 transition-all duration-200" />
                        </h3>
                        <p className={`${service.textColor} text-sm mt-1 leading-relaxed`}>
                          {service.description}
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </a>
            </motion.div>
          ))}
        </div>
      </motion.div>

      {/* Admin Access */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.6 }}
        className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 mb-8"
      >
        <div className="bg-white/5 backdrop-blur-xl rounded-xl border border-white/10 p-6 text-center">
          <div className="flex items-center justify-center gap-2 mb-4">
            <CogIcon className="h-6 w-6 text-purple-300" />
            <h3 className="text-xl font-semibold text-white">System Administration</h3>
          </div>
          
          <p className="text-purple-200/80 mb-4">
            Access the admin dashboard to manage your UC-1 Pro system
          </p>
          
          <button
            onClick={() => navigate('/admin')}
            className="bg-gradient-to-r from-purple-600 to-blue-600 text-white px-8 py-3 rounded-lg hover:from-purple-700 hover:to-blue-700 transition-all duration-200 flex items-center gap-2 mx-auto"
          >
            <CpuChipIcon className="h-5 w-5" />
            <span>Admin Dashboard</span>
            <ArrowRightIcon className="h-4 w-4" />
          </button>
        </div>
      </motion.div>

      {/* Footer */}
      <footer className="bg-black/20 backdrop-blur-sm border-t border-white/10 py-8 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <MagicUnicornLogo className="w-8 h-8" />
              <div className="text-purple-200">
                <div className="font-semibold">Magic Unicorn Unconventional Technology & Stuff Inc</div>
                <div className="text-sm text-purple-300/70">UC-1 Pro v1.0.0</div>
              </div>
            </div>
            
            <div className="text-right text-purple-300/70 text-sm">
              <div>Enterprise AI Infrastructure</div>
              <div>Powered by NVIDIA RTX 5090</div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}