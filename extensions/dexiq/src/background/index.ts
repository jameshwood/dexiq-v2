// Background service worker for DexIQ
// Handles: messaging routing, side panel open/close, auth token management

console.log('DexIQ background service worker loaded');

// Open side panel when extension icon is clicked
chrome.action.onClicked.addListener(async (tab) => {
  if (tab.id) {
    await chrome.sidePanel.open({ tabId: tab.id });
  }
});

// Message router
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('Background received message:', message);

  switch (message.type) {
    case 'OPEN_SIDE_PANEL':
      handleOpenSidePanel(sender.tab?.id);
      sendResponse({ success: true });
      break;

    case 'GET_AUTH_TOKEN':
      handleGetAuthToken().then(sendResponse);
      return true; // Async response

    case 'SAVE_AUTH_TOKEN':
      handleSaveAuthToken(message.payload).then(sendResponse);
      return true;

    default:
      console.warn('Unknown message type:', message.type);
      sendResponse({ error: 'Unknown message type' });
  }
});

async function handleOpenSidePanel(tabId?: number) {
  if (tabId) {
    await chrome.sidePanel.open({ tabId });
  }
}

async function handleGetAuthToken() {
  // TODO: Implement secure token storage and retrieval
  // Consider using chrome.storage.session for sensitive data
  const result = await chrome.storage.local.get(['authToken', 'authExpiry']);

  if (result.authToken && result.authExpiry) {
    const isExpired = Date.now() > result.authExpiry;
    if (!isExpired) {
      return { token: result.authToken };
    }
  }

  return { token: null };
}

async function handleSaveAuthToken(payload: { token: string; expiresIn?: number }) {
  // TODO: Implement secure token storage
  const expiryTime = payload.expiresIn
    ? Date.now() + (payload.expiresIn * 1000)
    : Date.now() + (24 * 60 * 60 * 1000); // 24 hours default

  await chrome.storage.local.set({
    authToken: payload.token,
    authExpiry: expiryTime
  });

  return { success: true };
}

// Listen for tab updates to detect navigation to supported sites
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.url) {
    const url = new URL(tab.url);

    // Check if on a supported DEX site
    const supportedSites = ['geckoterminal.com', 'dexscreener.com'];
    const isSupported = supportedSites.some(site => url.hostname.includes(site));

    if (isSupported) {
      console.log('Supported DEX site detected:', url.hostname);
      // Could auto-open side panel here if desired
    }
  }
});
