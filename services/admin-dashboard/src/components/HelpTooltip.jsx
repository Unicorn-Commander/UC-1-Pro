import React, { useState } from 'react';
import { QuestionMarkCircleIcon } from '@heroicons/react/24/outline';

export default function HelpTooltip({ title, content, position = 'top' }) {
  const [showTooltip, setShowTooltip] = useState(false);

  const positionClasses = {
    top: 'bottom-full left-1/2 transform -translate-x-1/2 mb-2',
    right: 'left-full top-1/2 transform -translate-y-1/2 ml-2',
    bottom: 'top-full left-1/2 transform -translate-x-1/2 mt-2',
    left: 'right-full top-1/2 transform -translate-y-1/2 mr-2'
  };

  const arrowClasses = {
    top: 'top-full left-1/2 transform -translate-x-1/2 border-t-gray-800 dark:border-t-gray-700',
    right: 'right-full top-1/2 transform -translate-y-1/2 border-r-gray-800 dark:border-r-gray-700',
    bottom: 'bottom-full left-1/2 transform -translate-x-1/2 border-b-gray-800 dark:border-b-gray-700',
    left: 'left-full top-1/2 transform -translate-y-1/2 border-l-gray-800 dark:border-l-gray-700'
  };

  return (
    <div className="relative inline-block">
      <button
        type="button"
        className="ml-1 text-gray-400 hover:text-gray-600 dark:text-gray-500 dark:hover:text-gray-300"
        onMouseEnter={() => setShowTooltip(true)}
        onMouseLeave={() => setShowTooltip(false)}
        onClick={() => setShowTooltip(!showTooltip)}
      >
        <QuestionMarkCircleIcon className="h-4 w-4" />
      </button>
      
      {showTooltip && (
        <div className={`absolute z-50 ${positionClasses[position]} w-64`}>
          <div className="bg-gray-800 dark:bg-gray-700 text-white text-sm rounded-lg shadow-lg p-3">
            {title && (
              <div className="font-semibold mb-1">{title}</div>
            )}
            <div className="text-gray-200">{content}</div>
            <div 
              className={`absolute w-0 h-0 border-8 border-transparent ${arrowClasses[position]}`}
              style={{
                borderStyle: 'solid',
                ...(position === 'top' && { borderTopColor: 'inherit' }),
                ...(position === 'right' && { borderRightColor: 'inherit' }),
                ...(position === 'bottom' && { borderBottomColor: 'inherit' }),
                ...(position === 'left' && { borderLeftColor: 'inherit' }),
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}