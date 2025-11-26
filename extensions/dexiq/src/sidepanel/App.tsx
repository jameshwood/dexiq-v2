import { useState, useEffect } from 'react';
import type { PageData } from './types/api';

function App() {
  const [pageData, setPageData] = useState<PageData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get page data from content script
    loadPageData();

    // Listen for page changes
    chrome.runtime.onMessage.addListener((message) => {
      if (message.type === 'PAGE_CHANGED') {
        loadPageData();
      }
    });
  }, []);

  async function loadPageData() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

      if (tab.id) {
        const response = await chrome.tabs.sendMessage(tab.id, { type: 'GET_PAGE_DATA' });
        setPageData(response);
      }
    } catch (error) {
      console.error('Failed to get page data:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading DexIQ...</p>
        </div>
      </div>
    );
  }

  // TODO: Replace with proper routing and components
  // For now, show basic page type detection

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">DexIQ v2</h1>
        <p className="text-sm text-gray-600">AI-Powered Token Analysis</p>
      </header>

      {!pageData || pageData.pageType === 'unknown' ? (
        <div className="bg-white rounded-lg shadow p-6 text-center">
          <div className="text-4xl mb-4">🔍</div>
          <h2 className="text-lg font-semibold text-gray-900 mb-2">
            Navigate to a Supported Page
          </h2>
          <p className="text-gray-600 mb-4">
            DexIQ works on GeckoTerminal and DexScreener token pages.
          </p>
          <ul className="text-sm text-gray-500 space-y-1">
            <li>• GeckoTerminal token lists</li>
            <li>• GeckoTerminal pool pages</li>
            <li>• DexScreener pair pages (coming soon)</li>
          </ul>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="bg-white rounded-lg shadow p-4">
            <h3 className="font-semibold text-gray-900 mb-2">Page Detected</h3>
            <dl className="space-y-1 text-sm">
              <div>
                <dt className="inline text-gray-600">Type: </dt>
                <dd className="inline font-medium">{pageData.pageType}</dd>
              </div>
              <div>
                <dt className="inline text-gray-600">Site: </dt>
                <dd className="inline font-medium">{pageData.site}</dd>
              </div>
              {pageData.pageType === 'pair' && (
                <>
                  <div>
                    <dt className="inline text-gray-600">Chain: </dt>
                    <dd className="inline font-medium">{pageData.chainId}</dd>
                  </div>
                  <div>
                    <dt className="inline text-gray-600">Pool: </dt>
                    <dd className="inline font-mono text-xs">{pageData.poolAddress}</dd>
                  </div>
                </>
              )}
            </dl>
          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-800">
              <strong>TODO:</strong> Implement full UI with analysis, chat, and purchase tracking.
              This is a working skeleton - see docs/extension.md for development guide.
            </p>
          </div>
        </div>
      )}

      <footer className="mt-8 text-center text-xs text-gray-500">
        <p>DexIQ v2 • Built with Lightning Rails</p>
      </footer>
    </div>
  );
}

export default App;
