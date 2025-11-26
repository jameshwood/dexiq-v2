// Content script for DexIQ
// Scrapes token/pair data from GeckoTerminal and DexScreener pages

import { getActiveSite, isOnPairPage, getPoolAddress, getChainId } from './utils/pageDetectors';
import {
  waitForSymbols,
  extractPrice,
  extractVolume,
  extractLiquidity,
  extractPriceChanges
} from './scrapers/geckoterminal';
import { waitForTokenList } from './scrapers/geckoTerminalList';
import type { PairPayload, TokenPreview } from '../types/token';

console.log('DexIQ content script loaded');

// Detect which site we're on
const currentSite = getActiveSite();

// Message handler from side panel
chrome.runtime.onMessage.addListener((message, _sender, sendResponse) => {
  switch (message.type) {
    case 'GET_PAGE_DATA':
      handleGetPageData(sendResponse);
      return true; // Keep channel open for async response

    default:
      sendResponse({ error: 'Unknown message type' });
  }
});

async function handleGetPageData(sendResponse: (response: any) => void) {
  try {
    const pageData = await extractPageData();
    sendResponse(pageData);
  } catch (error) {
    sendResponse({ error: error instanceof Error ? error.message : 'Unknown error' });
  }
}

async function extractPageData() {
  switch (currentSite) {
    case 'geckoterminal':
      return await extractGeckoTerminalData();
    case 'dexscreener':
      return extractDexScreenerData();
    default:
      return { error: 'Unsupported site' };
  }
}

async function extractGeckoTerminalData() {
  const url = window.location.href;

  // Use battle-tested page detection from v1
  if (isOnPairPage()) {
    return await extractGeckoTerminalPairData(url);
  } else {
    return await extractGeckoTerminalListData();
  }
}

async function extractGeckoTerminalPairData(url: string): Promise<PairPayload> {
  // Wait for symbols to load (handles SPA rendering)
  const symbolPair = await waitForSymbols();

  if (!symbolPair) {
    throw new Error('Could not extract symbol pair from page');
  }

  // Extract additional data using battle-tested selectors
  const price = extractPrice();
  const volume = extractVolume();
  const liquidity = extractLiquidity();
  const changes = extractPriceChanges();

  // Get pool address and chain ID from URL
  const poolAddress = getPoolAddress();
  const chainId = getChainId();

  if (!poolAddress) {
    throw new Error('Could not extract pool address from URL');
  }

  return {
    site: 'geckoterminal',
    chainId,
    poolAddress,
    symbol: symbolPair.symbol,
    quoteSymbol: symbolPair.quoteSymbol,
    tokenUrl: url,
    // Include extracted data for immediate use
    price: price || 'N/A',
    volume: volume || 'N/A',
    liquidity: liquidity || 'N/A',
    change5m: changes.change5m || 'N/A',
    change1h: changes.change1h || 'N/A',
    change6h: changes.change6h || 'N/A',
    change24h: changes.change24h || 'N/A'
  } as PairPayload;
}

async function extractGeckoTerminalListData(): Promise<{ pageType: string; site: string; tokens: TokenPreview[] }> {
  // Wait for token list to load (handles SPA rendering)
  const tokens = await waitForTokenList();

  return {
    pageType: 'list',
    site: 'geckoterminal',
    tokens
  };
}

function extractDexScreenerData() {
  // TODO: Implement DexScreener extraction with v1 patterns
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
