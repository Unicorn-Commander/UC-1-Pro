import React, { createContext, useContext, useState, useEffect } from 'react';

const ThemeContext = createContext();

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
}

// Theme configurations
const themes = {
  unicorn: {
    name: 'Unicorn Commander',
    primary: 'unicorn-purple',
    accent: 'unicorn-gold',
    background: 'from-purple-900 via-blue-900 to-indigo-900',
    card: 'bg-white/10 backdrop-blur-lg border-white/20',
    text: {
      primary: 'text-white',
      secondary: 'text-purple-200',
      accent: 'text-unicorn-gold'
    }
  },
  dark: {
    name: 'Dark',
    primary: 'gray-800',
    accent: 'blue-500',
    background: 'bg-gray-900',
    card: 'bg-gray-800',
    text: {
      primary: 'text-white',
      secondary: 'text-gray-300',
      accent: 'text-blue-400'
    }
  },
  light: {
    name: 'Light',
    primary: 'white',
    accent: 'blue-600',
    background: 'bg-gray-50',
    card: 'bg-white',
    text: {
      primary: 'text-gray-900',
      secondary: 'text-gray-600',
      accent: 'text-blue-600'
    }
  }
};

export function ThemeProvider({ children }) {
  const [currentTheme, setCurrentTheme] = useState('unicorn'); // Default to Unicorn Commander theme
  const [isDarkMode, setIsDarkMode] = useState(true);

  useEffect(() => {
    // Apply theme to document
    const theme = themes[currentTheme];
    
    // For light theme, ensure dark mode is off
    if (currentTheme === 'light') {
      document.documentElement.classList.remove('dark');
    } else {
      document.documentElement.classList.add('dark');
    }
    
    // Store theme preference
    localStorage.setItem('uc1-theme', currentTheme);
  }, [currentTheme]);

  useEffect(() => {
    // Load saved theme
    const savedTheme = localStorage.getItem('uc1-theme');
    const savedDarkMode = localStorage.getItem('uc1-dark-mode');
    
    if (savedTheme && themes[savedTheme]) {
      setCurrentTheme(savedTheme);
    }
    if (savedDarkMode !== null) {
      setIsDarkMode(savedDarkMode === 'true');
    }
  }, []);

  const switchTheme = (themeName) => {
    if (themes[themeName]) {
      setCurrentTheme(themeName);
    }
  };

  const toggleDarkMode = () => {
    setIsDarkMode(!isDarkMode);
  };

  const value = {
    currentTheme,
    theme: themes[currentTheme],
    availableThemes: Object.keys(themes),
    switchTheme,
    isDarkMode,
    toggleDarkMode,
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
}