// Token types from v1 (battle-tested)

export interface PairPayload {
  site: string;
  chainId: string;
  poolAddress: string;
  symbol: string;
  quoteSymbol: string;
  tokenUrl: string;
  // Optional extracted data for immediate use
  price?: string;
  volume?: string;
  liquidity?: string;
  change5m?: string;
  change1h?: string;
  change6h?: string;
  change24h?: string;
}

export interface TokenPreview {
  source: string;
  tokenName: string;
  tokenSymbol: string;
  quoteSymbol: string;
  price: string;
  volume: string;
  change5m: string;
  change1h: string;
  change6h: string;
  change24h: string;
  liquidity: string;
  tokenUrl: string | null;
}

export interface SymbolPair {
  fullPair: string;
  symbol: string;
  quoteSymbol: string;
}
