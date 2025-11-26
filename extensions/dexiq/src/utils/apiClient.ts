// API client for DexIQ backend
// Handles authentication, retries, and consistent error handling

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';

interface RequestOptions extends RequestInit {
  retries?: number;
}

class ApiClient {
  private baseUrl: string;
  private authToken: string | null = null;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
    this.loadAuthToken();
  }

  private async loadAuthToken() {
    // Load from chrome.storage
    const response = await chrome.runtime.sendMessage({ type: 'GET_AUTH_TOKEN' });
    this.authToken = response.token;
  }

  async setAuthToken(token: string, expiresIn?: number) {
    this.authToken = token;
    await chrome.runtime.sendMessage({
      type: 'SAVE_AUTH_TOKEN',
      payload: { token, expiresIn }
    });
  }

  private async request<T>(
    endpoint: string,
    options: RequestOptions = {}
  ): Promise<T> {
    const { retries = 2, ...fetchOptions } = options;

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(fetchOptions.headers as Record<string, string>),
    };

    // Add auth headers if available
    if (this.authToken) {
      // TODO: Adjust based on your auth strategy (JWT, Devise Token Auth, etc.)
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }

    const url = `${this.baseUrl}${endpoint}`;

    try {
      const response = await fetch(url, {
        ...fetchOptions,
        headers,
      });

      if (!response.ok) {
        const error = await response.json().catch(() => ({ message: response.statusText }));
        throw new Error(error.message || `Request failed: ${response.status}`);
      }

      return await response.json();
    } catch (error) {
      if (retries > 0) {
        // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, 1000 * (3 - retries)));
        return this.request(endpoint, { ...options, retries: retries - 1 });
      }
      throw error;
    }
  }

  // Token endpoints
  async createToken(data: {
    chain_id: string;
    pool_address: string;
    symbol?: string;
    quote_symbol?: string;
    token_url?: string;
  }) {
    return this.request('/api/v1/tokens', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async getToken(id: number) {
    return this.request(`/api/v1/tokens/${id}`);
  }

  async getTokenStatus(id: number) {
    return this.request(`/api/v1/tokens/${id}/status`);
  }

  async analyzePair(id: number, data: any) {
    return this.request(`/api/v1/tokens/${id}/analyse_pair`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async analyzeTokenList(tokens: any[]) {
    return this.request('/api/v1/analyse_tokens', {
      method: 'POST',
      body: JSON.stringify({ tokens }),
    });
  }

  async getPurchases(tokenId: number) {
    return this.request(`/api/v1/tokens/${tokenId}/purchases`);
  }

  async createPurchase(tokenId: number, purchase: any) {
    return this.request(`/api/v1/tokens/${tokenId}/purchases`, {
      method: 'POST',
      body: JSON.stringify({ purchase }),
    });
  }

  async chatWithAI(tokenId: number, data: any) {
    return this.request(`/api/v1/tokens/${tokenId}/chat_with_ai`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}

export const apiClient = new ApiClient(API_BASE_URL);
