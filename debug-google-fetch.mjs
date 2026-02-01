import { fetch, ProxyAgent } from 'undici';

console.log("OPENCLAW_GOOGLE_PROXY:", process.env.OPENCLAW_GOOGLE_PROXY);
console.log("NODE_TLS_REJECT_UNAUTHORIZED:", process.env.NODE_TLS_REJECT_UNAUTHORIZED);

const proxyUrl = process.env.OPENCLAW_GOOGLE_PROXY;
let agent;

if (proxyUrl) {
  try {
    console.log("Configuring ProxyAgent with:", proxyUrl);
    agent = new ProxyAgent({
      uri: proxyUrl,
      connect: {
        rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED !== "0",
        timeout: 15000,
      },
    });
  } catch (err) {
    console.error("Failed to create agent:", err);
  }
} else {
  console.log("No OPENCLAW_GOOGLE_PROXY set. Using direct connection.");
}

async function testFetch(url) {
  console.log(`Fetching ${url}...`);
  try {
    const res = await fetch(url, {
      method: 'POST', // Some endpoints are POST
      dispatcher: agent
    });
    console.log(`Success! Status: ${res.status}`);
  } catch (err) {
    console.error(`Failed to fetch ${url}`);
    console.error(err);
    if (err.cause) console.error("Cause:", err.cause);
  }
}

// Test Token Endpoint (used in OAuth)
await testFetch('https://oauth2.googleapis.com/token');

// Test Code Assist Endpoint (used in discoverProject, where you likely timed out)
await testFetch('https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist');
