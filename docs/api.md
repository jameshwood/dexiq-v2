# DexIQ v2 API Documentation

Base URL: `/api/v1`

All endpoints return JSON with this structure:

```json
{
  "status": "ok" | "error",
  "message": "Optional message",
  "data": {},
  "errors": []
}
```

## Authentication

**TODO:** Authentication must be implemented before production deployment.

Options:
- JWT tokens
- Devise Token Auth
- API keys

For now, endpoints use a placeholder that returns the first user.

## Endpoints

### Tokens

#### Create or Find Token

**POST** `/api/v1/tokens`

Creates a new token or returns existing one. Enqueues background data fetch job.

**Request Body:**
```json
{
  "chain_id": "eth",
  "pool_address": "0xabc123...",
  "symbol": "TOKEN",
  "quote_symbol": "WETH",
  "token_url": "https://www.geckoterminal.com/eth/pools/0xabc123..."
}
```

**Response:**
```json
{
  "status": "ok",
  "token_id": 42,
  "message": "Token created/found. Data fetch enqueued."
}
```

---

#### Get Token Details

**GET** `/api/v1/tokens/:id`

Returns full token data including all snapshots.

**Response:**
```json
{
  "status": "ok",
  "token": {
    "id": 42,
    "chain_id": "eth",
    "pool_address": "0xabc123...",
    "symbol": "TOKEN",
    "quote_symbol": "WETH",
    "token_url": "https://...",
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z",
    "readiness": {
      "tier": "lots",
      "has_dexscreener": true,
      "has_gecko_terminal": true,
      "has_ohlcv": true,
      "last_updated": "2025-01-01T00:05:00Z"
    },
    "dex_snapshot": { "data": {...}, "fetched_at": "..." },
    "gecko_snapshot": { "data": {...}, "fetched_at": "..." },
    "ohlcv": [...]
  }
}
```

---

#### Get Data Readiness Status

**GET** `/api/v1/tokens/:id/status`

Quick check for data availability.

**Response:**
```json
{
  "status": "ok",
  "tier": "some",
  "has_dexscreener": true,
  "has_gecko_terminal": false,
  "has_ohlcv": true,
  "last_updated": "2025-01-01T00:05:00Z"
}
```

**Tier Values:**
- `"none"` - No data available yet
- `"some"` - 1-2 data sources available
- `"lots"` - All 3 sources available

---

#### Analyze Single Pair

**POST** `/api/v1/tokens/:id/analyse_pair`

Performs deep AI analysis on a token pair.

**Request Body:**
```json
{
  "symbol": "TOKEN",
  "quote_symbol": "WETH",
  "purchase_price": 0.5
}
```

**Response:**
```json
{
  "status": "ok",
  "data": {
    "assistant": "Based on the data, this token shows strong momentum...",
    "insights": [
      "High volume detected in last 24h",
      "Liquidity is adequate for medium trades",
      "Price momentum is positive"
    ],
    "structured_insights": [],
    "details": {
      "current_price": 0.55,
      "volume_24h": 1000000,
      "liquidity": 500000,
      "price_change_24h": 10.5,
      "market_cap": 5000000
    },
    "timestamp": "2025-01-01T00:10:00Z"
  }
}
```

---

#### Analyze Token List

**POST** `/api/v1/analyse_tokens`

Fast heuristic analysis for multiple tokens.

**Request Body:**
```json
{
  "tokens": [
    {
      "tokenName": "TOKEN1",
      "price": 0.5,
      "volume": 1000000,
      "change5m": 5.0,
      "change1h": 10.0,
      "change6h": 15.0,
      "change24h": 25.0,
      "liquidity": 500000
    },
    { "...": "..." }
  ]
}
```

**Response:**
```json
{
  "status": "ok",
  "data": [
    {
      "tokenName": "TOKEN1",
      "score": 75,
      "risk": "low",
      "recommendation": "consider",
      "sentiment": "bullish",
      "emoji": "📈"
    },
    { "...": "..." }
  ]
}
```

**Score:** 0-100 (higher is better)
**Risk:** `"low"` | `"medium"` | `"high"`
**Recommendation:** `"avoid"` | `"watch"` | `"consider"` | `"strong_buy"`
**Sentiment:** `"very_bearish"` | `"bearish"` | `"neutral"` | `"bullish"` | `"very_bullish"`

---

### Purchase Tracking

#### Get Purchase History

**GET** `/api/v1/tokens/:id/purchases`

Returns all purchases, current position, and P&L for the current user.

**Response:**
```json
{
  "status": "ok",
  "purchases": [
    {
      "id": 1,
      "transaction_type": "buy",
      "amount": 1000,
      "price_per_token": 0.5,
      "total_value": 500,
      "transaction_hash": "0xdef456...",
      "notes": "Initial position",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "current_position": {
    "total_bought": 1000,
    "total_sold": 0,
    "current_amount": 1000,
    "average_buy_price": 0.5,
    "total_invested": 500
  },
  "pnl": {
    "current_price": 0.55,
    "current_value": 550,
    "pnl_amount": 50,
    "pnl_percent": 10.0
  }
}
```

---

#### Log Purchase

**POST** `/api/v1/tokens/:id/purchases`

Records a buy or sell transaction.

**Request Body:**
```json
{
  "purchase": {
    "transaction_type": "buy",
    "amount": 1000,
    "price_per_token": 0.5,
    "transaction_hash": "0xdef456...",
    "notes": "Optional notes"
  }
}
```

**Response:**
```json
{
  "status": "ok",
  "purchase": { /* new purchase object */ },
  "current_position": { /* updated position */ },
  "message": "Transaction logged successfully"
}
```

---

### AI Chat

#### Chat About Token

**POST** `/api/v1/tokens/:id/chat_with_ai`

Ask questions about a token with context-aware AI.

**Request Body:**
```json
{
  "prompt": "What are the key risks for this token?",
  "session_id": "uuid-from-previous-chat",
  "pairData": { /* optional context */ },
  "analysis": { /* optional previous analysis */ }
}
```

**Response:**
```json
{
  "status": "ok",
  "reply": "Based on the data, the main risks are...",
  "session_id": "uuid"
}
```

**Note:** Session ID is auto-generated if not provided. Include it in subsequent messages for conversation continuity.

---

## Error Handling

### Error Response Format

```json
{
  "status": "error",
  "message": "Human-readable error message",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

### Common HTTP Status Codes

- `200 OK` - Success
- `400 Bad Request` - Invalid parameters
- `401 Unauthorized` - Authentication required
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation failed
- `500 Internal Server Error` - Server error

---

## ActionCable (WebSocket)

### Connection

**URL:** `ws://localhost:3000/cable` (dev) or `wss://your-domain.com/cable` (prod)

**Authentication:** Pass token as query param: `?token=YOUR_TOKEN`

### Channels

#### TokenStatusChannel

Subscribe to real-time token data readiness updates.

**Subscribe:**
```json
{
  "command": "subscribe",
  "identifier": "{\"channel\":\"TokenStatusChannel\",\"token_id\":42}"
}
```

**Message Format:**
```json
{
  "status": "ready",
  "tier": "lots",
  "token_id": 42,
  "timestamp": "2025-01-01T00:05:00Z",
  "data": {
    "has_dexscreener": true,
    "has_gecko_terminal": true,
    "has_ohlcv": true
  }
}
```

**Error Message:**
```json
{
  "status": "error",
  "token_id": 42,
  "error": "Failed to fetch data",
  "timestamp": "2025-01-01T00:05:00Z"
}
```

---

## Rate Limiting

**TODO:** Implement with `rack-attack`

Planned limits:
- 60 requests/minute per IP
- 1000 requests/hour per user
- Special limits for AI endpoints (higher cost)

---

## Caching

- **Token Analysis:** 15 minutes
- **External API Snapshots:** Stored in DB, fetched on demand
- **List Analysis:** No caching (fast heuristic)

---

## Development Tips

### Testing API Endpoints

```bash
# Create token
curl -X POST http://localhost:3000/api/v1/tokens \
  -H "Content-Type: application/json" \
  -d '{"chain_id":"eth","pool_address":"0xabc123","symbol":"TEST","quote_symbol":"WETH"}'

# Get token
curl http://localhost:3000/api/v1/tokens/1

# Analyze pair
curl -X POST http://localhost:3000/api/v1/tokens/1/analyse_pair \
  -H "Content-Type: application/json" \
  -d '{"symbol":"TEST","quote_symbol":"WETH"}'
```

### WebSocket Testing

Use `websocat` or browser dev tools:

```bash
websocat "ws://localhost:3000/cable?token=test"
```

Then send subscription command.
