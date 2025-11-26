// Content script for DexIQ
// Scrapes token/pair data from GeckoTerminal and DexScreener pages

console.log('DexIQ content script loaded');

// Detect which site we're on
const currentSite = detectSite();

// Message handler from side panel
chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  switch (message.type) {
    case 'GET_PAGE_DATA':
      const pageData = extractPageData();
      sendResponse(pageData);
      break;

    default:
      sendResponse({ error: 'Unknown message type' });
  }
});

function detectSite(): 'geckoterminal' | 'dexscreener' | 'unknown' {
  const hostname = window.location.hostname;

  if (hostname.includes('geckoterminal.com')) return 'geckoterminal';
  if (hostname.includes('dexscreener.com')) return 'dexscreener';

  return 'unknown';
}

function extractPageData() {
  switch (currentSite) {
    case 'geckoterminal':
      return extractGeckoTerminalData();
    case 'dexscreener':
      return extractDexScreenerData();
    default:
      return { error: 'Unsupported site' };
  }
}

function extractGeckoTerminalData() {
  const url = window.location.href;
  const pathname = window.location.pathname;

  // Detect page type: list vs single pair
  const isSinglePair = pathname.includes('/pools/');
  const isListPage = pathname.includes('/') && !isSinglePair;

  if (isSinglePair) {
    return extractGeckoTerminalPairData(url, pathname);
  } else if (isListPage) {
    return extractGeckoTerminalListData();
  }

  return { pageType: 'unknown' };
}

function extractGeckoTerminalPairData(url: string, pathname: string) {
  // TODO: Implement proper selectors for GeckoTerminal
  // Example URL: https://www.geckoterminal.com/eth/pools/0xabc123...

  const pathParts = pathname.split('/');
  const chainId = pathParts[pathParts.length - 2];
  const poolAddress = pathParts[pathParts.length - 1];

  // Extract metadata from page
  // This is a simplified example - actual selectors need to be tested
  const symbolElement = document.querySelector('[data-selector="pair-symbol"]');
  const symbol = symbolElement?.textContent?.split('/')[0] || '';
  const quoteSymbol = symbolElement?.textContent?.split('/')[1] || '';

  return {
    pageType: 'pair',
    site: 'geckoterminal',
    chainId,
    poolAddress,
    symbol,
    quoteSymbol,
    tokenUrl: url
  };
}

function extractGeckoTerminalListData() {
  // TODO: Implement list extraction
  // Find all token rows and extract key data
  const tokens: any[] = [];

  // Example: find token cards/rows
  const tokenElements = document.querySelectorAll('[data-selector="token-row"]');

  tokenElements.forEach((element) => {
    // Extract token data - selectors need to be validated
    tokens.push({
      tokenName: element.querySelector('.token-name')?.textContent || '',
      price: parseFloat(element.querySelector('.price')?.textContent || '0'),
      volume: parseFloat(element.querySelector('.volume')?.textContent || '0'),
      change24h: parseFloat(element.querySelector('.change-24h')?.textContent || '0'),
      liquidity: parseFloat(element.querySelector('.liquidity')?.textContent || '0')
    });
  });

  return {
    pageType: 'list',
    site: 'geckoterminal',
    tokens
  };
}

function extractDexScreenerData() {
  // TODO: Implement DexScreener extraction
  // Will need to parse window.location.href and window.location.pathname

  return {
    pageType: 'pair',
    site: 'dexscreener',
    message: 'DexScreener extraction not yet implemented'
  };
}

// Observe URL changes for SPAs
let lastUrl = window.location.href;
new MutationObserver(() => {
  const currentUrl = window.location.href;
  if (currentUrl !== lastUrl) {
    lastUrl = currentUrl;
    console.log('URL changed, notifying side panel...');

    // Notify side panel of page change
    chrome.runtime.sendMessage({
      type: 'PAGE_CHANGED',
      payload: { url: currentUrl }
    });
  }
}).observe(document, { subtree: true, childList: true });
