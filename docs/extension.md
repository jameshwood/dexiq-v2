# DexIQ Chrome Extension Development Guide

## Overview

The DexIQ Chrome Extension is built with:
- **Vite** - Build tool and dev server
- **React 18** - UI framework
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Manifest V3** - Latest Chrome extension standard

## Project Structure

```
extensions/dexiq/
├── public/
│   ├── manifest.template.json   # Template rendered by Rake task
│   ├── sidepanel.html           # Side panel entry HTML
│   └── icons/                   # Extension icons (16, 32, 48, 128)
├── src/
│   ├── background/
│   │   └── index.ts             # Service worker (messaging, auth)
│   ├── content/
│   │   └── index.ts             # Page scraper (GeckoTerminal/DexScreener)
│   ├── sidepanel/
│   │   ├── App.tsx              # Main React app
│   │   ├── main.tsx             # React entry point
│   │   ├── components/          # Reusable UI components
│   │   ├── pages/               # Page-level components
│   │   ├── hooks/               # Custom React hooks
│   │   ├── store/               # Zustand state management
│   │   ├── types/               # TypeScript type definitions
│   │   └── utils/               # Utilities (API client, etc.)
│   └── styles/
│       └── index.css            # Global styles + Tailwind
├── vite.config.ts               # Vite configuration
├── tsconfig.json                # TypeScript configuration
├── tailwind.config.js           # Tailwind configuration
└── package.json                 # Dependencies and scripts
```

## Development Workflow

### 1. Initial Setup

```bash
# Install extension dependencies
cd extensions/dexiq
npm install

# Generate manifest and env files
cd ../..
bin/rails extension:env
bin/rails extension:manifest
```

### 2. Development Mode

**Option A: Watch mode (recommended)**
```bash
bin/rails extension:dev
```
This starts Vite in watch mode. Changes are rebuilt automatically.

**Option B: Manual build**
```bash
cd extensions/dexiq
npm run build
```

### 3. Load Extension in Chrome

1. Open Chrome and navigate to `chrome://extensions`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select `extensions/dexiq/dist` folder
5. Extension should appear in your extensions list

### 4. Testing Changes

After rebuilding (automatic in watch mode):
1. Go to `chrome://extensions`
2. Click the refresh icon on your extension
3. Navigate to a GeckoTerminal page
4. Click the extension icon to open side panel

### 5. Debugging

- **Background worker:** `chrome://extensions` → "Inspect views: service worker"
- **Content script:** Open DevTools on the page, check Console
- **Side panel:** Right-click in side panel → "Inspect"

## Key Concepts

### Message Passing

The extension uses Chrome's messaging API for communication between components.

**From content script to background:**
```typescript
chrome.runtime.sendMessage({ type: 'OPEN_SIDE_PANEL' });
```

**From side panel to content script:**
```typescript
const [tab] = await chrome.tabs.query({ active: true });
const response = await chrome.tabs.sendMessage(tab.id, {
  type: 'GET_PAGE_DATA'
});
```

**Background message listener:**
```typescript
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  switch (message.type) {
    case 'GET_AUTH_TOKEN':
      handleGetAuthToken().then(sendResponse);
      return true; // Required for async response
  }
});
```

### Storage

Use `chrome.storage.local` for persistent data:

```typescript
// Save
await chrome.storage.local.set({ authToken: 'abc123' });

// Retrieve
const result = await chrome.storage.local.get(['authToken']);
console.log(result.authToken);
```

**Don't store:**
- Large amounts of data (use backend instead)
- Sensitive unencrypted data

### Content Script Selectors

**TODO:** Test and update selectors for GeckoTerminal and DexScreener.

Current implementation in `src/content/index.ts` uses placeholder selectors:
```typescript
const symbolElement = document.querySelector('[data-selector="pair-symbol"]');
```

**To find real selectors:**
1. Open DevTools on target site
2. Inspect the element you want to scrape
3. Look for stable identifiers:
   - `data-*` attributes (best)
   - Unique class names
   - IDs (if available)
4. Update `extractGeckoTerminalPairData()` and `extractGeckoTerminalListData()`

### API Client

The API client is configured with environment variables:

```typescript
// In src/utils/apiClient.ts
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;
```

Environment variables are injected during build via:
```bash
bin/rails extension:env
```

This creates `.env.development` (or `.env.production`) with:
```
VITE_API_BASE_URL=http://localhost:3000
VITE_WS_URL=ws://localhost:3000/cable
```

### ActionCable Integration

**TODO:** Implement in a custom hook like `useTokenStatus`:

```typescript
import { useEffect, useState } from 'react';

export function useTokenStatus(tokenId: number) {
  const [status, setStatus] = useState(null);

  useEffect(() => {
    const wsUrl = import.meta.env.VITE_WS_URL;
    const cable = createConsumer(`${wsUrl}?token=${authToken}`);

    const subscription = cable.subscriptions.create(
      { channel: 'TokenStatusChannel', token_id: tokenId },
      {
        received: (data) => setStatus(data)
      }
    );

    return () => subscription.unsubscribe();
  }, [tokenId]);

  return status;
}
```

**Libraries to add:**
- `@rails/actioncable` - Official ActionCable client

## Building Components

### Component Structure

Use this pattern for new components:

```typescript
// src/sidepanel/components/TokenCard.tsx
interface TokenCardProps {
  tokenName: string;
  score: number;
  risk: 'low' | 'medium' | 'high';
  sentiment: string;
}

export function TokenCard({ tokenName, score, risk, sentiment }: TokenCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-4">
      <h3 className="font-semibold">{tokenName}</h3>
      <div className="flex justify-between mt-2">
        <span>Score: {score}</span>
        <span className={`text-${risk === 'high' ? 'red' : 'green'}-600`}>
          {risk}
        </span>
      </div>
    </div>
  );
}
```

### Hooks

Create custom hooks for data fetching:

```typescript
// src/sidepanel/hooks/usePairAnalysis.ts
import { useState, useEffect } from 'react';
import { apiClient } from '../utils/apiClient';

export function usePairAnalysis(tokenId: number) {
  const [analysis, setAnalysis] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiClient.analyzePair(tokenId, {})
      .then(setAnalysis)
      .finally(() => setLoading(false));
  }, [tokenId]);

  return { analysis, loading };
}
```

### State Management

For global state, consider Zustand:

```typescript
// src/sidepanel/store/authStore.ts
import { create } from 'zustand';

interface AuthState {
  token: string | null;
  setToken: (token: string) => void;
  clearToken: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  setToken: (token) => set({ token }),
  clearToken: () => set({ token: null }),
}));
```

## Build and Distribution

### Production Build

```bash
# Set Rails environment to production
RAILS_ENV=production bin/rails extension:build
```

This:
1. Generates `.env.production` with production URLs
2. Renders manifest.json with production config
3. Runs `npm run build`
4. Outputs optimized files to `dist/`

### Package for Chrome Web Store

```bash
RAILS_ENV=production bin/rails extension:package
```

Creates a `.zip` file ready for upload to Chrome Web Store.

### What Gets Packaged

- `manifest.json`
- `sidepanel.html`
- `background.js`
- `content.js`
- All assets (icons, CSS, etc.)
- Compiled React bundle

## Testing

### Manual Testing Checklist

- [ ] Extension loads without errors
- [ ] Side panel opens on supported sites
- [ ] Content script detects page type correctly
- [ ] Token list scraping works
- [ ] Single pair scraping works
- [ ] API calls succeed
- [ ] WebSocket connection establishes
- [ ] Auth token is stored and retrieved
- [ ] Purchase logging works
- [ ] P&L calculations are accurate

### Automated Testing (TODO)

Consider adding:
- **Jest** - Unit tests for utilities and hooks
- **React Testing Library** - Component tests
- **Playwright** - E2E tests with real Chrome extension

## Common Issues

### Extension Won't Load

- Check for syntax errors in `manifest.json`
- Ensure all required files exist in `dist/`
- Check browser console for error messages

### Content Script Not Running

- Verify `matches` patterns in manifest
- Check that content script is built to `dist/content.js`
- Ensure page has finished loading

### API Calls Failing

- Check CORS configuration in Rails
- Verify `.env` file has correct URLs
- Check network tab in DevTools
- Ensure Rails server is running

### WebSocket Won't Connect

- Check WSS/WS protocol matches environment
- Verify ActionCable is running
- Check authentication token is valid
- Look for CORS issues

## Next Steps

### Immediate Priorities

1. **Test and fix content script selectors** for GeckoTerminal
2. **Implement proper authentication** (JWT or Devise Token Auth)
3. **Build out React components** for all views
4. **Add ActionCable real-time updates**
5. **Implement chat interface** with session management

### Component Implementations Needed

- `PairOverview` - Token pair summary and key metrics
- `AIInsight` - Display analysis results
- `AIChatbot` - Chat interface with context
- `TokenDetails` - Full token data display
- `PurchaseLog` - Transaction history and form
- `TokenCard` - List item for token list view
- `LoadingScreen` - Loading state
- `UnsupportedPage` - Message for non-DEX pages

### Features to Add

- **Auto-refresh** - Periodically update token data
- **Notifications** - Browser notifications for alerts
- **Favorites** - Save tokens for quick access
- **Export** - Download transaction history as CSV
- **Settings** - User preferences panel

## Resources

- [Chrome Extension Docs](https://developer.chrome.com/docs/extensions/)
- [Manifest V3 Migration](https://developer.chrome.com/docs/extensions/mv3/intro/)
- [Vite Guide](https://vitejs.dev/guide/)
- [React Hooks Reference](https://react.dev/reference/react)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
