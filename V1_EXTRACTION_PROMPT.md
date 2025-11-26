# DexIQ v1 → v2 Code Extraction Prompt

**Use this prompt in your DexIQ v1 project with Claude Code**

---

## Context

I'm rebuilding DexIQ as v2 on a clean Lightning Rails architecture. The v2 skeleton is complete with proper separation of concerns, but I need to extract **proven, working code** from v1 to accelerate development.

## Your Mission

Search through the v1 codebase and extract **only the valuable, working parts** that can be reused in v2. Do NOT extract architectural code - v2 has a better structure. Focus on:

1. **Proven patterns** that work
2. **Tested selectors** for scraping
3. **Refined prompts** for AI
4. **Working integrations** with external APIs
5. **Quality assets** (icons, etc.)

---

## What to Extract

### 1. Content Script Selectors (CRITICAL)

**Location to check:** Look in content scripts, scrapers, or page extractors

**What I need:**
```javascript
// Find the ACTUAL working CSS selectors for:

// GeckoTerminal:
// - How to detect if we're on a pair page vs list page
// - Selectors for extracting: symbol, quote_symbol, price, volume, liquidity, price changes
// - Selectors for token list items

// DexScreener:
// - URL pattern detection
// - Selectors for extracting pair data
// - Selectors for list data
```

**Output format:**
For each selector, provide:
- The CSS selector or data attribute
- What it extracts
- Whether it's stable (data-* attributes preferred)
- Example HTML context if available

---

### 2. OpenAI Prompts (CRITICAL)

**Location to check:** Services, controllers, or AI integration files

**What I need:**
```
// Find the ACTUAL working prompts for:

1. Token List Analysis
   - Prompt template for analyzing multiple tokens
   - Expected input format
   - Desired output structure

2. Single Pair Deep Analysis
   - Prompt template for individual token analysis
   - What data gets included in the prompt
   - How results are structured

3. AI Chat
   - System prompt for the chatbot
   - How context is maintained
   - Session management approach
```

**Output format:**
- Full prompt templates (with placeholders marked clearly)
- Input data structure expected
- Output format/schema
- Any temperature/token settings that work well

---

### 3. External API Integration Patterns

**Location to check:** API clients, services, or HTTP wrappers

**What I need:**

**GeckoTerminal API:**
```
- Base URL and version
- Endpoint patterns used
- Headers required
- Rate limiting strategy
- Response parsing logic
- Error handling patterns
```

**DexScreener API:**
```
- Base URL
- Endpoint patterns
- Any authentication needed
- Response structure
- Retry logic that works
```

**OpenAI API:**
```
- Model(s) used
- Token limits
- Structured output patterns
- Error handling
- Cost optimization tricks
```

**Output format:**
- Working endpoint URLs
- Request/response examples
- Headers and auth patterns
- Error handling code that works

---

### 4. Utility Functions (NICE TO HAVE)

**Location to check:** helpers, utils, lib directories

**What I need:**
```
// Find reusable utilities like:

- Price formatting functions
- Number abbreviation (1M, 1K, etc.)
- Percentage calculations
- Date/time formatters
- Token address validation
- Chain ID mapping/normalization
```

**Output format:**
- Self-contained functions
- No dependencies on v1 architecture
- Clear input/output examples
- Unit tests if they exist

---

### 5. Extension Manifest & Config (NICE TO HAVE)

**Location to check:** Extension manifest.json, configs

**What I need:**
```
- Any special permissions needed that we might have missed
- Content Security Policy settings
- Host permissions that work
- Any background script patterns
- Web accessible resources configuration
```

**Output format:**
- Relevant manifest.json sections
- CSP configurations
- Explanation of why each is needed

---

### 6. Icons & Assets (IF BETTER THAN PLACEHOLDERS)

**Location to check:** public/icons, assets, images

**What I need:**
```
- High-quality extension icons (16, 32, 48, 128px)
- Any SVG icons used in the UI
- Brand colors/design tokens
```

**Output format:**
- File paths to quality assets
- Recommended if better than v2 placeholders
- Design system notes if documented

---

### 7. P&L Calculation Logic (CRITICAL FOR ACCURACY)

**Location to check:** Purchase tracking, position calculation

**What I need:**
```
// The EXACT logic for:

- Calculating average buy price (FIFO, LIFO, or weighted average?)
- Current position calculation
- P&L calculation (realized vs unrealized)
- Handling sells and partial positions
- Edge cases (e.g., selling more than bought)
```

**Output format:**
- The complete calculation logic
- Test cases that prove it works
- Any edge cases handled
- Formula explanations

---

### 8. ActionCable/WebSocket Patterns (IF IMPLEMENTED)

**Location to check:** Channels, cable connections, real-time updates

**What I need:**
```
- How connection authentication works
- Channel subscription patterns
- Reconnection logic
- Message format
- Error handling
```

**Output format:**
- Working client-side code
- Server-side channel code (if clean)
- Connection establishment pattern
- Heartbeat/keepalive logic

---

## What NOT to Extract

❌ **Do NOT extract:**
- Database models (v2 has better associations)
- Controllers (v2 has proper API structure)
- Routes (v2 has clean routing)
- Old service classes (v2 has separation of concerns)
- Views (except maybe styles/design patterns)
- Configuration files (v2 is environment-based)
- Tightly coupled code
- Monolithic classes

---

## Output Format

Create a structured document like this:

```markdown
# DexIQ v1 Extraction Results

## 1. Content Script Selectors

### GeckoTerminal - Pair Page
**File:** `path/to/file.js`
**Lines:** 45-67

\```javascript
// Selector for token symbol
const symbolSelector = '[data-test-id="pair-symbol"]';
const symbol = document.querySelector(symbolSelector)?.textContent;

// Selector for price
const priceSelector = '.price-display';
// etc...
\```

**Notes:**
- These selectors work as of Nov 2024
- data-test-id attributes are stable
- Price selector may need fallback

**v2 Integration:** Use in `extensions/dexiq/src/content/index.ts` in `extractGeckoTerminalPairData()`

---

### GeckoTerminal - Token List
**File:** `path/to/file.js`
**Lines:** 89-120

\```javascript
// Find all token rows
const tokenRows = document.querySelectorAll('[data-component="token-row"]');
// etc...
\```

**Notes:** Works on list pages only

**v2 Integration:** Use in `extractGeckoTerminalListData()`

---

## 2. OpenAI Prompts

### Token Pair Analysis Prompt
**File:** `path/to/service.rb`
**Lines:** 34-89

\```
System: You are a cryptocurrency analyst specializing in DeFi tokens...

Context:
Token: #{symbol}/#{quote_symbol}
Current Price: #{price}
24h Volume: #{volume}
[etc...]

Task: Provide a concise analysis covering...
\```

**Notes:**
- GPT-4 with temp 0.7 works best
- Max tokens: 2000
- Structured output using JSON mode

**v2 Integration:** Use in `app/services/analysis/token_pair_analysis_service.rb` method `build_ai_prompt`

---

[Continue for each category...]
```

---

## Validation Questions

For each piece of code you extract, ask:

1. **Does this work?** - Is it tested and proven?
2. **Is it standalone?** - Can it be used without v1 architecture?
3. **Is it better than v2?** - Does v2 already have a better implementation?
4. **Is it documented?** - Can I understand what it does?
5. **Is it current?** - Does it work with current API versions?

If you answer "no" to any of these, don't extract it.

---

## Priority Order

**DO THESE FIRST (Critical):**
1. Content script selectors
2. OpenAI prompts
3. P&L calculation logic
4. External API patterns

**DO THESE SECOND (Important):**
5. Utility functions
6. ActionCable patterns
7. Manifest configurations

**DO THESE LAST (Nice to have):**
8. Icons/assets (only if significantly better)
9. Design patterns
10. Performance optimizations

---

## Final Notes

- Be selective - quality over quantity
- Include working code only
- Add context and integration notes
- Flag anything that might be outdated
- Highlight edge cases that are handled

When done, provide the extraction document so I can review and integrate the valuable pieces into v2.
