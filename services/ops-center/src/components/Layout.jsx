import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  HomeIcon, 
  CubeIcon, 
  CogIcon,
  ServerIcon,
  ChartBarIcon,
  WifiIcon,
  SunIcon,
  MoonIcon,
  QuestionMarkCircleIcon,
  ArchiveBoxIcon,
  PuzzlePieceIcon,
  DocumentTextIcon,
  ShieldCheckIcon,
  ArrowRightOnRectangleIcon,
  UserCircleIcon
} from '@heroicons/react/24/outline';
import { useTheme } from '../contexts/ThemeContext';
import { ColonelLogo, MagicUnicornLogo, CenterDeepLogo } from './Logos';

const navigation = [
  { name: 'Dashboard', href: '/admin/', icon: HomeIcon },
  { name: 'Models & AI', href: '/admin/models', icon: CubeIcon },
  { name: 'Services', href: '/admin/services', icon: ServerIcon },
  { name: 'Resources', href: '/admin/system', icon: ChartBarIcon },
  { name: 'Network', href: '/admin/network', icon: WifiIcon },
  { name: 'Storage', href: '/admin/storage', icon: ArchiveBoxIcon },
  { name: 'Logs', href: '/admin/logs', icon: DocumentTextIcon },
  { name: 'Security', href: '/admin/security', icon: ShieldCheckIcon },
  { name: 'Extensions', href: '/admin/extensions', icon: PuzzlePieceIcon },
  { name: 'Settings', href: '/admin/settings', icon: CogIcon },
];

export default function Layout({ children }) {
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, currentTheme, switchTheme, availableThemes, isDarkMode, toggleDarkMode } = useTheme();
  
  // Theme configurations for display names
  const themes = {
    dark: { name: 'Dark', icon: '🌙' },
    light: { name: 'Light', icon: '☀️' },
    unicorn: { name: 'Unicorn', icon: '🦄' }
  };
  
  const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');
  
  const handleLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userInfo');
    navigate('/login');
  };

  const themeClasses = {
    background: `min-h-screen ${theme.background}`,
    sidebar: theme.sidebar,
    nav: currentTheme === 'unicorn' 
      ? 'hover:bg-white/10'
      : currentTheme === 'light'
      ? 'hover:bg-gray-100'
      : 'hover:bg-slate-700/50',
    logo: theme.text.logo,
    brandText: theme.text.secondary,
    themeLabel: theme.text.secondary
  };

  return (
    <div className={themeClasses.background}>
      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="hidden md:flex md:w-64 md:flex-col">
          <div className={`flex flex-col flex-grow pt-5 pb-4 overflow-y-auto ${themeClasses.sidebar}`}>
            {/* Brand Header */}
            <div className="flex flex-col items-center flex-shrink-0 px-4 mb-8">
              {/* Main Logo Area - Unicorn Commander prominent at top */}
              <div className="flex items-center gap-3 mb-3">
                {/* The Colonel Logo */}
                <ColonelLogo className="w-14 h-14 drop-shadow-xl" />
                <div className="text-center">
                  <h1 className={`text-2xl font-bold ${themeClasses.logo} leading-tight`}>
                    Ops Center
                  </h1>
                  <div className={`text-lg ${currentTheme === 'unicorn' ? 'text-purple-200/80' : currentTheme === 'light' ? 'text-gray-600' : 'text-gray-400'} font-medium`}>
                    UC-1 Pro Control
                  </div>
                </div>
              </div>
              
              {/* System Management - subtitle */}
              <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : currentTheme === 'light' ? 'text-gray-500' : 'text-gray-400'} mb-2 font-medium`}>
                System Management Console
              </div>
              
              {/* Version */}
              <div className={`text-xs ${currentTheme === 'unicorn' ? 'text-purple-300/60' : currentTheme === 'light' ? 'text-gray-500' : 'text-gray-500'} font-mono`}>
                v1.0.0
              </div>
            </div>
            <div className="mt-8 flex flex-col flex-1">
              <nav className="flex-1 px-2 space-y-1">
                {navigation.map((item) => {
                  const isActive = location.pathname === item.href;
                  return (
                    <Link
                      key={item.name}
                      to={item.href}
                      className={`
                        group flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-all duration-200
                        ${isActive
                          ? currentTheme === 'unicorn' 
                            ? 'bg-white/20 text-white shadow-lg backdrop-blur-sm border border-white/20' 
                            : currentTheme === 'light'
                            ? 'bg-blue-100 text-blue-900'
                            : 'bg-blue-900 text-blue-100'
                          : currentTheme === 'unicorn'
                            ? 'text-purple-200 hover:bg-white/10 hover:text-white'
                            : currentTheme === 'light'
                            ? 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                            : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                        }
                      `}
                    >
                      <item.icon
                        className={`
                          mr-3 flex-shrink-0 h-5 w-5
                          ${isActive
                            ? currentTheme === 'unicorn'
                              ? 'text-yellow-400'
                              : currentTheme === 'light'
                              ? 'text-blue-600'
                              : 'text-blue-400'
                            : currentTheme === 'unicorn'
                              ? 'text-purple-300 group-hover:text-yellow-300'
                              : currentTheme === 'light'
                              ? 'text-gray-400 group-hover:text-gray-600'
                              : 'text-gray-400 group-hover:text-gray-300'
                          }
                        `}
                        aria-hidden="true"
                      />
                      {item.name}
                    </Link>
                  );
                })}
              </nav>
              
              {/* Help Button */}
              <div className="px-2 mb-4">
                <button
                  onClick={() => {
                    const currentHost = window.location.hostname;
                    window.open(`http://${currentHost}:8086`, '_blank');
                  }}
                  className={`w-full flex items-center gap-2 px-3 py-2 text-sm font-medium rounded-lg transition-all duration-200 ${
                    currentTheme === 'unicorn'
                      ? 'text-purple-200 hover:bg-white/10 hover:text-white'
                      : currentTheme === 'light'
                      ? 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                      : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  }`}
                >
                  <QuestionMarkCircleIcon className="h-5 w-5" />
                  Help & Documentation
                </button>
              </div>
              
              {/* User Info and Logout */}
              <div className="px-2 mb-4">
                <div className="border-t border-white/10 pt-4">
                  {userInfo.username && (
                    <div className={`flex items-center gap-2 px-2 mb-3 text-sm ${
                      currentTheme === 'unicorn' ? 'text-purple-200' : currentTheme === 'light' ? 'text-gray-600' : 'text-gray-400'
                    }`}>
                      <UserCircleIcon className="h-5 w-5" />
                      <span>{userInfo.username}</span>
                    </div>
                  )}
                  <button
                    onClick={handleLogout}
                    className={`w-full flex items-center gap-2 px-3 py-2 text-sm font-medium rounded-lg transition-all duration-200 ${
                      currentTheme === 'unicorn'
                        ? 'text-red-300 hover:bg-red-900/20 hover:text-red-200'
                        : currentTheme === 'light'
                        ? 'text-red-600 hover:bg-red-50 hover:text-red-700'
                        : 'text-red-400 hover:bg-red-900/20 hover:text-red-300'
                    }`}
                  >
                    <ArrowRightOnRectangleIcon className="h-5 w-5" />
                    Logout
                  </button>
                </div>
              </div>
              
              {/* Theme Switcher */}
              <div className="px-2 pb-4">
                <div className="border-t border-white/10 pt-4">
                  <div className={`text-xs ${themeClasses.themeLabel} mb-2 px-2`}>Theme</div>
                  <div className="flex gap-1">
                    {availableThemes.map((themeName) => (
                      <button
                        key={themeName}
                        onClick={() => switchTheme(themeName)}
                        className={`
                          px-2 py-1 text-xs rounded transition-all
                          ${currentTheme === themeName
                            ? 'bg-white/20 text-white'
                            : currentTheme === 'unicorn' ? 'text-purple-300/70 hover:bg-white/10 hover:text-white' : currentTheme === 'light' ? 'text-gray-600 hover:bg-gray-100' : 'text-gray-400 hover:bg-gray-700'
                          }
                        `}
                        title={`Switch to ${themeName} theme`}
                      >
                        {themes[themeName]?.icon} {themes[themeName]?.name || themeName}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div className="flex flex-col flex-1 overflow-hidden">
          <main className="flex-1 relative overflow-y-auto focus:outline-none">
            <div className="py-6">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
                {children}
              </div>
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}