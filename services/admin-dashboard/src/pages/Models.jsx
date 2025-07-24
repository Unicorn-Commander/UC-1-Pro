import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  MagnifyingGlassIcon, 
  CloudArrowDownIcon,
  TrashIcon,
  PlayIcon,
  CheckCircleIcon,
  XCircleIcon
} from '@heroicons/react/24/outline';
import { useSystem } from '../contexts/SystemContext';

export default function Models() {
  const { models } = useSystem();
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [downloading, setDownloading] = useState({});

  const searchModels = async () => {
    if (!searchQuery.trim()) return;
    
    setSearching(true);
    try {
      const response = await fetch(`/api/v1/models/search?q=${encodeURIComponent(searchQuery)}`);
      if (!response.ok) throw new Error('Search failed');
      const data = await response.json();
      setSearchResults(data);
    } catch (error) {
      console.error('Search error:', error);
    } finally {
      setSearching(false);
    }
  };

  const downloadModel = async (modelId) => {
    setDownloading(prev => ({ ...prev, [modelId]: true }));
    try {
      const response = await fetch('/api/v1/models/download', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model_id: modelId }),
      });
      if (!response.ok) throw new Error('Download failed');
      // Progress updates will come through WebSocket
    } catch (error) {
      console.error('Download error:', error);
      setDownloading(prev => ({ ...prev, [modelId]: false }));
    }
  };

  const deleteModel = async (modelId) => {
    if (!confirm('Are you sure you want to delete this model?')) return;
    
    try {
      const response = await fetch(`/api/v1/models/${modelId}`, {
        method: 'DELETE',
      });
      if (!response.ok) throw new Error('Delete failed');
    } catch (error) {
      console.error('Delete error:', error);
    }
  };

  const setActiveModel = async (modelId) => {
    try {
      const response = await fetch('/api/v1/models/active', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model_id: modelId }),
      });
      if (!response.ok) throw new Error('Failed to set active model');
    } catch (error) {
      console.error('Set active model error:', error);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          Model Management
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Manage AI models, download new ones, and configure active models
        </p>
      </div>

      {/* Search Section */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Search Hugging Face Models
        </h2>
        <div className="flex gap-4">
          <div className="flex-1 relative">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && searchModels()}
              placeholder="Search for models... (e.g., llama, mistral, qwen)"
              className="w-full px-4 py-2 pl-10 border rounded-lg dark:bg-gray-700 dark:border-gray-600 dark:text-white"
            />
            <MagnifyingGlassIcon className="absolute left-3 top-2.5 h-5 w-5 text-gray-400" />
          </div>
          <button
            onClick={searchModels}
            disabled={searching}
            className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50"
          >
            {searching ? 'Searching...' : 'Search'}
          </button>
        </div>

        {/* Search Results */}
        {searchResults.length > 0 && (
          <div className="mt-6 space-y-4">
            <h3 className="font-medium text-gray-900 dark:text-white">Search Results</h3>
            {searchResults.map((model) => (
              <motion.div
                key={model.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="border dark:border-gray-700 rounded-lg p-4"
              >
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900 dark:text-white">{model.id}</h4>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      {model.description || 'No description available'}
                    </p>
                    <div className="flex gap-4 mt-2 text-sm text-gray-500">
                      <span>Downloads: {model.downloads?.toLocaleString() || 0}</span>
                      <span>Likes: {model.likes || 0}</span>
                      <span>Size: {model.size || 'Unknown'}</span>
                    </div>
                  </div>
                  <button
                    onClick={() => downloadModel(model.id)}
                    disabled={downloading[model.id]}
                    className="ml-4 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center gap-2"
                  >
                    <CloudArrowDownIcon className="h-5 w-5" />
                    {downloading[model.id] ? 'Downloading...' : 'Download'}
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>

      {/* Installed Models */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Installed Models
        </h2>
        <div className="space-y-4">
          {models.map((model) => (
            <motion.div
              key={model.id}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="border dark:border-gray-700 rounded-lg p-4"
            >
              <div className="flex justify-between items-center">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h4 className="font-medium text-gray-900 dark:text-white">{model.name}</h4>
                    {model.active && (
                      <span className="px-2 py-1 bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 text-xs rounded-full">
                        Active
                      </span>
                    )}
                  </div>
                  <div className="flex gap-4 mt-2 text-sm text-gray-500">
                    <span>Type: {model.type}</span>
                    <span>Size: {model.size}</span>
                    <span>Last used: {model.last_used || 'Never'}</span>
                  </div>
                </div>
                <div className="flex gap-2">
                  {!model.active && (
                    <button
                      onClick={() => setActiveModel(model.id)}
                      className="px-3 py-1 bg-primary-600 text-white rounded hover:bg-primary-700"
                    >
                      <PlayIcon className="h-4 w-4" />
                    </button>
                  )}
                  <button
                    onClick={() => deleteModel(model.id)}
                    className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700"
                  >
                    <TrashIcon className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
}