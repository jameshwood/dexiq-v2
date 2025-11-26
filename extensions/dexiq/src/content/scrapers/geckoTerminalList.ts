// GeckoTerminal list page scraping utilities from v1 (battle-tested)

import type { TokenPreview } from "../../types/token";

/**
 * Extracts all token rows from GeckoTerminal list/trending pages
 * Battle-tested from v1 - works on trending, new pairs, and custom lists
 */
export function extractTokenListFromPage(): TokenPreview[] {
  const tokens: TokenPreview[] = [];

  // Try multiple selectors for token rows
  const rowSelectors = [
    '[data-component="token-row"]',
    '[data-controller="token-row"]',
    'tr[data-href*="/pools/"]',
    'a[href*="/pools/"]'
  ];

  let tokenRows: Element[] = [];
  for (const selector of rowSelectors) {
    const elements = Array.from(document.querySelectorAll(selector));
    if (elements.length > 0) {
      tokenRows = elements;
      break;
    }
  }

  for (const row of tokenRows) {
    try {
      const token = extractTokenFromRow(row);
      if (token) {
        tokens.push(token);
      }
    } catch (error) {
      console.error('[DexIQ] Error extracting token from row:', error);
    }
  }

  return tokens;
}

/**
 * Extracts token data from a single row element
 */
function extractTokenFromRow(row: Element): TokenPreview | null {
  // Extract token URL
  const linkElement = row.querySelector('a[href*="/pools/"]') ||
                      (row as HTMLElement).closest('a[href*="/pools/"]') ||
                      (row.hasAttribute('data-href') ? row : null);

  let tokenUrl: string | null = null;
  if (linkElement) {
    tokenUrl = (linkElement as HTMLAnchorElement).href ||
               linkElement.getAttribute('data-href') ||
               linkElement.getAttribute('href');

    // Make absolute URL if relative
    if (tokenUrl && tokenUrl.startsWith('/')) {
      tokenUrl = `https://www.geckoterminal.com${tokenUrl}`;
    }
  }

  // Extract symbol (usually the most prominent text or first column)
  const symbolElement = row.querySelector('[data-test-id*="symbol"]') ||
                       row.querySelector('.token-symbol') ||
                       row.querySelector('.symbol');

  let tokenSymbol = symbolElement?.textContent?.trim() || '';

  // If no dedicated symbol element, try to extract from combined text
  if (!tokenSymbol) {
    const allText = row.textContent?.trim() || '';
    const symbolMatch = allText.match(/^([A-Z0-9]+)\s*\/\s*([A-Z0-9]+)/);
    if (symbolMatch) {
      tokenSymbol = symbolMatch[1];
    }
  }

  // Extract token name (often before or with symbol)
  const nameElement = row.querySelector('[data-test-id*="name"]') ||
                     row.querySelector('.token-name') ||
                     row.querySelector('.name');
  const tokenName = nameElement?.textContent?.trim() || tokenSymbol;

  // Extract quote symbol (usually paired with main symbol)
  let quoteSymbol = 'USD';
  const pairText = row.textContent?.trim() || '';
  const pairMatch = pairText.match(/([A-Z0-9]+)\s*\/\s*([A-Z0-9]+)/);
  if (pairMatch) {
    quoteSymbol = pairMatch[2];
  }

  // Extract price
  const price = extractValueFromRow(row, ['price'], true);

  // Extract volume (24h)
  const volume = extractValueFromRow(row, ['volume', '24h'], false);

  // Extract liquidity / TVL
  const liquidity = extractValueFromRow(row, ['liquidity', 'tvl'], false);

  // Extract price changes
  const changes = extractPriceChangesFromRow(row);

  // Only return if we have at least symbol and URL
  if (!tokenSymbol || !tokenUrl) {
    return null;
  }

  return {
    source: 'geckoterminal',
    tokenName,
    tokenSymbol,
    quoteSymbol,
    price: price || 'N/A',
    volume: volume || 'N/A',
    change5m: changes.change5m || 'N/A',
    change1h: changes.change1h || 'N/A',
    change6h: changes.change6h || 'N/A',
    change24h: changes.change24h || 'N/A',
    liquidity: liquidity || 'N/A',
    tokenUrl
  };
}

/**
 * Extracts a numeric value from a row using keyword matching
 */
function extractValueFromRow(
  row: Element,
  keywords: string[],
  isPriceField: boolean
): string | null {
  // Look for elements containing keywords
  const allElements = row.querySelectorAll('*');

  for (const element of allElements) {
    const text = element.textContent?.trim() || '';
    const className = element.className || '';
    const testId = element.getAttribute('data-test-id') || '';

    // Check if element or its attributes contain keywords
    const matchesKeyword = keywords.some(keyword =>
      text.toLowerCase().includes(keyword) ||
      className.toLowerCase().includes(keyword) ||
      testId.toLowerCase().includes(keyword)
    );

    if (matchesKeyword) {
      // Extract numeric value
      if (isPriceField) {
        const match = text.match(/\$?([\d,.]+)/);
        return match ? match[1] : null;
      } else {
        const match = text.match(/\$?([\d,.]+[KMB]?)/);
        return match ? match[1] : null;
      }
    }
  }

  return null;
}

/**
 * Extracts price change percentages from a row
 */
function extractPriceChangesFromRow(row: Element): {
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

  // Find all elements that might contain percentage changes
  const allElements = row.querySelectorAll('*');

  for (const element of allElements) {
    const text = element.textContent?.trim() || '';
    const testId = element.getAttribute('data-test-id') || '';
    const className = element.className || '';

    // Match percentage
    const match = text.match(/([+-]?[\d.]+)%/);
    if (!match) continue;

    const percentage = match[1];

    // Determine time period
    if (text.includes('5m') || testId.includes('5m') || className.includes('5m')) {
      changes.change5m = percentage;
    } else if (text.includes('1h') || testId.includes('1h') || className.includes('1h')) {
      changes.change1h = percentage;
    } else if (text.includes('6h') || testId.includes('6h') || className.includes('6h')) {
      changes.change6h = percentage;
    } else if (text.includes('24h') || testId.includes('24h') || className.includes('24h')) {
      changes.change24h = percentage;
    }
  }

  return changes;
}

/**
 * Waits for token list to load on the page
 *
 * @param maxAttempts Maximum number of attempts (default: 10)
 * @param delayMs Delay between attempts in ms (default: 500)
 */
export async function waitForTokenList(maxAttempts = 10, delayMs = 500): Promise<TokenPreview[]> {
  for (let i = 0; i < maxAttempts; i++) {
    const tokens = extractTokenListFromPage();
    if (tokens.length > 0) {
      return tokens;
    }

    if (i < maxAttempts - 1) {
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }

  return [];
}
