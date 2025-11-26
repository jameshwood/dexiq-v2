// Page detection utilities from v1 (battle-tested)

export function getActiveSite(): string {
  const hostname = window.location.hostname;
  if (hostname.includes("geckoterminal.com")) return "geckoterminal";
  if (hostname.includes("dexscreener.com")) return "dexscreener";
  return "unknown";
}

export function isOnPairPage(): boolean {
  const path = window.location.pathname;
  const geckoPattern = /^\/[^/]+\/pools\/[^/]+$/;
  return window.location.hostname.includes("geckoterminal.com") && geckoPattern.test(path);
}

export function getPoolAddress(): string | null {
  const segments = window.location.pathname.split('/');
  return segments[3] || null; // geckoterminal.com/[chain]/pools/[ADDRESS]
}

export function getChainId(): string {
  return window.location.pathname.split('/')[1];
}
