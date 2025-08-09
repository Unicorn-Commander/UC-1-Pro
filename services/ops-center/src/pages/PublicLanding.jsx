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
  SpeakerWaveIcon,
  SunIcon,
  MoonIcon,
  PaintBrushIcon
} from '@heroicons/react/24/outline';
import { ColonelLogo, MagicUnicornLogo } from '../components/Logos';
import { useTheme } from '../contexts/ThemeContext';

export default function PublicLanding() {
  const navigate = useNavigate();
  const searchInputRef = useRef(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentHost, setCurrentHost] = useState('localhost');
  const { theme, currentTheme, switchTheme, availableThemes } = useTheme();
  
  // Theme display configurations
  const themeDisplayNames = {
    dark: { name: 'Professional Dark', icon: MoonIcon },
    light: { name: 'Professional Light', icon: SunIcon },
    unicorn: { name: 'Magic Unicorn', icon: PaintBrushIcon }
  };

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

  // Get theme-specific styling
  const getThemeStyles = () => {
    if (currentTheme === 'unicorn') {
      return {
        background: 'min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900',
        headerText: 'text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400',
        subText: 'text-purple-200/80',
        searchBg: 'bg-white/10 backdrop-blur-xl rounded-2xl shadow-2xl border border-white/20',
        searchInput: 'bg-white/10 border border-white/20 text-white placeholder-purple-300 focus:ring-purple-400',
        searchIcon: 'text-purple-300',
        searchButton: 'bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700',
        cardOverlay: 'bg-white/5 backdrop-blur-xl border border-white/10',
        footerBg: 'bg-black/20 backdrop-blur-sm border-t border-white/10',
        logoText: 'text-purple-200',
        footerText: 'text-purple-300/70'
      };
    } else if (currentTheme === 'light') {
      return {
        background: `min-h-screen ${theme.background}`,
        headerText: `${theme.text.logo}`,
        subText: `${theme.text.secondary}`,
        searchBg: `${theme.card} shadow-xl`,
        searchInput: `bg-gray-50 border border-gray-300 ${theme.text.primary} placeholder-gray-500 focus:ring-blue-500 focus:border-blue-500`,
        searchIcon: 'text-gray-600',
        searchButton: `${theme.button}`,
        cardOverlay: `${theme.card}`,
        footerBg: 'bg-gray-50/95 backdrop-blur-sm border-t border-gray-200',
        logoText: `${theme.text.primary}`,
        footerText: `${theme.text.secondary}`
      };
    } else { // dark theme
      return {
        background: `min-h-screen ${theme.background}`,
        headerText: `${theme.text.logo}`,
        subText: `${theme.text.secondary}`,
        searchBg: `${theme.card} shadow-xl`,
        searchInput: `bg-slate-700/50 border border-slate-600 ${theme.text.primary} placeholder-slate-400 focus:ring-blue-500 focus:border-blue-500`,
        searchIcon: 'text-slate-400',
        searchButton: `${theme.button}`,
        cardOverlay: `${theme.card}`,
        footerBg: 'bg-slate-900/95 backdrop-blur-sm border-t border-slate-700',
        logoText: `${theme.text.primary}`,
        footerText: `${theme.text.secondary}`
      };
    }
  };

  const styles = getThemeStyles();

  return (
    <div className={styles.background}>
      {/* Header */}
      <header className="pt-8 pb-4">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Theme Switcher */}
          <div className="flex justify-end mb-4">
            <div className="flex items-center gap-2">
              {availableThemes.map((themeId) => {
                const ThemeIcon = themeDisplayNames[themeId].icon;
                return (
                  <button
                    key={themeId}
                    onClick={() => switchTheme(themeId)}
                    className={`p-2 rounded-lg transition-all duration-200 ${
                      currentTheme === themeId
                        ? currentTheme === 'unicorn'
                          ? 'bg-purple-600/50 text-yellow-400'
                          : currentTheme === 'light'
                          ? 'bg-blue-100 text-blue-600'
                          : 'bg-slate-700 text-blue-400'
                        : currentTheme === 'unicorn'
                        ? 'bg-white/10 text-purple-300 hover:bg-white/20'
                        : currentTheme === 'light'
                        ? 'bg-white text-gray-600 hover:bg-gray-100'
                        : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
                    }`}
                    title={themeDisplayNames[themeId].name}
                  >
                    <ThemeIcon className="h-5 w-5" />
                  </button>
                );
              })}
            </div>
          </div>
          
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
                  <h1 className={`text-4xl md:text-5xl font-bold ${styles.headerText} ${currentTheme === 'unicorn' ? 'animate-gradient' : ''}`}>
                    Unicorn Commander
                  </h1>
                  <div className={`text-2xl md:text-3xl ${styles.subText} font-bold tracking-widest ${currentTheme === 'unicorn' ? 'sparkle-text' : ''}`}>
                    PRO
                  </div>
                </div>
                <p className={`text-lg ${styles.subText} mt-1`}>
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
        <div className={`${styles.searchBg} p-8 rounded-2xl`}>
          <form onSubmit={handleSearch} className="relative">
            <div className="relative">
              <MagnifyingGlassIcon className={`absolute left-4 top-1/2 transform -translate-y-1/2 h-6 w-6 ${styles.searchIcon}`} />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={handleKeyPress}
                className={`w-full pl-12 pr-16 py-4 text-lg rounded-xl focus:outline-none focus:ring-2 focus:border-transparent transition-all duration-200 ${styles.searchInput}`}
                placeholder="Search the web with Center-Deep..."
              />
              <button
                type="submit"
                className={`absolute right-2 top-1/2 transform -translate-y-1/2 text-white px-6 py-2 rounded-lg transition-all duration-200 flex items-center gap-2 ${styles.searchButton}`}
              >
                <span>Search</span>
                <ArrowRightIcon className="h-4 w-4" />
              </button>
            </div>
          </form>
          <p className={`text-center text-sm mt-3 ${styles.footerText}`}>
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
        <h2 className={`text-3xl font-bold text-center mb-8 ${currentTheme === 'unicorn' ? 'text-white' : theme.text.primary}`}>
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
        <div className={`${styles.cardOverlay} rounded-xl p-6 text-center`}>
          <div className="flex items-center justify-center gap-2 mb-4">
            <CogIcon className={`h-6 w-6 ${currentTheme === 'unicorn' ? 'text-purple-300' : theme.text.accent}`} />
            <h3 className={`text-xl font-semibold ${currentTheme === 'unicorn' ? 'text-white' : theme.text.primary}`}>
              System Administration
            </h3>
          </div>
          
          <p className={`${styles.subText} mb-4`}>
            Access the admin dashboard to manage your UC-1 Pro system
          </p>
          
          <button
            onClick={() => navigate('/admin')}
            className={`px-8 py-3 rounded-lg transition-all duration-200 flex items-center gap-2 mx-auto text-white ${styles.searchButton}`}
          >
            <CpuChipIcon className="h-5 w-5" />
            <span>Admin Dashboard</span>
            <ArrowRightIcon className="h-4 w-4" />
          </button>
        </div>
      </motion.div>

      {/* Footer */}
      <footer className={`${styles.footerBg} py-8 mt-16`}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <MagicUnicornLogo className="w-8 h-8" />
              <div className={styles.logoText}>
                <div className="font-semibold">Magic Unicorn Unconventional Technology & Stuff Inc</div>
                <div className={`text-sm ${styles.footerText}`}>UC-1 Pro v1.0.0</div>
              </div>
            </div>
            
            <div className={`text-right text-sm ${styles.footerText}`}>
              <div>Enterprise AI Infrastructure</div>
              <div>Powered by NVIDIA RTX 5090</div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}