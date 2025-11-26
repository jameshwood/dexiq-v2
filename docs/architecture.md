# DexIQ v2 Architecture

## System Overview

DexIQ v2 is a full-stack application consisting of:

1. **Rails API Backend** - Lightning Rails-based server providing JSON API and WebSocket services
2. **Chrome Extension** - React + TypeScript side panel for DEX analysis
3. **External Integrations** - DexScreener and GeckoTerminal API clients
4. **AI Layer** - OpenAI GPT-4 for token analysis and chat

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Chrome Extension                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────┐  │
│  │   Content    │  │  Background  │  │       Side Panel (React)     │  │
│  │   Script     │  │   Worker     │  │  - Token Analysis UI         │  │
│  │              │  │              │  │  - AI Chat Interface          │  │
│  │  - Scraper   │  │  - Messaging │  │  - Purchase Tracking         │  │
│  │  - Observer  │  │  - Auth      │  │  - Real-time Updates         │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                        HTTP/WS over HTTPS
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Rails API Backend                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────┐  │
│  │ Controllers  │  │   Services   │  │         Jobs                 │  │
│  │ /api/v1/*    │  │              │  │  FetchTokenDataJob          │  │
│  │              │  │  Analysis    │  │                              │  │
│  │  - Tokens    │  │  Integrations│  │  Sidekiq Queue              │  │
│  │  - Purchases │  │  Presenters  │  │                              │  │
│  │  - Chat      │  │  Readiness   │  │                              │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────────┘  │
│                                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────────┐  │
│  │  ActionCable │  │   Models     │  │      Database (PostgreSQL)   │  │
│  │              │  │              │  │                              │  │
│  │  - TokenStatus│  │  Token       │  │  - tokens                   │  │
│  │    Channel   │  │  Snapshots   │  │  - snapshots (3 types)      │  │
│  │              │  │  PurchaseLog │  │  - purchase_logs            │  │
│  └──────────────┘  └──────────────┘  └──────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                    │                              │
           External APIs                      OpenAI API
                    │                              │
         ┌──────────┴──────────┐         ┌────────┴────────┐
         │                     │         │                  │
    DexScreener          GeckoTerminal   │   GPT-4         │
         API                  API        │   Structured     │
                                         │   Analysis       │
                                         └──────────────────┘
```

## Core Data Flow

### 1. Token Creation and Data Fetch

```
Extension → POST /api/v1/tokens
                ↓
         Create/Find Token
                ↓
         Enqueue FetchTokenDataJob
                ↓
    ┌───────────┴────────────┐
    │                        │
DexScreener              GeckoTerminal
 API Call                 API Call
    │                        │
    └───────────┬────────────┘
                ↓
         Save Snapshots
                ↓
     Calculate Readiness Tier
                ↓
    Broadcast via ActionCable
                ↓
         Extension Updates
```

### 2. AI Analysis Flow

```
Extension → POST /api/v1/tokens/:id/analyse_pair
                ↓
         Gather All Snapshots
                ↓
         TokenPairAnalysisService
                ↓
         Build AI Prompt
                ↓
         OpenAI API Call (GPT-4)
                ↓
         Structure Response
                ↓
         Cache Result (15 min)
                ↓
         Return to Extension
```

### 3. Real-Time Updates (ActionCable)

```
Extension Opens Side Panel
         ↓
Connect to ActionCable (WSS)
         ↓
Authenticate Connection
         ↓
Subscribe to token_status_<id>
         ↓
[Background: Job Completes]
         ↓
Broadcast Readiness Message
         ↓
Extension Receives Update
         ↓
Fetch Full Token Data
```

## Key Components

### Backend Services

- **Integrations** (`app/services/integrations/`)
  - `GeckoTerminalClient` - HTTP client for GeckoTerminal API
  - `DexscreenerClient` - HTTP client for DexScreener API

- **Analysis** (`app/services/analysis/`)
  - `TokenListHeuristicService` - Fast rule-based token scoring
  - `TokenPairAnalysisService` - Deep AI-driven pair analysis
  - `TokenListAnalysisService` - AI-enhanced list analysis

- **Readiness** (`app/services/readiness/`)
  - `TokenDataReadinessService` - Determines data availability tier

- **Presenters** (`app/services/presenters/`)
  - `TokenPresenter` - Consistent token JSON format
  - `PurchasePresenter` - Position and P&L calculations
  - `AnalysisPresenter` - Analysis result formatting

### Models

- **Token** - Core entity, uniquely identified by chain_id + pool_address
- **DexscreenerSnapshot** - DexScreener API response data
- **GeckoTerminalSnapshot** - GeckoTerminal pool data
- **GeckoOhlcvSnapshot** - OHLCV candle data
- **PurchaseLog** - Buy/sell transactions
- **AiChatInteraction** - Chat conversation history

### Extension Components

- **Background Worker** - Message routing, auth management
- **Content Script** - Page scraping, URL monitoring
- **Side Panel** - React app with:
  - Token list analysis view
  - Single token deep analysis view
  - AI chatbot interface
  - Purchase tracking and P&L display

## Security Model

### API Authentication

**Current:** Basic placeholder (uses first user)
**TODO:** Implement one of:
- JWT tokens with short TTL
- Devise Token Auth with refresh tokens
- Signed tokens with HMAC verification

### ActionCable Authentication

**Current:** Token-based via query string
**TODO:** Implement JWT verification in `connection.rb`

### Extension Storage

- Auth tokens stored in `chrome.storage.local` with TTL
- Sensitive data never stored in plain text
- Auto-refresh mechanism for expired tokens

## Performance Considerations

### Caching Strategy

- **Token Analysis:** 15-minute cache (Rails.cache)
- **External API Responses:** Snapshot-based (DB storage)
- **Extension:** TanStack Query for client-side caching

### Background Jobs

- **Queue:** Sidekiq (production), Async (development)
- **Retries:** Exponential backoff on Faraday errors
- **Monitoring:** Structured logging with Lograge

### Database Indexes

- Unique index on `tokens(chain_id, pool_address)`
- Indexes on foreign keys (automatic)
- Composite index on `gecko_ohlcv_snapshots(token_id, timeframe)`
- Session index on `ai_chat_interactions(session_id, created_at)`

## Deployment

### Environment Variables

**Required:**
- `DATABASE_URL` - PostgreSQL connection
- `REDIS_URL` - Redis for ActionCable and Sidekiq
- `OPENAI_API_KEY` - OpenAI API key
- `EXTENSION_ALLOWED_ORIGINS` - Comma-separated extension origins

**Optional:**
- `OPENAI_MODEL` - Default: gpt-4o
- `RAILS_LOG_LEVEL` - Default: info

### Scaling Considerations

- **Horizontal:** Stateless Rails app, scales with load balancer
- **Jobs:** Sidekiq workers can scale independently
- **Database:** Read replicas for analytics queries
- **ActionCable:** Consider dedicated ActionCable servers for high traffic

## Future Enhancements

1. **Smart Alerts** - Background monitoring and push notifications
2. **Portfolio Dashboard** - Web-based analytics view
3. **Advanced Charts** - Technical indicators and visualizations
4. **Multi-DEX Support** - Expand beyond GeckoTerminal/DexScreener
5. **Team Features** - Shared watchlists and collaborative analysis
