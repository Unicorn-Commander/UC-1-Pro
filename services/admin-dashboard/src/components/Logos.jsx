import React from 'react';

export const ColonelLogo = ({ className = "w-8 h-8" }) => (
  <svg className={className} viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="colonelGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#ffab00" />
        <stop offset="100%" stopColor="#ff6600" />
      </linearGradient>
    </defs>
    <circle cx="50" cy="50" r="45" fill="url(#colonelGradient)" />
    <path d="M50 20C50 20 35 25 35 40C35 55 50 65 50 65C50 65 65 55 65 40C65 25 50 20 50 20Z" fill="white" fillOpacity="0.9"/>
    <circle cx="42" cy="38" r="3" fill="#333" />
    <circle cx="58" cy="38" r="3" fill="#333" />
    <path d="M45 48C45 48 47 52 50 52C53 52 55 48 55 48" stroke="#333" strokeWidth="2" strokeLinecap="round" />
  </svg>
);

export const MagicUnicornLogo = ({ className = "w-6 h-6" }) => (
  <svg className={className} viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="unicornGradient" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stopColor="#b66eff" />
        <stop offset="50%" stopColor="#00d4ff" />
        <stop offset="100%" stopColor="#ff00cc" />
      </linearGradient>
    </defs>
    <path d="M50 10L45 30L30 30L42 40L37 60L50 50L63 60L58 40L70 30L55 30Z" fill="url(#unicornGradient)" />
    <circle cx="50" cy="50" r="5" fill="white" fillOpacity="0.8" />
  </svg>
);