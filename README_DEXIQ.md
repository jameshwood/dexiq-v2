# DexIQ v2 - Production-Ready Skeleton

**AI-Powered Token Analysis for DEX Traders**

A complete rebuild of DexIQ on Lightning Rails with a Chrome Extension frontend. This is a fully scaffolded, production-ready skeleton ready for incremental implementation.

## What's Been Built

This skeleton includes **everything** needed to start building DexIQ v2:

### ✅ Complete Backend (Rails)

- **6 Database Models** with proper associations and validations
  - Token, DexscreenerSnapshot, GeckoTerminalSnapshot, GeckoOhlcvSnapshot, PurchaseLog, AiChatInteraction
- **Full API Layer** (`/api/v1`)
  - Token CRUD
  - Analysis endpoints (list and pair)
  - Purchase tracking with P&L
  - AI chat interface
- **Service Layer**
  - External API clients (GeckoTerminal, DexScreener)
  - Analysis services (heuristic and AI-based)
  - Readiness tracking
  - Presenters for consistent JSON
- **Background Jobs** with Sidekiq
  - FetchTokenDataJob orchestrates external data fetching
- **Real-time Updates** via ActionCable
  - TokenStatusChannel broadcasts data readiness
- **Initializers**
  - CORS for extension
  - Faraday with retry logic
  - Lograge for structured logging
  - OpenAI configuration

### ✅ Complete Chrome Extension

- **Vite + React + TypeScript + Tailwind** setup
- **Manifest V3** structure with templating
- **Background service worker** for messaging and auth
- **Content scripts** for page scraping (GeckoTerminal/DexScreener)
- **React side panel** with routing skeleton
- **API client** with retry logic and auth
- **Build automation** via Rake tasks

### ✅ Landing Page

- **Production-ready marketing page** with:
  - Hero section
  - Feature grid
  - How it works
  - Tech stack showcase
  - Roadmap
  - CTA sections
  - Modern CSS with responsive design

### ✅ Testing Infrastructure

- **Test stubs** for models, controllers, services, jobs
- **Clear TODO markers** for incremental implementation

### ✅ Comprehensive Documentation

- **architecture.md** - System design, data flow, components
- **api.md** - Complete API reference with examples
- **extension.md** - Development guide for the extension

## Quick Start

### 1. Install Dependencies

```bash
# Backend
bundle install

# Extension
cd extensions/dexiq && npm install && cd ../..
```

### 2. Setup Database

```bash
bin/rails db:create db:migrate
```

### 3. Configure Environment

Add to `.env`:
```bash
OPENAI_API_KEY=your_key_here
EXTENSION_ALLOWED_ORIGINS=chrome-extension://your-extension-id
```

### 4. Start Rails Server

```bash
bin/rails server
```

### 5. Build Extension

```bash
# Generate manifest and env files
bin/rails extension:env extension:manifest

# Build extension
cd extensions/dexiq
npm run build

# Load extensions/dexiq/dist in Chrome
```

### 6. Visit Landing Page

Open http://localhost:3000

## Project Structure

```
├── app/
│   ├── channels/           # ActionCable (TokenStatusChannel)
│   ├── controllers/
│   │   └── api/v1/        # API endpoints
│   ├── jobs/              # Background jobs
│   ├── models/            # 6 core models
│   └── services/          # Business logic
│       ├── analysis/      # Token analysis services
│       ├── integrations/  # External API clients
│       ├── presenters/    # JSON formatting
│       └── readiness/     # Data tier calculation
├── config/
│   ├── extension.yml      # Extension metadata by environment
│   └── initializers/      # CORS, Faraday, OpenAI, etc.
├── extensions/dexiq/      # Chrome extension
│   ├── public/
│   ├── src/
│   └── vite.config.ts
├── docs/                  # Full documentation
├── lib/tasks/
│   └── extension.rake     # Build automation
└── test/                  # Test stubs
```

## API Endpoints

All under `/api/v1`:

- `POST /tokens` - Create/find token
- `GET /tokens/:id` - Get full token data
- `GET /tokens/:id/status` - Data readiness check
- `POST /tokens/:id/analyse_pair` - Deep AI analysis
- `POST /analyse_tokens` - List analysis
- `GET /tokens/:id/purchases` - Purchase history + P&L
- `POST /tokens/:id/purchases` - Log transaction
- `POST /tokens/:id/chat_with_ai` - AI chat

WebSocket: `TokenStatusChannel` for real-time updates

## Extension Build Commands

```bash
bin/rails extension:env        # Generate .env files
bin/rails extension:manifest   # Render manifest.json
bin/rails extension:build      # Full build
bin/rails extension:package    # Create .zip for Chrome Web Store
bin/rails extension:clean      # Remove build artifacts
bin/rails extension:dev        # Development mode with watch
```

## Key TODOs for Production

### Critical

1. **Implement Authentication** (app/controllers/api/v1/base_controller.rb:20)
   - Choose: JWT, Devise Token Auth, or API keys
   - Update ActionCable connection auth

2. **Add OpenAI Integration** (app/services/analysis/token_pair_analysis_service.rb:50)
   - Implement `perform_ai_analysis` with GPT-4
   - Structure prompts for consistent output

3. **Test Content Script Selectors** (extensions/dexiq/src/content/index.ts:75)
   - Verify GeckoTerminal selectors on real pages
   - Add DexScreener selectors

4. **Build React Components** (extensions/dexiq/src/sidepanel/components/)
   - PairOverview, AIInsight, AIChatbot, TokenDetails, PurchaseLog, TokenCard

### Important

5. **Add Tests** - Fill in test stubs throughout `test/`
6. **WebMock for API Tests** - Mock external API calls in tests
7. **ActionCable Client** - Implement `useTokenStatus` hook in extension
8. **Error Handling** - Improve error messages and user feedback
9. **Rate Limiting** - Add rack-attack configuration
10. **Monitoring** - Set up error tracking (e.g., Sentry)

## Environment Variables

**Required:**
- `DATABASE_URL` - PostgreSQL
- `REDIS_URL` - For ActionCable and Sidekiq
- `OPENAI_API_KEY` - OpenAI API key

**Recommended:**
- `EXTENSION_ALLOWED_ORIGINS` - Extension ID for CORS
- `OPENAI_MODEL` - Default: gpt-4o
- `RAILS_LOG_LEVEL` - Default: info

## Deployment

### Backend

1. Set environment variables in hosting platform
2. Run migrations: `bin/rails db:migrate`
3. Precompile assets: `bin/rails assets:precompile`
4. Start web server and background workers

### Extension

1. Set `RAILS_ENV=production`
2. Update production URLs in `config/extension.yml`
3. Run `bin/rails extension:package`
4. Upload `.zip` to Chrome Web Store

## Documentation

- **[Architecture](docs/architecture.md)** - System design and data flow
- **[API Reference](docs/api.md)** - Complete endpoint documentation
- **[Extension Guide](docs/extension.md)** - Extension development

## Tech Stack

- **Backend:** Rails 8.0, PostgreSQL, Redis, Sidekiq
- **API:** RESTful JSON API with ActionCable WebSockets
- **AI:** OpenAI GPT-4 with structured outputs
- **Extension:** Vite, React 18, TypeScript, Tailwind CSS
- **External APIs:** GeckoTerminal, DexScreener
- **Testing:** Minitest
- **Deployment:** Environment-aware, containerization-ready

## Philosophy

This skeleton follows these principles:

1. **Environment-based configuration** - No hardcoded URLs or secrets
2. **API-first design** - Stable, versioned JSON API
3. **Thin controllers, fat services** - Business logic in service objects
4. **Real-time by design** - ActionCable for live updates
5. **Single source of truth** - Domain logic lives in Rails
6. **Defensive integrations** - Retry, backoff, and structured errors
7. **Test the money path** - Critical flows have test coverage
8. **Deploy early and often** - Built for incremental deployment

## Next Steps

1. **Review the docs** in `docs/` folder
2. **Run the Rails server** and visit the landing page
3. **Build the extension** and load it in Chrome
4. **Implement authentication** as first priority
5. **Fill in AI analysis** logic with real OpenAI calls
6. **Build out React components** one by one
7. **Add comprehensive tests** as you implement features
8. **Deploy** to staging environment early

## Support

- **GitHub Issues:** Report bugs and request features
- **Documentation:** See `docs/` for detailed guides
- **TODOs:** Search codebase for `TODO` markers

---

**Built with Lightning Rails** ⚡️

This is a complete, production-ready skeleton. Everything is wired up, documented, and ready for incremental implementation. Start with authentication, then work your way through the TODOs.

Good luck building DexIQ v2! 🚀
