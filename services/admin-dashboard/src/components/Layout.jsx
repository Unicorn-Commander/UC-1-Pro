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
import { ColonelLogo, MagicUnicornLogo } from './Logos';

const navigation = [
  { name: 'Dashboard', href: '/', icon: HomeIcon },
  { name: 'AI Model Management', href: '/models', icon: CubeIcon },
  { name: 'Services', href: '/services', icon: ServerIcon },
  { name: 'System Monitor', href: '/system', icon: ChartBarIcon },
  { name: 'Network & WiFi', href: '/network', icon: WifiIcon },
  { name: 'Storage & Backup', href: '/storage', icon: ArchiveBoxIcon },
  { name: 'Extensions', href: '/extensions', icon: PuzzlePieceIcon },
  { name: 'Logs & Diagnostics', href: '/logs', icon: DocumentTextIcon },
  { name: 'Security & Access', href: '/security', icon: ShieldCheckIcon },
  { name: 'Settings', href: '/settings', icon: CogIcon },
];

export default function Layout({ children }) {
  const location = useLocation();
  const navigate = useNavigate();
  const { theme, currentTheme, switchTheme, availableThemes, isDarkMode, toggleDarkMode } = useTheme();
  
  const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}');
  
  const handleLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userInfo');
    navigate('/login');
  };

  const getThemeClasses = () => {
    if (currentTheme === 'unicorn') {
      return {
        background: 'min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900',
        sidebar: 'bg-black/20 backdrop-blur-xl border-r border-white/10',
        nav: 'hover:bg-white/10',
        logo: 'text-white',
        brandText: 'text-purple-300/70',
        themeLabel: 'text-purple-300/70'
      };
    } else if (currentTheme === 'light') {
      return {
        background: 'min-h-screen bg-gray-50',
        sidebar: 'bg-white border-r border-gray-200',
        nav: 'hover:bg-gray-100',
        logo: 'text-gray-900',
        brandText: 'text-gray-600',
        themeLabel: 'text-gray-600'
      };
    }
    return {
      background: 'min-h-screen bg-gray-900',
      sidebar: 'bg-gray-800 border-r border-gray-700',
      nav: 'hover:bg-gray-700',
      logo: 'text-white',
      brandText: 'text-gray-400',
      themeLabel: 'text-gray-400'
    };
  };

  const themeClasses = getThemeClasses();

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
                {/* Colonel Logo - Larger */}
                <ColonelLogo className="w-14 h-14 drop-shadow-xl" />
                <div className="text-center">
                  <h1 className={`text-2xl font-bold ${themeClasses.logo} leading-tight`}>
                    Unicorn Commander
                  </h1>
                  <div className={`text-lg ${currentTheme === 'unicorn' ? 'text-purple-200/80' : currentTheme === 'light' ? 'text-gray-600' : 'text-gray-400'} font-medium`}>
                    Pro
                  </div>
                </div>
              </div>
              
              {/* Admin Control Panel - subtitle */}
              <div className={`text-sm ${currentTheme === 'unicorn' ? 'text-purple-200/70' : currentTheme === 'light' ? 'text-gray-500' : 'text-gray-400'} mb-2 font-medium`}>
                Admin Control Panel
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
                        {themeName === 'unicorn' ? '🦄' : themeName === 'dark' ? '🌙' : '☀️'} {themeName}
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