/**
 * Browser Engine — The brain behind the CDP MCP.
 * Implements all 10 upgrades from research:
 *   1. Accessibility tree parsing
 *   2. Numbered element annotations
 *   3. Smart DOM simplification
 *   4. Shadow DOM + iframe traversal
 *   5. Network interception
 *   6. Console/error capture
 *   7. Multi-tab management
 *   8. Element caching
 *   9. Post-action validation
 *   10. Self-healing selectors
 */

import CDP from "chrome-remote-interface";
import { spawn, ChildProcess } from "child_process";
import path from "path";
import os from "os";
import fs from "fs";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface IndexedElement {
  index: number;
  role: string;
  name: string;
  value?: string;
  description?: string;
  disabled?: boolean;
  checked?: boolean;
  expanded?: boolean;
  selected?: boolean;
  required?: boolean;
  focused?: boolean;
  backendNodeId?: number;
  boundingBox?: { x: number; y: number; width: number; height: number };
  parentContext?: string;
  selector?: string;
  nodeId?: number;
  depth: number;
}

export interface NetworkEntry {
  requestId: string;
  url: string;
  method: string;
  status?: number;
  statusText?: string;
  type?: string;
  timestamp: number;
  responseHeaders?: Record<string, string>;
  requestHeaders?: Record<string, string>;
  postData?: string;
  mimeType?: string;
  size?: number;
  intercepted?: boolean;
}

export interface ConsoleEntry {
  level: string;
  text: string;
  url?: string;
  line?: number;
  timestamp: number;
}

export interface TabInfo {
  targetId: string;
  url: string;
  title: string;
  type: string;
  active: boolean;
}

interface CachedElement {
  selector: string;
  role: string;
  name: string;
  lastSeen: number;
  hitCount: number;
}

// ---------------------------------------------------------------------------
// Engine
// ---------------------------------------------------------------------------

export class BrowserEngine {
  private client: any = null;
  private chromeProcess: ChildProcess | null = null;

  // State
  private indexedElements: Map<number, IndexedElement> = new Map();
  private networkEntries: Map<string, NetworkEntry> = new Map();
  private consoleEntries: ConsoleEntry[] = [];
  private elementCache: Map<string, CachedElement> = new Map();
  private interceptRules: Map<string, (req: any) => any> = new Map();
  private activeTargetId: string | null = null;
  private nextElementIndex = 1;

  // Config
  private cdpPort: number;
  private userProfilePath: string;
  private chromeBinaryPath: string;

  constructor() {
    this.cdpPort = parseInt(process.env.BROWSER_CDP_PORT || "9222", 10);
    this.userProfilePath =
      process.env.BROWSER_USER_PROFILE_PATH ||
      path.join(os.homedir(), ".claude", "browser-cdp-profile");
    this.chromeBinaryPath =
      process.env.BROWSER_CHROME_BINARY_PATH ||
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
  }

  // =========================================================================
  // CONNECTION
  // =========================================================================

  async ensureConnected(): Promise<any> {
    if (this.client) {
      try {
        await this.client.Runtime.evaluate({ expression: "1" });
        return this.client;
      } catch {
        this.client = null;
      }
    }

    // Try existing Chrome first — connect to a specific tab (not browser-level,
    // which may be held by Antigravity or another tool)
    try {
      this.client = await this.connectToPageTarget();
      await this.setupDomains();
      return this.client;
    } catch {
      // No Chrome running or no connectable tab — launch our own
      await this.launchChrome();
      for (let i = 0; i < 30; i++) {
        await this.sleep(500);
        try {
          this.client = await this.connectToPageTarget();
          await this.setupDomains();
          return this.client;
        } catch { /* retry */ }
      }
      throw new Error(`Failed to connect to Chrome on port ${this.cdpPort}`);
    }
  }

  private async connectToPageTarget(): Promise<any> {
    // If we already have a target, try connecting to it directly
    if (this.activeTargetId) {
      try {
        return await CDP({ port: this.cdpPort, target: this.activeTargetId });
      } catch { /* target may be gone, fall through */ }
    }

    // List all targets and find a page tab
    const targets = await CDP.List({ port: this.cdpPort });
    const pageTargets = targets.filter((t: any) => t.type === "page");

    if (pageTargets.length === 0) {
      // No page tabs — try browser-level connection (will create a new tab)
      return CDP({ port: this.cdpPort });
    }

    // Connect to first available page target
    const target = pageTargets[0];
    this.activeTargetId = target.id;
    return CDP({ port: this.cdpPort, target: target.id });
  }

  private async setupDomains(): Promise<void> {
    if (!this.client) return;
    const c = this.client;

    await Promise.all([
      c.Network.enable(),
      c.Page.enable(),
      c.DOM.enable(),
      c.Runtime.enable(),
      c.Accessibility?.enable?.().catch(() => {}),
      c.Overlay?.enable?.().catch(() => {}),
    ]);

    // ---- Network tracking ----
    this.networkEntries.clear();
    c.Network.requestWillBeSent((p: any) => {
      this.networkEntries.set(p.requestId, {
        requestId: p.requestId,
        url: p.request.url,
        method: p.request.method,
        type: p.type,
        timestamp: p.timestamp,
        requestHeaders: p.request.headers,
        postData: p.request.postData,
      });
    });
    c.Network.responseReceived((p: any) => {
      const e = this.networkEntries.get(p.requestId);
      if (e) {
        e.status = p.response.status;
        e.statusText = p.response.statusText;
        e.mimeType = p.response.mimeType;
        e.responseHeaders = p.response.headers;
      }
    });
    c.Network.loadingFinished?.((p: any) => {
      const e = this.networkEntries.get(p.requestId);
      if (e) e.size = p.encodedDataLength;
    });

    // ---- Console capture ----
    this.consoleEntries = [];
    c.Runtime.consoleAPICalled?.((p: any) => {
      this.consoleEntries.push({
        level: p.type,
        text: p.args?.map((a: any) => a.value ?? a.description ?? "").join(" ") || "",
        timestamp: p.timestamp,
      });
      if (this.consoleEntries.length > 200) this.consoleEntries.shift();
    });
    c.Runtime.exceptionThrown?.((p: any) => {
      this.consoleEntries.push({
        level: "error",
        text: p.exceptionDetails?.text +
          (p.exceptionDetails?.exception?.description
            ? ": " + p.exceptionDetails.exception.description
            : ""),
        url: p.exceptionDetails?.url,
        line: p.exceptionDetails?.lineNumber,
        timestamp: Date.now(),
      });
    });
  }

  private async launchChrome(): Promise<void> {
    if (!fs.existsSync(this.userProfilePath)) {
      fs.mkdirSync(this.userProfilePath, { recursive: true });
    }
    const args = [
      `--remote-debugging-port=${this.cdpPort}`,
      `--user-data-dir=${this.userProfilePath}`,
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-background-timer-throttling",
      "--disable-backgrounding-occluded-windows",
      "--disable-renderer-backgrounding",
      "--disable-features=TranslateUI",
      "--window-size=1440,900",
    ];
    this.chromeProcess = spawn(this.chromeBinaryPath, args, {
      detached: true,
      stdio: "ignore",
    });
    this.chromeProcess.unref();
  }

  // =========================================================================
  // 1. ACCESSIBILITY TREE (the biggest upgrade)
  // =========================================================================

  async getAccessibilityTree(): Promise<IndexedElement[]> {
    const c = await this.ensureConnected();
    this.indexedElements.clear();
    this.nextElementIndex = 1;

    try {
      // Try CDP Accessibility.getFullAXTree first
      const { nodes } = await c.send("Accessibility.getFullAXTree", { depth: 10 });
      return this.parseAXTree(nodes);
    } catch {
      // Fallback: build from DOM
      return this.buildTreeFromDOM();
    }
  }

  private parseAXTree(nodes: any[]): IndexedElement[] {
    const elements: IndexedElement[] = [];

    for (const node of nodes) {
      // Skip ignored/invisible nodes
      if (node.ignored) continue;

      const role = node.role?.value || "";
      const name = node.name?.value || "";

      // Only index interactive or meaningful elements
      if (!this.isActionableRole(role) && !name) continue;

      const el: IndexedElement = {
        index: this.nextElementIndex++,
        role,
        name,
        value: node.value?.value,
        description: node.description?.value,
        backendNodeId: node.backendDOMNodeId,
        depth: 0,
        disabled: this.getAXProperty(node, "disabled"),
        checked: this.getAXProperty(node, "checked"),
        expanded: this.getAXProperty(node, "expanded"),
        selected: this.getAXProperty(node, "selected"),
        required: this.getAXProperty(node, "required"),
        focused: this.getAXProperty(node, "focused"),
      };

      this.indexedElements.set(el.index, el);
      elements.push(el);
    }

    return elements;
  }

  private getAXProperty(node: any, name: string): boolean | undefined {
    const prop = node.properties?.find((p: any) => p.name === name);
    return prop?.value?.value;
  }

  private isActionableRole(role: string): boolean {
    const actionable = new Set([
      "button", "link", "textbox", "searchbox", "combobox", "listbox",
      "option", "checkbox", "radio", "switch", "slider", "spinbutton",
      "tab", "tabpanel", "menuitem", "menuitemcheckbox", "menuitemradio",
      "treeitem", "row", "cell", "columnheader", "rowheader",
      "heading", "img", "dialog", "alertdialog", "alert",
      "navigation", "main", "form", "search", "banner",
      "contentinfo", "complementary", "region", "article",
    ]);
    return actionable.has(role);
  }

  private async buildTreeFromDOM(): Promise<IndexedElement[]> {
    const c = await this.ensureConnected();
    const elements: IndexedElement[] = [];

    const { result } = await c.Runtime.evaluate({
      expression: `(() => {
        const els = [];
        const selectors = 'a,button,input,select,textarea,[role="button"],[role="link"],[role="tab"],[role="checkbox"],[role="radio"],[role="switch"],[role="combobox"],[role="menuitem"],[contenteditable="true"],details>summary,h1,h2,h3,h4,h5,h6,img[alt],[aria-label]';
        document.querySelectorAll(selectors).forEach((el, i) => {
          const rect = el.getBoundingClientRect();
          if (rect.width === 0 && rect.height === 0) return;
          if (window.getComputedStyle(el).display === 'none') return;
          if (window.getComputedStyle(el).visibility === 'hidden') return;

          const role = el.getAttribute('role') || el.tagName.toLowerCase();
          const name = el.getAttribute('aria-label')
            || el.textContent?.trim().substring(0, 80)
            || el.getAttribute('placeholder')
            || el.getAttribute('title')
            || el.getAttribute('alt')
            || '';

          els.push({
            role,
            name,
            value: el.value || '',
            disabled: el.disabled || false,
            checked: el.checked || false,
            tag: el.tagName,
            type: el.type || '',
            id: el.id,
            className: el.className?.toString?.()?.substring(0, 60) || '',
            rect: { x: rect.x, y: rect.y, width: rect.width, height: rect.height },
          });
        });
        return JSON.stringify(els);
      })()`,
      returnByValue: true,
    });

    const parsed = JSON.parse(result.value as string);
    for (const el of parsed) {
      const indexed: IndexedElement = {
        index: this.nextElementIndex++,
        role: el.role,
        name: el.name,
        value: el.value || undefined,
        disabled: el.disabled,
        checked: el.checked,
        boundingBox: el.rect,
        depth: 0,
        selector: this.buildSelector(el),
      };
      this.indexedElements.set(indexed.index, indexed);
      elements.push(indexed);
    }

    return elements;
  }

  private buildSelector(el: any): string {
    if (el.id) return `#${el.id}`;
    const tag = el.tag?.toLowerCase() || "div";
    if (el.type) return `${tag}[type="${el.type}"]`;
    if (el.name) {
      const escaped = el.name.replace(/"/g, '\\"').substring(0, 40);
      return `${tag}[aria-label="${escaped}"]`;
    }
    return tag;
  }

  // Format tree for LLM consumption
  formatTreeForLLM(elements: IndexedElement[]): string {
    const lines: string[] = [];
    for (const el of elements) {
      let line = `[${el.index}] ${el.role}`;
      if (el.name) line += ` "${el.name}"`;
      if (el.value) line += ` value="${el.value}"`;
      if (el.disabled) line += " (disabled)";
      if (el.checked) line += " (checked)";
      if (el.selected) line += " (selected)";
      if (el.expanded !== undefined) line += el.expanded ? " (expanded)" : " (collapsed)";
      if (el.focused) line += " (focused)";
      if (el.required) line += " (required)";
      lines.push(line);
    }
    return lines.join("\n");
  }

  // =========================================================================
  // 2. NUMBERED ELEMENT ANNOTATIONS ON SCREENSHOTS
  // =========================================================================

  async takeAnnotatedScreenshot(): Promise<{ screenshot: string; tree: string }> {
    const c = await this.ensureConnected();

    // Get indexed elements with bounding boxes
    const elements = await this.getAccessibilityTree();

    // Resolve bounding boxes for elements that have backendNodeId
    for (const el of elements) {
      if (el.backendNodeId && !el.boundingBox) {
        try {
          const { model } = await c.DOM.getBoxModel({ backendNodeId: el.backendNodeId });
          if (model) {
            const q = model.content;
            el.boundingBox = {
              x: q[0], y: q[1],
              width: q[2] - q[0],
              height: q[5] - q[1],
            };
          }
        } catch { /* skip */ }
      }
    }

    // Inject numbered annotations overlay via JS
    const annotations = elements
      .filter(el => el.boundingBox && el.boundingBox.width > 0)
      .map(el => ({
        index: el.index,
        x: el.boundingBox!.x,
        y: el.boundingBox!.y,
        w: el.boundingBox!.width,
        h: el.boundingBox!.height,
      }));

    await c.Runtime.evaluate({
      expression: `(() => {
        // Remove previous annotations
        document.querySelectorAll('[data-cdp-annotation]').forEach(e => e.remove());

        const annotations = ${JSON.stringify(annotations)};
        const container = document.createElement('div');
        container.setAttribute('data-cdp-annotation', 'container');
        container.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:2147483647';

        for (const a of annotations) {
          // Bounding box highlight
          const box = document.createElement('div');
          box.setAttribute('data-cdp-annotation', 'box');
          box.style.cssText = \`position:absolute;left:\${a.x}px;top:\${a.y}px;width:\${a.w}px;height:\${a.h}px;border:2px solid rgba(255,107,53,0.7);border-radius:3px;pointer-events:none\`;

          // Number label
          const label = document.createElement('div');
          label.setAttribute('data-cdp-annotation', 'label');
          label.textContent = String(a.index);
          label.style.cssText = \`position:absolute;left:\${a.x - 2}px;top:\${Math.max(0, a.y - 18)}px;background:#ff6b35;color:#fff;font:bold 11px/16px monospace;padding:0 4px;border-radius:3px;pointer-events:none;white-space:nowrap\`;

          container.appendChild(box);
          container.appendChild(label);
        }
        document.body.appendChild(container);
      })()`,
    });

    // Wait a tick for render
    await this.sleep(100);

    // Take screenshot WITH annotations visible
    const { data } = await c.Page.captureScreenshot({ format: "png" });

    // Remove annotations
    await c.Runtime.evaluate({
      expression: `document.querySelectorAll('[data-cdp-annotation]').forEach(e => e.remove())`,
    });

    return {
      screenshot: data,
      tree: this.formatTreeForLLM(elements),
    };
  }

  // Plain screenshot (no annotations)
  async takeScreenshot(fullPage: boolean = false): Promise<string> {
    const c = await this.ensureConnected();
    const params: any = { format: "png" };

    if (fullPage) {
      const metrics = await c.send("Page.getLayoutMetrics", {});
      const contentSize = metrics.cssContentSize || metrics.contentSize;
      params.clip = {
        x: 0, y: 0,
        width: contentSize.width,
        height: contentSize.height,
        scale: 1,
      };
    }

    const { data } = await c.Page.captureScreenshot(params);
    return data;
  }

  // =========================================================================
  // 3. SMART DOM SIMPLIFICATION
  // =========================================================================

  async getSimplifiedDOM(selector?: string): Promise<string> {
    const c = await this.ensureConnected();

    const { result } = await c.Runtime.evaluate({
      expression: `(() => {
        const root = ${selector ? `document.querySelector(${JSON.stringify(selector)})` : "document.body"};
        if (!root) return "Element not found";

        function simplify(el, depth) {
          if (depth > 6) return '';
          const style = window.getComputedStyle(el);
          if (style.display === 'none' || style.visibility === 'hidden') return '';

          const tag = el.tagName?.toLowerCase();
          if (!tag) return el.textContent?.trim().substring(0, 100) || '';

          // Skip noise elements
          if (['script','style','noscript','svg','path','meta','link','br','hr'].includes(tag)) return '';

          const attrs = [];
          if (el.id) attrs.push('id="' + el.id + '"');
          if (el.getAttribute('role')) attrs.push('role="' + el.getAttribute('role') + '"');
          if (el.getAttribute('aria-label')) attrs.push('aria-label="' + el.getAttribute('aria-label') + '"');
          if (el.getAttribute('type')) attrs.push('type="' + el.getAttribute('type') + '"');
          if (el.getAttribute('href')) attrs.push('href="' + el.getAttribute('href').substring(0, 80) + '"');
          if (el.getAttribute('placeholder')) attrs.push('placeholder="' + el.getAttribute('placeholder') + '"');
          if (el.disabled) attrs.push('disabled');
          if (el.value && ['INPUT','TEXTAREA','SELECT'].includes(el.tagName)) attrs.push('value="' + el.value.substring(0, 50) + '"');

          const indent = '  '.repeat(depth);
          const attrStr = attrs.length ? ' ' + attrs.join(' ') : '';

          // Leaf text node
          const text = el.childNodes.length === 1 && el.childNodes[0].nodeType === 3
            ? el.textContent?.trim().substring(0, 100) || ''
            : '';

          if (text && !el.children.length) {
            return indent + '<' + tag + attrStr + '>' + text + '</' + tag + '>';
          }

          let children = '';
          for (const child of el.children) {
            const s = simplify(child, depth + 1);
            if (s) children += s + '\\n';
          }

          if (!children && !text) {
            // Skip empty containers
            if (['div','span','section','article','aside','main','header','footer','nav','ul','ol','li','p'].includes(tag)) return '';
          }

          return indent + '<' + tag + attrStr + '>' + (children ? '\\n' + children + indent : text) + '</' + tag + '>';
        }

        return simplify(root, 0);
      })()`,
      returnByValue: true,
    });

    return result.value as string;
  }

  // =========================================================================
  // 4. SHADOW DOM + IFRAME TRAVERSAL
  // =========================================================================

  async getFlattenedDocument(): Promise<string> {
    const c = await this.ensureConnected();

    // Use DOM.getFlattenedDocument which pierces shadow DOMs
    try {
      const { nodes } = await c.send("DOM.getFlattenedDocument", {
        depth: -1,
        pierce: true,
      });

      // Count meaningful nodes
      const interactive = nodes.filter((n: any) =>
        n.nodeName && ["INPUT", "BUTTON", "A", "SELECT", "TEXTAREA"].includes(n.nodeName)
      );
      return `Flattened DOM: ${nodes.length} total nodes, ${interactive.length} interactive elements (includes shadow DOM + iframes)`;
    } catch {
      return "getFlattenedDocument not supported, falling back to standard DOM";
    }
  }

  // =========================================================================
  // 5. NETWORK INTERCEPTION (not just monitoring)
  // =========================================================================

  async enableNetworkInterception(): Promise<string> {
    const c = await this.ensureConnected();

    await c.send("Fetch.enable", {
      patterns: [{ urlPattern: "*", requestStage: "Request" }],
    });

    c.on("Fetch.requestPaused", async (params: any) => {
      const url = params.request.url;
      let handled = false;

      // Check intercept rules
      for (const [pattern, handler] of this.interceptRules) {
        if (url.includes(pattern)) {
          try {
            const result = handler(params);
            if (result?.body) {
              await c.send("Fetch.fulfillRequest", {
                requestId: params.requestId,
                responseCode: result.statusCode || 200,
                responseHeaders: result.headers || [{ name: "Content-Type", value: "application/json" }],
                body: Buffer.from(result.body).toString("base64"),
              });
              handled = true;
            } else if (result?.modifiedHeaders) {
              await c.send("Fetch.continueRequest", {
                requestId: params.requestId,
                headers: result.modifiedHeaders,
              });
              handled = true;
            }
          } catch { /* fall through */ }
          break;
        }
      }

      if (!handled) {
        await c.send("Fetch.continueRequest", { requestId: params.requestId }).catch(() => {});
      }
    });

    return "Network interception enabled";
  }

  addInterceptRule(urlPattern: string, handler: (req: any) => any): void {
    this.interceptRules.set(urlPattern, handler);
  }

  removeInterceptRule(urlPattern: string): void {
    this.interceptRules.delete(urlPattern);
  }

  async blockUrls(patterns: string[]): Promise<string> {
    const c = await this.ensureConnected();
    await c.send("Network.setBlockedURLs", { urls: patterns });
    return `Blocked ${patterns.length} URL patterns`;
  }

  // =========================================================================
  // 6. CONSOLE/ERROR CAPTURE
  // =========================================================================

  getConsoleEntries(level?: string, limit: number = 50): ConsoleEntry[] {
    let entries = this.consoleEntries;
    if (level) entries = entries.filter(e => e.level === level);
    return entries.slice(-limit);
  }

  clearConsole(): void {
    this.consoleEntries = [];
  }

  // =========================================================================
  // 7. MULTI-TAB MANAGEMENT
  // =========================================================================

  async listTabs(): Promise<TabInfo[]> {
    const targets = await CDP.List({ port: this.cdpPort }) as any[];
    return targets
      .filter((t: any) => t.type === "page")
      .map((t: any) => ({
        targetId: t.id,
        url: t.url,
        title: t.title,
        type: t.type,
        active: t.id === this.activeTargetId,
      }));
  }

  async switchTab(targetId: string): Promise<string> {
    // Close current connection
    if (this.client) {
      try { await this.client.close(); } catch {}
      this.client = null;
    }

    // Connect to specific target
    this.client = await CDP({ port: this.cdpPort, target: targetId });
    this.activeTargetId = targetId;
    await this.setupDomains();

    const { result } = await this.client.Runtime.evaluate({
      expression: "document.title",
      returnByValue: true,
    });
    return `Switched to tab: ${result.value}`;
  }

  async newTab(url?: string): Promise<string> {
    const c = await this.ensureConnected();
    const { targetId } = await c.send("Target.createTarget", {
      url: url || "about:blank",
    });
    return this.switchTab(targetId);
  }

  async closeTab(targetId: string): Promise<string> {
    const c = await this.ensureConnected();
    await c.send("Target.closeTarget", { targetId });
    return `Closed tab ${targetId}`;
  }

  // =========================================================================
  // 8. ELEMENT CACHING
  // =========================================================================

  cacheElement(key: string, el: IndexedElement): void {
    if (el.selector) {
      this.elementCache.set(key, {
        selector: el.selector,
        role: el.role,
        name: el.name,
        lastSeen: Date.now(),
        hitCount: 1,
      });
    }
  }

  getCachedElement(key: string): CachedElement | undefined {
    const cached = this.elementCache.get(key);
    if (cached) {
      cached.hitCount++;
      cached.lastSeen = Date.now();
    }
    return cached;
  }

  // =========================================================================
  // 9. POST-ACTION VALIDATION
  // =========================================================================

  async validateAction(
    beforeUrl: string,
    expectedChange?: string
  ): Promise<{ success: boolean; details: string }> {
    const c = await this.ensureConnected();
    await this.sleep(300); // Wait for page to settle

    const { result: urlResult } = await c.Runtime.evaluate({
      expression: "document.location.href",
      returnByValue: true,
    });
    const currentUrl = urlResult.value as string;

    // Check for new errors
    const recentErrors = this.consoleEntries
      .filter(e => e.level === "error" && e.timestamp > Date.now() - 2000);

    const urlChanged = currentUrl !== beforeUrl;
    const hasErrors = recentErrors.length > 0;

    let details = `URL: ${currentUrl}`;
    if (urlChanged) details += ` (changed from ${beforeUrl})`;
    if (hasErrors) details += `\nErrors: ${recentErrors.map(e => e.text).join("; ")}`;

    return {
      success: !hasErrors,
      details,
    };
  }

  // =========================================================================
  // 10. SELF-HEALING SELECTORS
  // =========================================================================

  async findElementByDescription(description: string): Promise<IndexedElement | null> {
    const elements = await this.getAccessibilityTree();

    // Exact name match
    const exact = elements.find(
      e => e.name.toLowerCase() === description.toLowerCase()
    );
    if (exact) return exact;

    // Partial name match
    const partial = elements.find(
      e => e.name.toLowerCase().includes(description.toLowerCase())
    );
    if (partial) return partial;

    // Role + fuzzy match
    const words = description.toLowerCase().split(/\s+/);
    let bestMatch: IndexedElement | null = null;
    let bestScore = 0;

    for (const el of elements) {
      const text = `${el.role} ${el.name} ${el.value || ""}`.toLowerCase();
      let score = 0;
      for (const word of words) {
        if (text.includes(word)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = el;
      }
    }

    return bestScore > 0 ? bestMatch : null;
  }

  // =========================================================================
  // CORE ACTIONS (click, type, navigate, scroll, etc.)
  // =========================================================================

  async navigate(url: string): Promise<string> {
    const c = await this.ensureConnected();
    await c.Page.navigate({ url });
    try {
      await Promise.race([
        c.Page.loadEventFired(),
        this.sleep(10000),
      ]);
    } catch { /* timeout is ok */ }
    const { result } = await c.Runtime.evaluate({
      expression: "document.title", returnByValue: true,
    });
    return `Navigated to ${url} — "${result.value}"`;
  }

  async clickByIndex(index: number): Promise<string> {
    const el = this.indexedElements.get(index);
    if (!el) return `Element [${index}] not found. Run observe first.`;

    const c = await this.ensureConnected();
    const beforeUrl = await this.getCurrentUrl();

    // Try backendNodeId click first
    if (el.backendNodeId) {
      try {
        const { nodeId } = await c.send("DOM.requestNode", { backendNodeId: el.backendNodeId });
        await c.send("DOM.focus", { nodeId });
        const { model } = await c.DOM.getBoxModel({ backendNodeId: el.backendNodeId });
        const q = model.content;
        const cx = (q[0] + q[2]) / 2;
        const cy = (q[1] + q[5]) / 2;
        await this.dispatchClick(c, cx, cy);
        const validation = await this.validateAction(beforeUrl);
        return `Clicked [${index}] ${el.role} "${el.name}" at (${Math.round(cx)}, ${Math.round(cy)})\n${validation.details}`;
      } catch { /* fall through */ }
    }

    // Fallback: bounding box
    if (el.boundingBox) {
      const cx = el.boundingBox.x + el.boundingBox.width / 2;
      const cy = el.boundingBox.y + el.boundingBox.height / 2;
      await this.dispatchClick(c, cx, cy);
      const validation = await this.validateAction(beforeUrl);
      return `Clicked [${index}] ${el.role} "${el.name}" at (${Math.round(cx)}, ${Math.round(cy)})\n${validation.details}`;
    }

    // Fallback: selector
    if (el.selector) {
      return this.clickBySelector(el.selector);
    }

    return `Cannot click [${index}] — no position or selector available`;
  }

  async clickBySelector(selector: string): Promise<string> {
    const c = await this.ensureConnected();
    const { result } = await c.Runtime.evaluate({
      expression: `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el) return null;
        const rect = el.getBoundingClientRect();
        el.click();
        return JSON.stringify({
          tag: el.tagName,
          text: el.innerText?.substring(0, 80),
          x: rect.left + rect.width/2,
          y: rect.top + rect.height/2
        });
      })()`,
      returnByValue: true,
    });

    if (!result.value) return `Element not found: ${selector}`;
    const info = JSON.parse(result.value);
    return `Clicked <${info.tag}> "${info.text}" at (${Math.round(info.x)}, ${Math.round(info.y)})`;
  }

  async clickAtCoords(x: number, y: number): Promise<string> {
    const c = await this.ensureConnected();
    await this.dispatchClick(c, x, y);
    return `Clicked at (${x}, ${y})`;
  }

  async type(selector: string, text: string, clearFirst: boolean = true): Promise<string> {
    const c = await this.ensureConnected();

    await c.Runtime.evaluate({
      expression: `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el) return false;
        el.focus();
        ${clearFirst ? "if (el.select) el.select();" : ""}
        return true;
      })()`,
      returnByValue: true,
    });

    if (clearFirst) {
      await c.Input.dispatchKeyEvent({ type: "keyDown", key: "a", modifiers: os.platform() === "darwin" ? 4 : 2 });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: "a" });
      await c.Input.dispatchKeyEvent({ type: "keyDown", key: "Backspace" });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: "Backspace" });
    }

    for (const char of text) {
      await c.Input.dispatchKeyEvent({ type: "keyDown", text: char, key: char });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: char });
    }

    return `Typed "${text}" into ${selector}`;
  }

  async typeByIndex(index: number, text: string, clearFirst: boolean = true): Promise<string> {
    const el = this.indexedElements.get(index);
    if (!el) return `Element [${index}] not found. Run observe first.`;

    const c = await this.ensureConnected();

    // Focus by backendNodeId
    if (el.backendNodeId) {
      try {
        const { nodeId } = await c.send("DOM.requestNode", { backendNodeId: el.backendNodeId });
        await c.send("DOM.focus", { nodeId });
      } catch { /* fall through to selector */ }
    }

    if (clearFirst) {
      await c.Input.dispatchKeyEvent({ type: "keyDown", key: "a", modifiers: os.platform() === "darwin" ? 4 : 2 });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: "a" });
      await c.Input.dispatchKeyEvent({ type: "keyDown", key: "Backspace" });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: "Backspace" });
    }

    for (const char of text) {
      await c.Input.dispatchKeyEvent({ type: "keyDown", text: char, key: char });
      await c.Input.dispatchKeyEvent({ type: "keyUp", key: char });
    }

    return `Typed "${text}" into [${index}] ${el.role} "${el.name}"`;
  }

  async pressKey(key: string, modifiers?: string[]): Promise<string> {
    const c = await this.ensureConnected();
    let modFlag = 0;
    if (modifiers?.includes("alt")) modFlag |= 1;
    if (modifiers?.includes("ctrl")) modFlag |= 2;
    if (modifiers?.includes("meta") || modifiers?.includes("cmd")) modFlag |= 4;
    if (modifiers?.includes("shift")) modFlag |= 8;

    const keyMap: Record<string, string> = {
      enter: "Enter", tab: "Tab", escape: "Escape", backspace: "Backspace",
      delete: "Delete", arrowup: "ArrowUp", arrowdown: "ArrowDown",
      arrowleft: "ArrowLeft", arrowright: "ArrowRight",
      home: "Home", end: "End", pageup: "PageUp", pagedown: "PageDown", space: " ",
    };
    const cdpKey = keyMap[key.toLowerCase()] || key;

    await c.Input.dispatchKeyEvent({ type: "keyDown", key: cdpKey, modifiers: modFlag });
    await c.Input.dispatchKeyEvent({ type: "keyUp", key: cdpKey, modifiers: modFlag });

    return `Pressed ${modifiers?.length ? modifiers.join("+") + "+" : ""}${key}`;
  }

  async scrollDown(px: number = 500): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseWheel", x: 400, y: 400, deltaX: 0, deltaY: px });
    return `Scrolled down ${px}px`;
  }

  async scrollUp(px: number = 500): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseWheel", x: 400, y: 400, deltaX: 0, deltaY: -px });
    return `Scrolled up ${px}px`;
  }

  async scrollTo(x: number, y: number): Promise<string> {
    const c = await this.ensureConnected();
    await c.Runtime.evaluate({ expression: `window.scrollTo(${x}, ${y})` });
    return `Scrolled to (${x}, ${y})`;
  }

  async refreshPage(): Promise<string> {
    const c = await this.ensureConnected();
    await c.Page.reload();
    try { await Promise.race([c.Page.loadEventFired(), this.sleep(10000)]); } catch {}
    return "Page refreshed";
  }

  async resizeViewport(width: number, height: number): Promise<string> {
    const c = await this.ensureConnected();
    await c.send("Emulation.setDeviceMetricsOverride", {
      width, height, deviceScaleFactor: 2, mobile: false,
    });
    return `Viewport resized to ${width}x${height}`;
  }

  async selectOption(selector: string, value: string): Promise<string> {
    const c = await this.ensureConnected();
    const { result } = await c.Runtime.evaluate({
      expression: `(() => {
        const el = document.querySelector(${JSON.stringify(selector)});
        if (!el || el.tagName !== 'SELECT') return 'Not a select element';
        el.value = ${JSON.stringify(value)};
        el.dispatchEvent(new Event('change', { bubbles: true }));
        return 'Selected: ' + el.options[el.selectedIndex]?.text;
      })()`,
      returnByValue: true,
    });
    return result.value as string;
  }

  async moveMouse(x: number, y: number): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseMoved", x, y });
    return `Mouse moved to (${x}, ${y})`;
  }

  async mouseDown(x: number, y: number, button: string = "left"): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mousePressed", x, y, button, clickCount: 1 });
    return `Mouse down at (${x}, ${y})`;
  }

  async mouseUp(x: number, y: number, button: string = "left"): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseReleased", x, y, button, clickCount: 1 });
    return `Mouse up at (${x}, ${y})`;
  }

  async mouseWheel(x: number, y: number, dx: number, dy: number): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseWheel", x, y, deltaX: dx, deltaY: dy });
    return `Mouse wheel at (${x}, ${y}) delta(${dx}, ${dy})`;
  }

  async drag(fromX: number, fromY: number, toX: number, toY: number): Promise<string> {
    const c = await this.ensureConnected();
    await c.Input.dispatchMouseEvent({ type: "mouseMoved", x: fromX, y: fromY });
    await this.sleep(50);
    await c.Input.dispatchMouseEvent({ type: "mousePressed", x: fromX, y: fromY, button: "left", clickCount: 1 });
    await this.sleep(100);

    const steps = 10;
    for (let i = 1; i <= steps; i++) {
      await c.Input.dispatchMouseEvent({
        type: "mouseMoved",
        x: Math.round(fromX + ((toX - fromX) * i) / steps),
        y: Math.round(fromY + ((toY - fromY) * i) / steps),
        buttons: 1,
      });
      await this.sleep(20);
    }

    await c.Input.dispatchMouseEvent({ type: "mouseReleased", x: toX, y: toY, button: "left", clickCount: 1 });
    return `Dragged from (${fromX}, ${fromY}) to (${toX}, ${toY})`;
  }

  async runJs(expression: string): Promise<string> {
    const c = await this.ensureConnected();
    const { result, exceptionDetails } = await c.Runtime.evaluate({
      expression, returnByValue: true, awaitPromise: true,
    });
    if (exceptionDetails) {
      return `Error: ${exceptionDetails.text || exceptionDetails.exception?.description || "Unknown"}`;
    }
    if (result.type === "undefined") return "undefined";
    if (result.value !== undefined) {
      return typeof result.value === "string" ? result.value : JSON.stringify(result.value, null, 2);
    }
    return result.description || String(result.value);
  }

  async waitForNavigation(timeout: number = 10000): Promise<string> {
    const c = await this.ensureConnected();
    await Promise.race([
      c.Page.loadEventFired(),
      this.sleep(timeout),
    ]);
    return `Navigation complete: ${await this.getCurrentUrl()}`;
  }

  async getCurrentUrl(): Promise<string> {
    const c = await this.ensureConnected();
    const { result } = await c.Runtime.evaluate({ expression: "document.location.href", returnByValue: true });
    return result.value as string;
  }

  async getTitle(): Promise<string> {
    const c = await this.ensureConnected();
    const { result } = await c.Runtime.evaluate({ expression: "document.title", returnByValue: true });
    return result.value as string;
  }

  getNetworkEntries(filter?: string, limit: number = 50): NetworkEntry[] {
    let entries = Array.from(this.networkEntries.values());
    if (filter) entries = entries.filter(e => e.url.toLowerCase().includes(filter.toLowerCase()));
    return entries.slice(-limit);
  }

  getNetworkEntry(requestId: string): NetworkEntry | undefined {
    return this.networkEntries.get(requestId);
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  private async dispatchClick(c: any, x: number, y: number): Promise<void> {
    await c.Input.dispatchMouseEvent({ type: "mouseMoved", x, y });
    await this.sleep(50);
    await c.Input.dispatchMouseEvent({ type: "mousePressed", x, y, button: "left", clickCount: 1 });
    await c.Input.dispatchMouseEvent({ type: "mouseReleased", x, y, button: "left", clickCount: 1 });
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(r => setTimeout(r, ms));
  }

  async close(): Promise<void> {
    if (this.client) {
      try { await this.client.close(); } catch {}
      this.client = null;
    }
  }
}
