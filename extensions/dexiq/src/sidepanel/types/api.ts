// API types for DexIQ extension

export interface PageData {
  pageType: 'pair' | 'list' | 'unknown';
  site: 'geckoterminal' | 'dexscreener' | 'unknown';
  chainId?: string;
  poolAddress?: string;
  symbol?: string;
  quoteSymbol?: string;
  tokenUrl?: string;
  tokens?: TokenListItem[];
}

export interface TokenListItem {
  tokenName: string;
  price: number;
  volume: number;
  change5m?: number;
  change1h?: number;
  change6h?: number;
  change24h?: number;
  liquidity: number;
}

export interface ApiResponse<T> {
  status: 'ok' | 'error';
  message?: string;
  data?: T;
  errors?: string[];
}

export interface Token {
  id: number;
  chain_id: string;
  pool_address: string;
  symbol: string;
  quote_symbol: string;
  token_url: string;
  created_at: string;
  updated_at: string;
}

export interface TokenAnalysis {
  assistant: string;
  insights: string[];
  structured_insights: any[];
  details: Record<string, any>;
  timestamp: string;
}

export interface Purchase {
  id: number;
  transaction_type: 'buy' | 'sell';
  amount: number;
  price_per_token: number;
  total_value: number;
  transaction_hash?: string;
  notes?: string;
  created_at: string;
}

export interface Position {
  total_bought: number;
  total_sold: number;
  current_amount: number;
  average_buy_price: number;
  total_invested: number;
}

export interface PnL {
  current_price: number;
  current_value: number;
  pnl_amount: number;
  pnl_percent: number;
}
