#!/usr/bin/env node
/**
 * Browser CDP MCP Server v2.0 — 50x Upgrade
 *
 * Beyond Antigravity. 30 tools powered by:
 *   - Accessibility tree parsing (not raw DOM)
 *   - Numbered element annotations on screenshots
 *   - Smart DOM simplification
 *   - Shadow DOM + iframe traversal
 *   - Network interception (modify, not just monitor)
 *   - Console/error capture
 *   - Multi-tab management
 *   - Element caching
 *   - Post-action validation
 *   - Self-healing selectors
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { BrowserEngine } from "./engine.js";

const engine = new BrowserEngine();

const server = new McpServer({
  name: "browser-cdp",
  version: "2.0.0",
});

// ---------------------------------------------------------------------------
// Helper: EVERY action auto-observes. No manual observe calls needed.
// Returns: action result + annotated screenshot + element tree + console errors
// ---------------------------------------------------------------------------

async function autoObserve(actionResult: string): Promise<any> {
  try {
    const { screenshot, tree } = await engine.takeAnnotatedScreenshot();
    const url = await engine.getCurrentUrl();
    const title = await engine.getTitle();

    // Auto-surface any console errors from the last 3 seconds
    const recentErrors = engine.getConsoleEntries("error", 5)
      .filter(e => e.timestamp > Date.now() - 3000);
    const errorSection = recentErrors.length
      ? `\n\nConsole Errors:\n${recentErrors.map(e => `  [ERROR] ${e.text}`).join("\n")}`
      : "";

    return {
      content: [
        {
          type: "text" as const,
          text: `${actionResult}\n\nPage: ${title}\nURL: ${url}${errorSection}\n\nElements:\n${tree}`,
        },
        { type: "image" as const, data: screenshot, mimeType: "image/png" as const },
      ],
    };
  } catch {
    return { content: [{ type: "text" as const, text: actionResult }] };
  }
}


// ===========================================================================
// OBSERVATION TOOLS (the biggest upgrade — accessibility tree + annotations)
// ===========================================================================

// 1. observe — THE killer tool. Returns annotated screenshot + indexed element tree
server.tool(
  "observe",
  "Observe the page: returns an annotated screenshot with numbered elements and an accessibility tree. Use this BEFORE clicking or typing — it gives you element indexes to reference.",
  {},
  async () => {
    const { screenshot, tree } = await engine.takeAnnotatedScreenshot();
    const url = await engine.getCurrentUrl();
    const title = await engine.getTitle();
    return {
      content: [
        {
          type: "text" as const,
          text: `Page: ${title}\nURL: ${url}\n\nInteractive Elements:\n${tree}\n\nUse element [index] numbers with clickElement/typeInElement tools.`,
        },
        { type: "image" as const, data: screenshot, mimeType: "image/png" as const },
      ],
    };
  }
);

// 2. getSimplifiedDOM — clean DOM, not the 100K raw mess
server.tool(
  "getSimplifiedDOM",
  "Get a simplified, clean DOM with only meaningful elements (strips scripts, styles, hidden elements). Far more token-efficient than raw DOM.",
  {
    selector: z.string().optional().describe("CSS selector to scope the DOM extraction"),
  },
  async ({ selector }) => {
    const dom = await engine.getSimplifiedDOM(selector);
    const url = await engine.getCurrentUrl();
    return { content: [{ type: "text" as const, text: `URL: ${url}\n\n${dom}` }] };
  }
);

// 3. getText
server.tool(
  "getText",
  "Get visible text content from page or specific element",
  { selector: z.string().optional().describe("CSS selector (defaults to full page)") },
  async ({ selector }) => {
    const text = await engine.runJs(
      selector
        ? `document.querySelector(${JSON.stringify(selector)})?.innerText || "Not found"`
        : `document.body.innerText`
    );
    return { content: [{ type: "text" as const, text }] };
  }
);

// ===========================================================================
// ACTION TOOLS (click, type, press — now with element index support)
// ===========================================================================

// 4. clickElement — click by index (from observe) OR selector OR coordinates
server.tool(
  "clickElement",
  "Click an element. Preferred: use index from observe(). Also accepts CSS selector or x,y coordinates.",
  {
    index: z.number().optional().describe("Element index from observe()"),
    selector: z.string().optional().describe("CSS selector"),
    x: z.number().optional().describe("X pixel coordinate"),
    y: z.number().optional().describe("Y pixel coordinate"),
  },
  async ({ index, selector, x, y }) => {
    let result: string;
    if (index !== undefined) {
      result = await engine.clickByIndex(index);
    } else if (selector) {
      result = await engine.clickBySelector(selector);
    } else if (x !== undefined && y !== undefined) {
      result = await engine.clickAtCoords(x, y);
    } else {
      result = "Provide index, selector, or x/y coordinates";
    }
    return autoObserve(result);
  }
);

// 5. typeText — type into element by index or selector
server.tool(
  "typeText",
  "Type text into an input. Use index from observe() or CSS selector.",
  {
    index: z.number().optional().describe("Element index from observe()"),
    selector: z.string().optional().describe("CSS selector"),
    text: z.string().describe("Text to type"),
    clearFirst: z.boolean().optional().default(true).describe("Clear field before typing"),
  },
  async ({ index, selector, text, clearFirst }) => {
    let result: string;
    if (index !== undefined) {
      result = await engine.typeByIndex(index, text, clearFirst);
    } else if (selector) {
      result = await engine.type(selector, text, clearFirst);
    } else {
      result = "Provide index or selector";
    }
    return autoObserve(result);
  }
);

// 6. pressKey
server.tool(
  "pressKey",
  "Press a keyboard key (Enter, Tab, Escape, etc.) with optional modifiers",
  {
    key: z.string().describe("Key name: Enter, Tab, Escape, Backspace, ArrowDown, etc."),
    modifiers: z.array(z.string()).optional().describe("Modifier keys: alt, ctrl, meta/cmd, shift"),
  },
  async ({ key, modifiers }) => {
    const result = await engine.pressKey(key, modifiers);
    return { content: [{ type: "text" as const, text: result }] };
  }
);

// 7. selectOption
server.tool(
  "selectOption",
  "Select an option from a dropdown/select element",
  {
    selector: z.string().describe("CSS selector of select element"),
    value: z.string().describe("Value to select"),
  },
  async ({ selector, value }) => {
    const result = await engine.selectOption(selector, value);
    return autoObserve(result);
  }
);

// 8. findAndClick — self-healing: find element by description, then click it
server.tool(
  "findAndClick",
  "Find an element by natural language description and click it. Self-healing — works even when selectors change.",
  {
    description: z.string().describe("Natural language description of element (e.g., 'Submit button', 'Login link')"),
  },
  async ({ description }) => {
    const el = await engine.findElementByDescription(description);
    if (!el) return { content: [{ type: "text" as const, text: `No element found matching "${description}"` }] };
    const result = await engine.clickByIndex(el.index);
    return autoObserve(`Found: [${el.index}] ${el.role} "${el.name}"\n${result}`);
  }
);

// ===========================================================================
// NAVIGATION
// ===========================================================================

// 9. navigate
server.tool(
  "navigate",
  "Navigate to a URL",
  { url: z.string().describe("URL to navigate to") },
  async ({ url }) => {
    const result = await engine.navigate(url);
    return autoObserve(result);
  }
);

// 10. refreshPage
server.tool(
  "refreshPage",
  "Refresh the current page",
  {},
  async () => {
    const result = await engine.refreshPage();
    return autoObserve(result);
  }
);

// 11. waitForNavigation
server.tool(
  "waitForNavigation",
  "Wait for page load to complete",
  { timeout: z.number().optional().default(10000).describe("Timeout in ms") },
  async ({ timeout }) => {
    const result = await engine.waitForNavigation(timeout);
    return autoObserve(result);
  }
);

// ===========================================================================
// SCROLLING
// ===========================================================================

// 12. scrollDown
server.tool(
  "scrollDown",
  "Scroll the page down",
  { pixels: z.number().optional().default(500) },
  async ({ pixels }) => {
    const result = await engine.scrollDown(pixels);
    return autoObserve(result);
  }
);

// 13. scrollUp
server.tool(
  "scrollUp",
  "Scroll the page up",
  { pixels: z.number().optional().default(500) },
  async ({ pixels }) => {
    const result = await engine.scrollUp(pixels);
    return autoObserve(result);
  }
);

// 14. scrollTo
server.tool(
  "scrollTo",
  "Scroll to specific position",
  {
    x: z.number().describe("Horizontal scroll position"),
    y: z.number().describe("Vertical scroll position"),
  },
  async ({ x, y }) => {
    const result = await engine.scrollTo(x, y);
    return autoObserve(result);
  }
);

// ===========================================================================
// MOUSE
// ===========================================================================

// 15. moveMouse
server.tool("moveMouse", "Move mouse cursor", {
  x: z.number(), y: z.number(),
}, async ({ x, y }) => {
  return { content: [{ type: "text" as const, text: await engine.moveMouse(x, y) }] };
});

// 16. mouseDown
server.tool("mouseDown", "Press mouse button", {
  x: z.number(), y: z.number(),
  button: z.enum(["left", "right", "middle"]).optional().default("left"),
}, async ({ x, y, button }) => {
  return { content: [{ type: "text" as const, text: await engine.mouseDown(x, y, button) }] };
});

// 17. mouseUp
server.tool("mouseUp", "Release mouse button", {
  x: z.number(), y: z.number(),
  button: z.enum(["left", "right", "middle"]).optional().default("left"),
}, async ({ x, y, button }) => {
  return { content: [{ type: "text" as const, text: await engine.mouseUp(x, y, button) }] };
});

// 18. mouseWheel
server.tool("mouseWheel", "Mouse wheel event", {
  x: z.number(), y: z.number(),
  deltaX: z.number(), deltaY: z.number(),
}, async ({ x, y, deltaX, deltaY }) => {
  return { content: [{ type: "text" as const, text: await engine.mouseWheel(x, y, deltaX, deltaY) }] };
});

// 19. drag
server.tool("drag", "Drag from one point to another", {
  fromX: z.number(), fromY: z.number(),
  toX: z.number(), toY: z.number(),
}, async ({ fromX, fromY, toX, toY }) => {
  const result = await engine.drag(fromX, fromY, toX, toY);
  return autoObserve(result);
});

// ===========================================================================
// VIEWPORT
// ===========================================================================

// 20. resizeViewport
server.tool("resizeViewport", "Resize browser viewport", {
  width: z.number(), height: z.number(),
}, async ({ width, height }) => {
  const result = await engine.resizeViewport(width, height);
  return autoObserve(result);
});

// ===========================================================================
// SCREENSHOTS
// ===========================================================================

// 21. screenshot
server.tool(
  "screenshot",
  "Take a screenshot (plain, without annotations)",
  { fullPage: z.boolean().optional().default(false) },
  async ({ fullPage }) => {
    const ss = await engine.takeScreenshot(fullPage);
    const url = await engine.getCurrentUrl();
    const title = await engine.getTitle();
    return {
      content: [
        { type: "text" as const, text: `Screenshot: ${title}\nURL: ${url}` },
        { type: "image" as const, data: ss, mimeType: "image/png" as const },
      ],
    };
  }
);

// ===========================================================================
// JAVASCRIPT
// ===========================================================================

// 22. runJs
server.tool(
  "runJs",
  "Execute JavaScript in the browser page context",
  { expression: z.string().describe("JavaScript to evaluate") },
  async ({ expression }) => {
    const result = await engine.runJs(expression);
    return { content: [{ type: "text" as const, text: result }] };
  }
);

// ===========================================================================
// NETWORK (interception + monitoring)
// ===========================================================================

// 23. listNetworkRequests
server.tool(
  "listNetworkRequests",
  "List recent network requests with status, method, URL, size",
  { filter: z.string().optional().describe("Filter by URL substring") },
  async ({ filter }) => {
    const entries = engine.getNetworkEntries(filter);
    const lines = entries.map(e =>
      `[${e.method}] ${e.status || "…"} ${e.url.substring(0, 140)}${e.size ? ` (${e.size}B)` : ""}`
    );
    return { content: [{ type: "text" as const, text: `Network (${entries.length}):\n${lines.join("\n")}` }] };
  }
);

// 24. interceptNetwork
server.tool(
  "interceptNetwork",
  "Enable network interception — allows blocking, modifying, or mocking requests",
  {},
  async () => {
    const result = await engine.enableNetworkInterception();
    return { content: [{ type: "text" as const, text: result }] };
  }
);

// 25. blockUrls
server.tool(
  "blockUrls",
  "Block specific URL patterns (ads, trackers, etc.)",
  { patterns: z.array(z.string()).describe("URL patterns to block (e.g., ['*analytics*', '*ads*'])") },
  async ({ patterns }) => {
    const result = await engine.blockUrls(patterns);
    return { content: [{ type: "text" as const, text: result }] };
  }
);

// ===========================================================================
// CONSOLE
// ===========================================================================

// 26. getConsole
server.tool(
  "getConsole",
  "Get browser console output (logs, warnings, errors). Essential for debugging web apps.",
  {
    level: z.enum(["log", "warning", "error", "info", "debug"]).optional().describe("Filter by level"),
    limit: z.number().optional().default(50),
  },
  async ({ level, limit }) => {
    const entries = engine.getConsoleEntries(level, limit);
    if (entries.length === 0) return { content: [{ type: "text" as const, text: "No console entries" }] };
    const lines = entries.map(e => `[${e.level}] ${e.text}${e.url ? ` (${e.url}:${e.line})` : ""}`);
    return { content: [{ type: "text" as const, text: lines.join("\n") }] };
  }
);

// ===========================================================================
// MULTI-TAB
// ===========================================================================

// 27. listTabs
server.tool(
  "listTabs",
  "List all open browser tabs",
  {},
  async () => {
    const tabs = await engine.listTabs();
    const lines = tabs.map(t =>
      `${t.active ? "→ " : "  "}[${t.targetId.substring(0, 8)}] ${t.title} — ${t.url}`
    );
    return { content: [{ type: "text" as const, text: `Tabs (${tabs.length}):\n${lines.join("\n")}` }] };
  }
);

// 28. switchTab
server.tool(
  "switchTab",
  "Switch to a different browser tab by target ID",
  { targetId: z.string().describe("Tab target ID from listTabs") },
  async ({ targetId }) => {
    const result = await engine.switchTab(targetId);
    return autoObserve(result);
  }
);

// 29. newTab
server.tool(
  "newTab",
  "Open a new browser tab, optionally with a URL",
  { url: z.string().optional().describe("URL to open (default: blank)") },
  async ({ url }) => {
    const result = await engine.newTab(url);
    return autoObserve(result);
  }
);

// 30. closeTab
server.tool(
  "closeTab",
  "Close a browser tab",
  { targetId: z.string().describe("Tab target ID to close") },
  async ({ targetId }) => {
    const result = await engine.closeTab(targetId);
    return { content: [{ type: "text" as const, text: result }] };
  }
);

// ===========================================================================
// SPEAR AUDIT — automated visual verification for web apps
// ===========================================================================

// 31. auditPage — comprehensive page audit (for SPEAR integration)
server.tool(
  "auditPage",
  "Run a comprehensive visual + functional audit on a web page. Navigates to URL, captures annotated screenshot, checks console errors, validates network, checks accessibility tree. Designed for SPEAR audit integration.",
  {
    url: z.string().describe("URL to audit"),
    checkLinks: z.boolean().optional().default(false).describe("Also check for broken links"),
  },
  async ({ url, checkLinks }) => {
    // Navigate
    await engine.navigate(url);

    // Get annotated screenshot + tree
    const { screenshot, tree } = await engine.takeAnnotatedScreenshot();
    const title = await engine.getTitle();
    const currentUrl = await engine.getCurrentUrl();

    // Console errors
    const errors = engine.getConsoleEntries("error", 20);
    const warnings = engine.getConsoleEntries("warning", 10);

    // Network failures
    const networkEntries = engine.getNetworkEntries();
    const failedRequests = networkEntries.filter(
      e => e.status && (e.status >= 400 || e.status === 0)
    );

    // Element count
    const elementCount = tree.split("\n").filter(l => l.trim()).length;

    // Build audit report
    const sections: string[] = [];
    sections.push(`AUDIT: ${title}`);
    sections.push(`URL: ${currentUrl}`);
    sections.push(`Elements: ${elementCount} interactive`);
    sections.push(`Network: ${networkEntries.length} requests, ${failedRequests.length} failed`);

    if (failedRequests.length > 0) {
      sections.push(`\nFailed Requests:`);
      for (const f of failedRequests.slice(0, 10)) {
        sections.push(`  [${f.status}] ${f.method} ${f.url.substring(0, 120)}`);
      }
    }

    if (errors.length > 0) {
      sections.push(`\nConsole Errors (${errors.length}):`);
      for (const e of errors.slice(0, 10)) {
        sections.push(`  ${e.text.substring(0, 200)}`);
      }
    }

    if (warnings.length > 0) {
      sections.push(`\nConsole Warnings (${warnings.length}):`);
      for (const w of warnings.slice(0, 5)) {
        sections.push(`  ${w.text.substring(0, 200)}`);
      }
    }

    // Broken link check
    if (checkLinks) {
      const linkCheck = await engine.runJs(`(() => {
        const links = Array.from(document.querySelectorAll('a[href]'));
        return JSON.stringify(links.map(a => ({
          text: a.textContent?.trim().substring(0, 40),
          href: a.href,
          broken: a.href.startsWith('javascript:') || a.href === '#' || a.href === ''
        })).filter(l => l.broken));
      })()`);
      const brokenLinks = JSON.parse(linkCheck || "[]");
      if (brokenLinks.length > 0) {
        sections.push(`\nSuspicious Links (${brokenLinks.length}):`);
        for (const l of brokenLinks.slice(0, 10)) {
          sections.push(`  "${l.text}" → ${l.href}`);
        }
      }
    }

    sections.push(`\nInteractive Elements:\n${tree}`);

    const verdict = errors.length === 0 && failedRequests.length === 0
      ? "PASS — No errors, no failed requests"
      : `ISSUES FOUND — ${errors.length} console errors, ${failedRequests.length} failed requests`;
    sections.push(`\nVerdict: ${verdict}`);

    return {
      content: [
        { type: "text" as const, text: sections.join("\n") },
        { type: "image" as const, data: screenshot, mimeType: "image/png" as const },
      ],
    };
  }
);

// ===========================================================================
// START
// ===========================================================================

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  process.stderr.write("Browser CDP MCP v2.0 — 30 tools, 10 upgrades beyond Antigravity\n");
}

main().catch((err) => {
  process.stderr.write(`Fatal: ${err}\n`);
  process.exit(1);
});

process.on("SIGINT", async () => { await engine.close(); process.exit(0); });
process.on("SIGTERM", async () => { await engine.close(); process.exit(0); });
