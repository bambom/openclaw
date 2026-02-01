#!/usr/bin/env node
import "dotenv/config";
import { ProxyAgent, setGlobalDispatcher } from "undici";
import { spawn } from "node:child_process";
import path from "node:path";
import process from "node:process";

// Configure global fetch proxy if environment variables are set
const proxyUrl = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
if (proxyUrl) {
  // Enforce proxy on standard environment variables for other libraries
  process.env.HTTPS_PROXY = proxyUrl;
  process.env.HTTP_PROXY = proxyUrl;

  // Set default NO_PROXY to exclude domestic services and local addresses
  if (!process.env.NO_PROXY) {
    process.env.NO_PROXY = "localhost,127.0.0.1,::1,.feishu.cn,.larksuite.com";
  }

  // Only use undici ProxyAgent for http/https, as it doesn't support socks5://
  if (proxyUrl.startsWith("http:") || proxyUrl.startsWith("https:")) {
    try {
      const proxyAgent = new ProxyAgent({
        uri: proxyUrl,
        connect: {
          rejectUnauthorized: process.env.NODE_TLS_REJECT_UNAUTHORIZED !== "0",
        },
      });
      setGlobalDispatcher(proxyAgent);
    } catch {
      // Silently ignore proxy initialization errors to avoid crashing on startup
    }
  }
}

import { applyCliProfileEnv, parseCliProfileArgs } from "./cli/profile.js";
import { isTruthyEnvValue, normalizeEnv } from "./infra/env.js";
import { installProcessWarningFilter } from "./infra/warnings.js";
import { attachChildProcessBridge } from "./process/child-process-bridge.js";

process.title = "openclaw";
installProcessWarningFilter();
normalizeEnv();

if (process.argv.includes("--no-color")) {
  process.env.NO_COLOR = "1";
  process.env.FORCE_COLOR = "0";
}

const EXPERIMENTAL_WARNING_FLAG = "--disable-warning=ExperimentalWarning";

function hasExperimentalWarningSuppressed(nodeOptions: string): boolean {
  if (!nodeOptions) {
    return false;
  }
  return nodeOptions.includes(EXPERIMENTAL_WARNING_FLAG) || nodeOptions.includes("--no-warnings");
}

function ensureExperimentalWarningSuppressed(): boolean {
  if (isTruthyEnvValue(process.env.OPENCLAW_NO_RESPAWN)) {
    return false;
  }
  if (isTruthyEnvValue(process.env.OPENCLAW_NODE_OPTIONS_READY)) {
    return false;
  }
  const nodeOptions = process.env.NODE_OPTIONS ?? "";
  if (hasExperimentalWarningSuppressed(nodeOptions)) {
    return false;
  }

  process.env.OPENCLAW_NODE_OPTIONS_READY = "1";
  process.env.NODE_OPTIONS = `${nodeOptions} ${EXPERIMENTAL_WARNING_FLAG}`.trim();

  const child = spawn(process.execPath, [...process.execArgv, ...process.argv.slice(1)], {
    stdio: "inherit",
    env: process.env,
  });

  attachChildProcessBridge(child);

  child.once("exit", (code, signal) => {
    if (signal) {
      process.exitCode = 1;
      return;
    }
    process.exit(code ?? 1);
  });

  child.once("error", (error) => {
    console.error(
      "[openclaw] Failed to respawn CLI:",
      error instanceof Error ? (error.stack ?? error.message) : error,
    );
    process.exit(1);
  });

  // Parent must not continue running the CLI.
  return true;
}

function normalizeWindowsArgv(argv: string[]): string[] {
  if (process.platform !== "win32") {
    return argv;
  }
  if (argv.length < 2) {
    return argv;
  }
  const stripControlChars = (value: string): string => {
    let out = "";
    for (let i = 0; i < value.length; i += 1) {
      const code = value.charCodeAt(i);
      if (code >= 32 && code !== 127) {
        out += value[i];
      }
    }
    return out;
  };
  const normalizeArg = (value: string): string =>
    stripControlChars(value)
      .replace(/^['"]+|['"]+$/g, "")
      .trim();
  const normalizeCandidate = (value: string): string =>
    normalizeArg(value).replace(/^\\\\\\?\\/, "");
  const execPath = normalizeCandidate(process.execPath);
  const execPathLower = execPath.toLowerCase();
  const execBase = path.basename(execPath).toLowerCase();
  const isExecPath = (value: string | undefined): boolean => {
    if (!value) {
      return false;
    }
    const lower = normalizeCandidate(value).toLowerCase();
    return (
      lower === execPathLower ||
      path.basename(lower) === execBase ||
      lower.endsWith("\\node.exe") ||
      lower.endsWith("/node.exe") ||
      lower.includes("node.exe")
    );
  };
  const next = [...argv];
  for (let i = 1; i <= 3 && i < next.length; ) {
    if (isExecPath(next[i])) {
      next.splice(i, 1);
      continue;
    }
    i += 1;
  }
  const filtered = next.filter((arg, index) => index === 0 || !isExecPath(arg));
  if (filtered.length < 3) {
    return filtered;
  }
  const cleaned = [...filtered];
  for (let i = 2; i < cleaned.length; ) {
    const arg = cleaned[i];
    if (!arg || arg.startsWith("-")) {
      i += 1;
      continue;
    }
    if (isExecPath(arg)) {
      cleaned.splice(i, 1);
      continue;
    }
    break;
  }
  return cleaned;
}

process.argv = normalizeWindowsArgv(process.argv);

if (!ensureExperimentalWarningSuppressed()) {
  const parsed = parseCliProfileArgs(process.argv);
  if (!parsed.ok) {
    // Keep it simple; Commander will handle rich help/errors after we strip flags.
    console.error(`[openclaw] ${parsed.error}`);
    process.exit(2);
  }

  if (parsed.profile) {
    applyCliProfileEnv({ profile: parsed.profile });
    // Keep Commander and ad-hoc argv checks consistent.
    process.argv = parsed.argv;
  }

  import("./cli/run-main.js")
    .then(({ runCli }) => runCli(process.argv))
    .catch((error) => {
      console.error(
        "[openclaw] Failed to start CLI:",
        error instanceof Error ? (error.stack ?? error.message) : error,
      );
      process.exitCode = 1;
    });
}
