import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  HomeIcon, 
  CubeIcon, 
  CogIcon,
  ServerIcon,
  ChartBarIcon,
  WifiIcon,
  SunIcon,
  MoonIcon
} from '@heroicons/react/24/outline';
import { useTheme } from '../contexts/ThemeContext';
import { ColonelLogo, MagicUnicornLogo } from './Logos';

const navigation = [
  { name: 'Dashboard', href: '/', icon: HomeIcon },
  { name: 'Models', href: '/models', icon: CubeIcon },
  { name: 'Services', href: '/services', icon: ServerIcon },
  { name: 'System', href: '/system', icon: ChartBarIcon },
  { name: 'Network', href: '/network', icon: WifiIcon },
  { name: 'Settings', href: '/settings', icon: CogIcon },
];

export default function Layout({ children }) {
  const location = useLocation();
  const { theme, currentTheme, switchTheme, availableThemes, isDarkMode, toggleDarkMode } = useTheme();

  const getThemeClasses = () => {
    if (currentTheme === 'unicorn') {
      return {
        background: 'min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900',
        sidebar: 'bg-black/20 backdrop-blur-xl border-r border-white/10',
        nav: 'hover:bg-white/10'
      };
    }
    return {
      background: 'min-h-screen bg-gray-50 dark:bg-gray-900',
      sidebar: 'bg-white dark:bg-gray-800 border-r dark:border-gray-700',
      nav: 'hover:bg-gray-50 dark:hover:bg-gray-700'
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
              {/* Magic Unicorn presents... */}
              <div className="flex items-center gap-1 text-xs text-purple-300/70 mb-1 font-light">
                <MagicUnicornLogo className="w-4 h-4" />
                <span>Magic Unicorn presents...</span>
              </div>
              
              {/* Main Logo Area */}
              <div className="flex items-center gap-3 mb-2">
                {/* Colonel Logo */}
                <ColonelLogo className="w-10 h-10 drop-shadow-lg" />
                <div className="text-center">
                  <h1 className="text-xl font-bold text-white leading-tight">
                    Unicorn Commander
                  </h1>
                  <div className="text-sm text-purple-200/80 font-medium">
                    Pro
                  </div>
                </div>
              </div>
              
              {/* Version */}
              <div className="text-xs text-purple-300/60 font-mono">
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
                            : 'bg-primary-100 dark:bg-primary-900 text-primary-900 dark:text-primary-100'
                          : currentTheme === 'unicorn'
                            ? 'text-purple-200 hover:bg-white/10 hover:text-white'
                            : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                        }
                      `}
                    >
                      <item.icon
                        className={`
                          mr-3 flex-shrink-0 h-5 w-5
                          ${isActive
                            ? currentTheme === 'unicorn'
                              ? 'text-yellow-400'
                              : 'text-primary-600 dark:text-primary-400'
                            : currentTheme === 'unicorn'
                              ? 'text-purple-300 group-hover:text-yellow-300'
                              : 'text-gray-400 group-hover:text-gray-500 dark:group-hover:text-gray-300'
                          }
                        `}
                        aria-hidden="true"
                      />
                      {item.name}
                    </Link>
                  );
                })}
              </nav>
              
              {/* Theme Switcher */}
              <div className="px-2 pb-4">
                <div className="border-t border-white/10 pt-4">
                  <div className="text-xs text-purple-300/70 mb-2 px-2">Theme</div>
                  <div className="flex gap-1">
                    {availableThemes.map((themeName) => (
                      <button
                        key={themeName}
                        onClick={() => switchTheme(themeName)}
                        className={`
                          px-2 py-1 text-xs rounded transition-all
                          ${currentTheme === themeName
                            ? 'bg-white/20 text-white'
                            : 'text-purple-300/70 hover:bg-white/10 hover:text-white'
                          }
                        `}
                        title={`Switch to ${themeName} theme`}
                      >
                        {themeName === 'unicorn' ? '🦄' : themeName === 'dark' ? '🌙' : '☀️'}
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