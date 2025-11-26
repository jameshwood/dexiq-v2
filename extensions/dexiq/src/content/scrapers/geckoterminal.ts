// GeckoTerminal DOM scraping utilities from v1 (battle-tested)

import type { SymbolPair } from "../../types/token";

/**
 * Extracts the token symbol pair from GeckoTerminal page using priority-ordered selectors
 * Battle-tested from v1 - handles both pair pages and list pages
 */
export function findSymbolPairFromPage(): SymbolPair | null {
  // Priority 1: Try data-controller attribute on pair info
  const pairInfoController = document.querySelector('[data-controller="pair-info"]');
  if (pairInfoController) {
    const fullPair = pairInfoController.getAttribute('data-pair-info-symbol-value');
    if (fullPair) {
      const parts = fullPair.split('/');
      if (parts.length === 2) {
        return {
          fullPair,
          symbol: parts[0].trim(),
          quoteSymbol: parts[1].trim()
        };
      }
    }
  }

  // Priority 2: Try the main heading with data-controller
  const headingController = document.querySelector('h1[data-controller="pair-info"]');
  if (headingController) {
    const text = headingController.textContent?.trim();
    if (text && text.includes('/')) {
      const parts = text.split('/');
      if (parts.length === 2) {
        return {
          fullPair: text,
          symbol: parts[0].trim(),
          quoteSymbol: parts[1].trim()
        };
      }
    }
  }

  // Priority 3: Try any h1 with the pair format
  const h1Elements = document.querySelectorAll('h1');
  for (const h1 of h1Elements) {
    const text = h1.textContent?.trim();
    if (text && text.includes('/')) {
      const parts = text.split('/');
      if (parts.length === 2 && parts[0].length < 20 && parts[1].length < 20) {
        return {
          fullPair: text,
          symbol: parts[0].trim(),
          quoteSymbol: parts[1].trim()
        };
      }
    }
  }

  // Priority 4: Try meta tags
  const ogTitle = document.querySelector('meta[property="og:title"]');
  if (ogTitle) {
    const content = ogTitle.getAttribute('content');
    if (content && content.includes('/')) {
      const match = content.match(/^([A-Z0-9]+)\/([A-Z0-9]+)/i);
      if (match) {
        return {
          fullPair: `${match[1]}/${match[2]}`,
          symbol: match[1],
          quoteSymbol: match[2]
        };
      }
    }
  }

  // Priority 5: Try page title
  const title = document.title;
  if (title && title.includes('/')) {
    const match = title.match(/^([A-Z0-9]+)\/([A-Z0-9]+)/i);
    if (match) {
      return {
        fullPair: `${match[1]}/${match[2]}`,
        symbol: match[1],
        quoteSymbol: match[2]
      };
    }
  }

  return null;
}

/**
 * Returns the default quote symbol for a given chain
 * Battle-tested defaults from v1
 */
export function getDefaultQuoteSymbol(chainId: string): string {
  const defaults: Record<string, string> = {
    'eth': 'ETH',
    'ethereum': 'ETH',
    'bsc': 'BNB',
    'polygon': 'MATIC',
    'arbitrum': 'ETH',
    'avalanche': 'AVAX',
    'fantom': 'FTM',
    'solana': 'SOL',
    'base': 'ETH',
    'optimism': 'ETH'
  };

  return defaults[chainId.toLowerCase()] || 'USD';
}

/**
 * Waits for symbols to appear on the page with retry logic
 * Handles SPAs where content loads after initial page load
 *
 * @param maxAttempts Maximum number of attempts (default: 10)
 * @param delayMs Delay between attempts in ms (default: 500)
 */
export async function waitForSymbols(maxAttempts = 10, delayMs = 500): Promise<SymbolPair | null> {
  for (let i = 0; i < maxAttempts; i++) {
    const symbols = findSymbolPairFromPage();
    if (symbols) {
      return symbols;
    }

    if (i < maxAttempts - 1) {
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }

  return null;
}

/**
 * Extracts price from GeckoTerminal pair page
 */
export function extractPrice(): string | null {
  // Try primary price display
  const priceSelectors = [
    '[data-controller="pair-price"]',
    '.pair-price',
    '[class*="price"]'
  ];

  for (const selector of priceSelectors) {
    const element = document.querySelector(selector);
    if (element?.textContent) {
      const text = element.textContent.trim();
      // Remove currency symbols and extract number
      const match = text.match(/[\d,.]+/);
      if (match) {
        return match[0];
      }
    }
  }

  return null;
}

/**
 * Extracts volume from GeckoTerminal pair page
 */
export function extractVolume(): string | null {
  // Look for volume indicators
  const volumeSelectors = [
    '[data-test-id*="volume"]',
    '[class*="volume"]'
  ];

  for (const selector of volumeSelectors) {
    const elements = document.querySelectorAll(selector);
    for (const element of elements) {
      const text = element.textContent?.trim();
      if (text && (text.includes('$') || text.includes('24h'))) {
        const match = text.match(/\$?([\d,.]+[KMB]?)/);
        if (match) {
          return match[1];
        }
      }
    }
  }

  return null;
}

/**
 * Extracts liquidity from GeckoTerminal pair page
 */
export function extractLiquidity(): string | null {
  // Look for liquidity indicators
  const liquiditySelectors = [
    '[data-test-id*="liquidity"]',
    '[class*="liquidity"]',
    '[class*="tvl"]'
  ];

  for (const selector of liquiditySelectors) {
    const elements = document.querySelectorAll(selector);
    for (const element of elements) {
      const text = element.textContent?.trim();
      if (text && text.includes('$')) {
        const match = text.match(/\$?([\d,.]+[KMB]?)/);
        if (match) {
          return match[1];
        }
      }
    }
  }

  return null;
}

/**
 * Extracts price changes (5m, 1h, 6h, 24h) from GeckoTerminal pair page
 */
export function extractPriceChanges(): {
  change5m: string | null;
  change1h: string | null;
  change6h: string | null;
  change24h: string | null;
} {
  const changes = {
    change5m: null as string | null,
    change1h: null as string | null,
    change6h: null as string | null,
    change24h: null as string | null
  };

  // Look for change indicators
  const changeElements = document.querySelectorAll('[class*="change"], [class*="percent"]');

  for (const element of changeElements) {
    const text = element.textContent?.trim();
    if (!text) continue;

    // Match percentage with optional +/- and time indicator
    const match = text.match(/([+-]?[\d.]+)%/);
    if (!match) continue;

    const percentage = match[1];

    // Determine time period from context
    if (text.includes('5m') || element.getAttribute('data-period') === '5m') {
      changes.change5m = percentage;
    } else if (text.includes('1h') || element.getAttribute('data-period') === '1h') {
      changes.change1h = percentage;
    } else if (text.includes('6h') || element.getAttribute('data-period') === '6h') {
      changes.change6h = percentage;
    } else if (text.includes('24h') || element.getAttribute('data-period') === '24h') {
      changes.change24h = percentage;
    }
  }

  return changes;
}
