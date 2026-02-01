import { fetch, setGlobalDispatcher, ProxyAgent } from 'undici';

const proxyUrl = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
console.log("Proxy URL:", proxyUrl);
console.log("NODE_TLS_REJECT_UNAUTHORIZED:", process.env.NODE_TLS_REJECT_UNAUTHORIZED);

if (proxyUrl) {
  try {
    console.log("Configuring ProxyAgent...");
    const agent = new ProxyAgent({
      uri: proxyUrl,
      connect: {
        rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED !== "0",
        timeout: 10000, // Explicit timeout
      },
    });
    setGlobalDispatcher(agent);
  } catch (err) {
    console.error("Failed to setup proxy agent:", err);
  }
}

console.log("Attempting fetch to oauth2.googleapis.com...");

try {
  // Try a simple GET first (will probably be 404 or 405, but proves connectivity)
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    body: new URLSearchParams({ grant_type: 'authorization_code' }) // dummy body
  });
  console.log("Response Status:", res.status);
  console.log("Response Text (partial):", (await res.text()).slice(0, 100));
  console.log("SUCCESS: Connection established.");
} catch (error) {
  console.error("FAILURE: Fetch failed.");
  console.error(error);
  if (error.cause) {
    console.error("Cause:", error.cause);
  }
}
