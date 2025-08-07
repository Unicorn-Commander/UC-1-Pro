import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  CubeIcon,
  MagnifyingGlassIcon, 
  CloudArrowDownIcon,
  TrashIcon,
  PlayIcon,
  StopIcon,
  CogIcon,
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  CheckCircleIcon,
  XCircleIcon,
  InformationCircleIcon,
  ChartBarIcon,
  DocumentTextIcon,
  AdjustmentsHorizontalIcon,
  ArrowPathIcon,
  FunnelIcon,
  ArrowsUpDownIcon,
  Cog6ToothIcon
} from '@heroicons/react/24/outline';
import { useSystem } from '../contexts/SystemContext';
import ModelSettingsForm from '../components/ModelSettingsForm';
import modelApi from '../services/modelApi';

export default function AIModelManagement() {
  const { systemStatus } = useSystem();
  const [activeTab, setActiveTab] = useState('vllm');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [selectedModel, setSelectedModel] = useState(null);
  const [showSettings, setShowSettings] = useState(false);
  const [showModelSettings, setShowModelSettings] = useState(null); // For per-model settings
  const [showFilters, setShowFilters] = useState(false);
  const [sortBy, setSortBy] = useState('downloads'); // downloads, likes, lastModified
  const [installedModels, setInstalledModels] = useState({ vllm: [], ollama: [] });
  const [loadingModels, setLoadingModels] = useState(true);
  const [filters, setFilters] = useState({
    quantization: '',
    minSize: '',
    maxSize: '',
    license: '',
    task: '',
    language: ''
  });
  
  // Global settings
  const [vllmSettings, setVllmSettings] = useState({
    gpu_memory_utilization: 0.95,
    max_model_len: 16384,
    tensor_parallel_size: 1,
    quantization: 'auto',
    dtype: 'auto',
    trust_remote_code: false,
    download_dir: '/home/ucadmin/UC-1-Pro/volumes/vllm_models',
    cpu_offload_gb: 0,
    enforce_eager: false,
    max_num_batched_tokens: null,
    max_num_seqs: 256,
    disable_log_stats: false,
    disable_log_requests: false
  });
  
  const [ollamaSettings, setOllamaSettings] = useState({
    models_path: '/home/ucadmin/.ollama/models',
    gpu_layers: -1,
    context_size: 2048,
    num_thread: 0,
    use_mmap: true,
    use_mlock: false,
    repeat_penalty: 1.1,
    temperature: 0.8,
    top_k: 40,
    top_p: 0.9,
    seed: -1
  });
  
  // Per-model settings overrides
  const [modelOverrides, setModelOverrides] = useState({});
  const [ollamaModels, setOllamaModels] = useState([]);
  const [downloadProgress, setDownloadProgress] = useState({});

  // Search timer for debouncing
  const [searchTimer, setSearchTimer] = useState(null);

  // Load installed models and settings on mount
  useEffect(() => {
    loadInstalledModels();
    loadGlobalSettings();
  }, []);

  // Reload models when tab changes
  useEffect(() => {
    loadInstalledModels();
  }, [activeTab]);

  const loadInstalledModels = async () => {
    setLoadingModels(true);
    try {
      const models = await modelApi.getInstalledModels();
      setInstalledModels(models);
      
      // Also load any active downloads
      const downloads = await modelApi.getAllDownloads();
      // Update download progress state
      const progressMap = {};
      Object.entries(downloads).forEach(([taskId, task]) => {
        if (task.status === 'downloading') {
          progressMap[task.model_id] = task.progress;
        }
      });
      setDownloadProgress(progressMap);
    } catch (error) {
      console.error('Failed to load models:', error);
    } finally {
      setLoadingModels(false);
    }
  };

  const loadGlobalSettings = async () => {
    try {
      const [vllm, ollama] = await Promise.all([
        modelApi.getGlobalSettings('vllm'),
        modelApi.getGlobalSettings('ollama')
      ]);
      setVllmSettings(vllm);
      setOllamaSettings(ollama);
    } catch (error) {
      console.error('Failed to load settings:', error);
    }
  };

  // Advanced search from Hugging Face
  useEffect(() => {
    if (searchTimer) {
      clearTimeout(searchTimer);
    }
    
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setSearching(false);
      return;
    }
    
    setSearching(true);
    
    const timer = setTimeout(async () => {
      try {
        // Build search parameters with filters
        let searchUrl = `https://huggingface.co/api/models?search=${encodeURIComponent(searchQuery)}`;
        
        // Add model type filter based on tab
        if (activeTab === 'vllm') {
          searchUrl += '&filter=text-generation';
        }
        
        // Add additional filters
        if (filters.task) {
          searchUrl += `&pipeline_tag=${filters.task}`;
        }
        if (filters.language) {
          searchUrl += `&language=${filters.language}`;
        }
        if (filters.license) {
          searchUrl += `&license=${filters.license}`;
        }
        
        searchUrl += '&limit=50'; // Get more results for filtering
        
        const response = await fetch(searchUrl);
        
        if (response.ok) {
          let data = await response.json();
          
          // Apply client-side filters
          data = data.filter(model => {
            // Quantization filter
            if (filters.quantization) {
              const hasQuantization = model.tags?.some(tag => 
                tag.toLowerCase().includes(filters.quantization.toLowerCase())
              );
              if (!hasQuantization) return false;
            }
            
            // Size filters (if available in metadata)
            // This is approximate based on model name patterns
            if (filters.minSize || filters.maxSize) {
              const sizeMatch = model.modelId.match(/(\d+)B/i);
              if (sizeMatch) {
                const size = parseInt(sizeMatch[1]);
                if (filters.minSize && size < parseInt(filters.minSize)) return false;
                if (filters.maxSize && size > parseInt(filters.maxSize)) return false;
              }
            }
            
            return true;
          });
          
          // Sort results
          data.sort((a, b) => {
            switch (sortBy) {
              case 'downloads':
                return (b.downloads || 0) - (a.downloads || 0);
              case 'likes':
                return (b.likes || 0) - (a.likes || 0);
              case 'lastModified':
                return new Date(b.lastModified || 0) - new Date(a.lastModified || 0);
              default:
                return 0;
            }
          });
          
          setSearchResults(data);
        }
      } catch (error) {
        console.error('Search error:', error);
        setSearchResults([]);
      } finally {
        setSearching(false);
      }
    }, 300);
    
    setSearchTimer(timer);
    
    return () => {
      if (timer) clearTimeout(timer);
    };
  }, [searchQuery, activeTab, filters, sortBy]);

  const downloadVllmModel = async (modelId) => {
    try {
      const result = await modelApi.downloadModel(modelId, 'vllm', vllmSettings);
      
      // Monitor download progress
      if (result.task_id) {
        monitorDownloadProgress(result.task_id, modelId);
      }
    } catch (error) {
      console.error('Download error:', error);
      alert(`Failed to start download: ${error.message}`);
    }
  };

  const downloadOllamaModel = async (modelName) => {
    try {
      const result = await modelApi.downloadModel(modelName, 'ollama');
      
      // Monitor download progress
      if (result.task_id) {
        monitorDownloadProgress(result.task_id, modelName);
      }
    } catch (error) {
      console.error('Ollama download error:', error);
      alert(`Failed to start download: ${error.message}`);
    }
  };

  const monitorDownloadProgress = async (taskId, modelId) => {
    try {
      await modelApi.monitorDownload(taskId, (status) => {
        setDownloadProgress(prev => ({
          ...prev,
          [modelId]: status.progress || 0
        }));
        
        if (status.status === 'completed') {
          // Reload models after successful download
          loadInstalledModels();
          // Clear download progress after a delay
          setTimeout(() => {
            setDownloadProgress(prev => {
              const newProgress = { ...prev };
              delete newProgress[modelId];
              return newProgress;
            });
          }, 2000);
        }
      });
    } catch (error) {
      console.error('Error monitoring download:', error);
      setDownloadProgress(prev => {
        const newProgress = { ...prev };
        delete newProgress[modelId];
        return newProgress;
      });
    }
  };

  const formatBytes = (bytes) => {
    if (!bytes) return 'Unknown';
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
  };

  const formatModelSize = (model) => {
    if (activeTab === 'ollama') {
      return formatBytes(model.size);
    }
    // For Hugging Face models, estimate size
    return model.safetensors ? 'Safetensors' : 'Unknown';
  };

  // Save model-specific settings
  const saveModelSettings = async (modelId, settings) => {
    try {
      await modelApi.updateModelSettings(modelId, activeTab, settings);
      
      // Update local state
      setModelOverrides(prev => ({
        ...prev,
        [modelId]: settings
      }));
      setShowModelSettings(null);
      
      // Reload models to get updated override status
      loadInstalledModels();
    } catch (error) {
      console.error('Failed to save model settings:', error);
      alert(`Failed to save settings: ${error.message}`);
    }
  };

  // Get effective settings for a model (global + overrides)
  const getEffectiveSettings = (modelId) => {
    const globalSettings = activeTab === 'vllm' ? vllmSettings : ollamaSettings;
    const overrides = modelOverrides[modelId] || {};
    return { ...globalSettings, ...overrides };
  };

  // Activate a model
  const activateModel = async (backend, modelId) => {
    try {
      const result = await modelApi.activateModel(backend, modelId);
      alert(`Model activated: ${result.message || 'Success'}`);
      loadInstalledModels();
    } catch (error) {
      console.error('Failed to activate model:', error);
      alert(`Failed to activate model: ${error.message}`);
    }
  };

  // Delete a model
  const deleteModel = async (backend, modelId) => {
    if (!confirm(`Are you sure you want to delete this model?\n\n${modelId}`)) {
      return;
    }
    
    try {
      await modelApi.deleteModel(backend, modelId);
      alert('Model deleted successfully');
      loadInstalledModels();
    } catch (error) {
      console.error('Failed to delete model:', error);
      alert(`Failed to delete model: ${error.message}`);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
          AI Model Management
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          Manage models for vLLM and Ollama inference engines with granular control
        </p>
      </div>

      {/* Tab Navigation */}
      <div className="border-b dark:border-gray-700">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('vllm')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'vllm'
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <CubeIcon className="h-5 w-5" />
              vLLM Models
            </div>
          </button>
          <button
            onClick={() => setActiveTab('ollama')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'ollama'
                ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            <div className="flex items-center gap-2">
              <CubeIcon className="h-5 w-5" />
              Ollama Models
            </div>
          </button>
        </nav>
      </div>

      {/* Settings Button */}
      <div className="flex justify-end">
        <button
          onClick={() => setShowSettings(!showSettings)}
          className="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 flex items-center gap-2"
        >
          <AdjustmentsHorizontalIcon className="h-5 w-5" />
          Global {activeTab === 'vllm' ? 'vLLM' : 'Ollama'} Settings
        </button>
      </div>

      {/* Global Settings Panel */}
      {showSettings && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          className="bg-white dark:bg-gray-800 rounded-lg shadow p-6"
        >
          <h3 className="text-lg font-semibold mb-4">
            Global {activeTab === 'vllm' ? 'vLLM' : 'Ollama'} Settings
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
            These settings apply to all models unless overridden by model-specific settings.
          </p>
          
          {activeTab === 'vllm' ? (
            <div className="grid grid-cols-2 gap-6">
              <div>
                <h3 className="text-lg font-semibold mb-4">GPU Settings</h3>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      GPU Memory Utilization
                    </label>
                    <input
                      type="range"
                      min="0.1"
                      max="1.0"
                      step="0.05"
                      value={vllmSettings.gpu_memory_utilization}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        gpu_memory_utilization: parseFloat(e.target.value)
                      })}
                      className="w-full"
                    />
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                      {(vllmSettings.gpu_memory_utilization * 100).toFixed(0)}%
                    </span>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Tensor Parallel Size
                    </label>
                    <select
                      value={vllmSettings.tensor_parallel_size}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        tensor_parallel_size: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    >
                      <option value={1}>1 (Single GPU)</option>
                      <option value={2}>2 GPUs</option>
                      <option value={4}>4 GPUs</option>
                      <option value={8}>8 GPUs</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      CPU Offload (GB)
                    </label>
                    <input
                      type="number"
                      min="0"
                      max="64"
                      value={vllmSettings.cpu_offload_gb}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        cpu_offload_gb: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-lg font-semibold mb-4">Model Settings</h3>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Max Model Length
                    </label>
                    <select
                      value={vllmSettings.max_model_len}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        max_model_len: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    >
                      <option value={2048}>2K</option>
                      <option value={4096}>4K</option>
                      <option value={8192}>8K</option>
                      <option value={16384}>16K</option>
                      <option value={32768}>32K</option>
                      <option value={65536}>64K</option>
                      <option value={131072}>128K</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Quantization
                    </label>
                    <select
                      value={vllmSettings.quantization}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        quantization: e.target.value
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    >
                      <option value="auto">Auto-detect</option>
                      <option value="awq">AWQ</option>
                      <option value="gptq">GPTQ</option>
                      <option value="squeezellm">SqueezeLLM</option>
                      <option value="fp8">FP8</option>
                      <option value="none">None (FP16)</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Data Type
                    </label>
                    <select
                      value={vllmSettings.dtype}
                      onChange={(e) => setVllmSettings({
                        ...vllmSettings,
                        dtype: e.target.value
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    >
                      <option value="auto">Auto</option>
                      <option value="half">FP16</option>
                      <option value="float16">float16</option>
                      <option value="bfloat16">bfloat16</option>
                      <option value="float">FP32</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="col-span-2">
                <h3 className="text-lg font-semibold mb-4">Advanced Settings</h3>
                
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={vllmSettings.trust_remote_code}
                        onChange={(e) => setVllmSettings({
                          ...vllmSettings,
                          trust_remote_code: e.target.checked
                        })}
                        className="rounded"
                      />
                      <span className="text-sm">Trust Remote Code</span>
                    </label>
                  </div>

                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={vllmSettings.enforce_eager}
                        onChange={(e) => setVllmSettings({
                          ...vllmSettings,
                          enforce_eager: e.target.checked
                        })}
                        className="rounded"
                      />
                      <span className="text-sm">Enforce Eager Mode</span>
                    </label>
                  </div>

                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={vllmSettings.disable_log_stats}
                        onChange={(e) => setVllmSettings({
                          ...vllmSettings,
                          disable_log_stats: e.target.checked
                        })}
                        className="rounded"
                      />
                      <span className="text-sm">Disable Log Stats</span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-6">
              <div>
                <h3 className="text-lg font-semibold mb-4">Performance Settings</h3>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      GPU Layers
                    </label>
                    <input
                      type="number"
                      min="-1"
                      value={ollamaSettings.gpu_layers}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        gpu_layers: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                    <span className="text-xs text-gray-500">-1 = use all layers</span>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Context Size
                    </label>
                    <select
                      value={ollamaSettings.context_size}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        context_size: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    >
                      <option value={512}>512</option>
                      <option value={1024}>1024</option>
                      <option value={2048}>2048</option>
                      <option value={4096}>4096</option>
                      <option value={8192}>8192</option>
                      <option value={16384}>16384</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      CPU Threads
                    </label>
                    <input
                      type="number"
                      min="0"
                      value={ollamaSettings.num_thread}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        num_thread: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                    <span className="text-xs text-gray-500">0 = auto-detect</span>
                  </div>
                </div>
              </div>

              <div>
                <h3 className="text-lg font-semibold mb-4">Generation Settings</h3>
                
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Temperature ({ollamaSettings.temperature})
                    </label>
                    <input
                      type="range"
                      min="0"
                      max="2"
                      step="0.1"
                      value={ollamaSettings.temperature}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        temperature: parseFloat(e.target.value)
                      })}
                      className="w-full"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Top K
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={ollamaSettings.top_k}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        top_k: parseInt(e.target.value)
                      })}
                      className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium mb-2">
                      Top P ({ollamaSettings.top_p})
                    </label>
                    <input
                      type="range"
                      min="0"
                      max="1"
                      step="0.05"
                      value={ollamaSettings.top_p}
                      onChange={(e) => setOllamaSettings({
                        ...ollamaSettings,
                        top_p: parseFloat(e.target.value)
                      })}
                      className="w-full"
                    />
                  </div>
                </div>
              </div>

              <div className="col-span-2">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={ollamaSettings.use_mmap}
                        onChange={(e) => setOllamaSettings({
                          ...ollamaSettings,
                          use_mmap: e.target.checked
                        })}
                        className="rounded"
                      />
                      <span className="text-sm">Use Memory Mapping</span>
                    </label>
                  </div>

                  <div>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={ollamaSettings.use_mlock}
                        onChange={(e) => setOllamaSettings({
                          ...ollamaSettings,
                          use_mlock: e.target.checked
                        })}
                        className="rounded"
                      />
                      <span className="text-sm">Lock Model in RAM</span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          )}

          <div className="mt-6 flex justify-end gap-2">
            <button
              onClick={() => setShowSettings(false)}
              className="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600"
            >
              Cancel
            </button>
            <button
              onClick={async () => {
                try {
                  await modelApi.updateGlobalSettings(
                    activeTab, 
                    activeTab === 'vllm' ? vllmSettings : ollamaSettings
                  );
                  alert('Global settings saved successfully');
                  setShowSettings(false);
                } catch (error) {
                  console.error('Failed to save settings:', error);
                  alert(`Failed to save settings: ${error.message}`);
                }
              }}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Save Global Settings
            </button>
          </div>
        </motion.div>
      )}

      {/* Search Section */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <div className="space-y-4">
          {/* Search Bar and Controls */}
          <div className="flex gap-2">
            <div className="relative flex-1">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder={`Search Hugging Face for ${activeTab === 'vllm' ? 'vLLM-compatible' : 'Ollama-compatible'} models...`}
                className="w-full px-4 py-2 pl-10 border rounded-lg dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
              <MagnifyingGlassIcon className="absolute left-3 top-2.5 h-5 w-5 text-gray-400" />
            </div>
            
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`px-4 py-2 border rounded-lg flex items-center gap-2 ${
                showFilters ? 'bg-blue-50 border-blue-300 text-blue-700' : 'hover:bg-gray-50'
              }`}
            >
              <FunnelIcon className="h-5 w-5" />
              Filters
            </button>
            
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
            >
              <option value="downloads">Sort by Downloads</option>
              <option value="likes">Sort by Likes</option>
              <option value="lastModified">Sort by Last Modified</option>
            </select>
          </div>

          {/* Filters Panel */}
          {showFilters && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="grid grid-cols-3 gap-4 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg"
            >
              <div>
                <label className="block text-sm font-medium mb-1">Quantization</label>
                <select
                  value={filters.quantization}
                  onChange={(e) => setFilters({ ...filters, quantization: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Any</option>
                  <option value="awq">AWQ</option>
                  <option value="gptq">GPTQ</option>
                  <option value="gguf">GGUF</option>
                  <option value="fp8">FP8</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Model Size (B)</label>
                <div className="flex gap-2">
                  <input
                    type="number"
                    placeholder="Min"
                    value={filters.minSize}
                    onChange={(e) => setFilters({ ...filters, minSize: e.target.value })}
                    className="w-1/2 px-2 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                  />
                  <input
                    type="number"
                    placeholder="Max"
                    value={filters.maxSize}
                    onChange={(e) => setFilters({ ...filters, maxSize: e.target.value })}
                    className="w-1/2 px-2 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">License</label>
                <select
                  value={filters.license}
                  onChange={(e) => setFilters({ ...filters, license: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Any</option>
                  <option value="apache-2.0">Apache 2.0</option>
                  <option value="mit">MIT</option>
                  <option value="cc-by-sa-4.0">CC BY-SA 4.0</option>
                  <option value="other">Other</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Task</label>
                <select
                  value={filters.task}
                  onChange={(e) => setFilters({ ...filters, task: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Any</option>
                  <option value="text-generation">Text Generation</option>
                  <option value="text2text-generation">Text2Text Generation</option>
                  <option value="conversational">Conversational</option>
                  <option value="feature-extraction">Feature Extraction</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium mb-1">Language</label>
                <select
                  value={filters.language}
                  onChange={(e) => setFilters({ ...filters, language: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                >
                  <option value="">Any</option>
                  <option value="en">English</option>
                  <option value="zh">Chinese</option>
                  <option value="es">Spanish</option>
                  <option value="fr">French</option>
                  <option value="multilingual">Multilingual</option>
                </select>
              </div>
              
              <div className="flex items-end">
                <button
                  onClick={() => setFilters({
                    quantization: '',
                    minSize: '',
                    maxSize: '',
                    license: '',
                    task: '',
                    language: ''
                  })}
                  className="w-full px-3 py-2 text-sm bg-gray-600 text-white rounded-lg hover:bg-gray-700"
                >
                  Clear Filters
                </button>
              </div>
            </motion.div>
          )}
        </div>

        {searching && (
          <div className="mt-4 text-center text-gray-500">
            <ArrowPathIcon className="h-6 w-6 animate-spin mx-auto" />
            Searching Hugging Face...
          </div>
        )}

        {/* Search Results */}
        {searchResults.length > 0 && (
          <div className="mt-4 space-y-3 max-h-96 overflow-y-auto">
            {searchResults.map((model) => (
              <div
                key={model.modelId}
                className="border dark:border-gray-700 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer"
                onClick={() => setSelectedModel(model)}
              >
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900 dark:text-white">
                      {model.modelId}
                    </h4>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      {model.author} • {model.downloads?.toLocaleString() || 0} downloads • {model.likes || 0} likes
                    </p>
                    <div className="flex gap-2 mt-2">
                      {model.pipeline_tag && (
                        <span className="inline-block px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 text-xs rounded">
                          {model.pipeline_tag}
                        </span>
                      )}
                      {model.tags?.slice(0, 3).map((tag) => (
                        <span
                          key={tag}
                          className="inline-block px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs rounded"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  </div>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      if (activeTab === 'vllm') {
                        downloadVllmModel(model.modelId);
                      } else {
                        downloadOllamaModel(model.modelId);
                      }
                    }}
                    className="ml-4 px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700"
                  >
                    <CloudArrowDownIcon className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Installed Models */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-white">
          Installed {activeTab === 'vllm' ? 'vLLM' : 'Ollama'} Models
        </h2>

        <div className="space-y-4">
          {activeTab === 'vllm' ? (
            installedModels.vllm.length === 0 ? (
              <p className="text-gray-500 dark:text-gray-400 text-center py-8">
                No vLLM models installed yet. Search and download models above.
              </p>
            ) : (
              installedModels.vllm.map((model) => (
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
                        {model.has_overrides && (
                          <span className="px-2 py-1 bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 text-xs rounded-full">
                            Custom Settings
                          </span>
                        )}
                        {downloadProgress[model.id] !== undefined && (
                          <div className="flex items-center gap-2">
                            <ArrowPathIcon className="h-4 w-4 animate-spin text-blue-500" />
                            <span className="text-xs text-blue-600 dark:text-blue-400">
                              Downloading: {Math.round(downloadProgress[model.id])}%
                            </span>
                          </div>
                        )}
                      </div>
                      <div className="flex gap-4 mt-2 text-sm text-gray-500">
                        <span>Path: {model.path}</span>
                        <span>Size: {formatBytes(model.size)}</span>
                        <span>Modified: {new Date(model.last_modified).toLocaleDateString()}</span>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowModelSettings(model.id)}
                        className="px-3 py-1 bg-purple-600 text-white rounded hover:bg-purple-700 flex items-center gap-1"
                        title="Model-specific settings"
                      >
                        <Cog6ToothIcon className="h-4 w-4" />
                      </button>
                      {!model.active && (
                        <button
                          onClick={() => activateModel('vllm', model.id)}
                          className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center gap-1"
                        >
                          <PlayIcon className="h-4 w-4" />
                          Activate
                        </button>
                      )}
                      <button
                        onClick={() => deleteModel('vllm', model.id)}
                        className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))
            )
          ) : (
            installedModels.ollama.length === 0 ? (
              <p className="text-gray-500 dark:text-gray-400 text-center py-8">
                No Ollama models installed yet. Search and download models above.
              </p>
            ) : (
              installedModels.ollama.map((model) => (
                <motion.div
                  key={model.name}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="border dark:border-gray-700 rounded-lg p-4"
                >
                  <div className="flex justify-between items-center">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h4 className="font-medium text-gray-900 dark:text-white">{model.name}</h4>
                        {model.has_overrides && (
                          <span className="px-2 py-1 bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 text-xs rounded-full">
                            Custom Settings
                          </span>
                        )}
                        {downloadProgress[model.name] !== undefined && (
                          <div className="flex items-center gap-2">
                            <ArrowPathIcon className="h-4 w-4 animate-spin text-blue-500" />
                            <span className="text-xs text-blue-600 dark:text-blue-400">
                              Downloading: {Math.round(downloadProgress[model.name])}%
                            </span>
                          </div>
                        )}
                      </div>
                      <div className="flex gap-4 mt-2 text-sm text-gray-500">
                        <span>Size: {formatBytes(model.size)}</span>
                        <span>Modified: {new Date(model.last_modified).toLocaleDateString()}</span>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => setShowModelSettings(model.name)}
                        className="px-3 py-1 bg-purple-600 text-white rounded hover:bg-purple-700 flex items-center gap-1"
                        title="Model-specific settings"
                      >
                        <Cog6ToothIcon className="h-4 w-4" />
                      </button>
                      <button
                        className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center gap-1"
                      >
                        <PlayIcon className="h-4 w-4" />
                        Run
                      </button>
                      <button
                        onClick={() => deleteModel('ollama', model.name)}
                        className="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </motion.div>
              ))
            )
          )}
        </div>
      </div>

      {/* Model-Specific Settings Modal */}
      {showModelSettings && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-2xl w-full max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-xl font-semibold">Model-Specific Settings</h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  Settings for: {showModelSettings}
                </p>
              </div>
              <button
                onClick={() => setShowModelSettings(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircleIcon className="h-6 w-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-lg">
                <p className="text-sm text-blue-800 dark:text-blue-200">
                  These settings override the global {activeTab === 'vllm' ? 'vLLM' : 'Ollama'} settings for this specific model.
                  Leave fields empty to use global defaults.
                </p>
              </div>

              <ModelSettingsForm
                modelId={showModelSettings}
                activeTab={activeTab}
                globalSettings={activeTab === 'vllm' ? vllmSettings : ollamaSettings}
                existingOverrides={modelOverrides[showModelSettings] || {}}
                onSave={saveModelSettings}
                onCancel={() => setShowModelSettings(null)}
              />
            </div>
          </div>
        </div>
      )}

      {/* Model Details Panel */}
      {selectedModel && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-2xl w-full max-h-[80vh] overflow-y-auto">
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-xl font-semibold">{selectedModel.modelId}</h3>
              <button
                onClick={() => setSelectedModel(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <XCircleIcon className="h-6 w-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <h4 className="font-medium mb-2">Model Information</h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>Author: {selectedModel.author}</div>
                  <div>Downloads: {selectedModel.downloads?.toLocaleString() || 0}</div>
                  <div>Likes: {selectedModel.likes || 0}</div>
                  <div>Task: {selectedModel.pipeline_tag || 'Unknown'}</div>
                  {selectedModel.lastModified && (
                    <div>Updated: {new Date(selectedModel.lastModified).toLocaleDateString()}</div>
                  )}
                  {selectedModel.library_name && (
                    <div>Library: {selectedModel.library_name}</div>
                  )}
                </div>
              </div>

              {selectedModel.tags && selectedModel.tags.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2">Tags</h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedModel.tags.map((tag) => (
                      <span
                        key={tag}
                        className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-sm rounded"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex gap-2">
                <button
                  onClick={() => {
                    if (activeTab === 'vllm') {
                      downloadVllmModel(selectedModel.modelId);
                    } else {
                      downloadOllamaModel(selectedModel.modelId);
                    }
                    setSelectedModel(null);
                  }}
                  className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 flex items-center gap-2"
                >
                  <CloudArrowDownIcon className="h-5 w-5" />
                  Download Model
                </button>
                <a
                  href={`https://huggingface.co/${selectedModel.modelId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
                >
                  View on Hugging Face
                </a>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}