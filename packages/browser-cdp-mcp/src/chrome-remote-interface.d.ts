declare module "chrome-remote-interface" {
  namespace CDP {
    interface Options {
      port?: number;
      host?: string;
      target?: string;
    }

    interface Client {
      Runtime: {
        enable(): Promise<void>;
        evaluate(params: {
          expression: string;
          returnByValue?: boolean;
          awaitPromise?: boolean;
        }): Promise<{
          result: { type: string; value?: any; description?: string };
          exceptionDetails?: {
            text: string;
            exception?: { description: string };
          };
        }>;
        consoleAPICalled?(callback: (params: any) => void): void;
        exceptionThrown?(callback: (params: any) => void): void;
      };
      Page: {
        enable(): Promise<void>;
        navigate(params: { url: string }): Promise<any>;
        loadEventFired(): Promise<any>;
        reload(): Promise<void>;
        captureScreenshot(params?: any): Promise<{ data: string }>;
      };
      DOM: {
        enable(): Promise<void>;
        getDocument(params?: { depth?: number }): Promise<{
          root: { nodeId: number };
        }>;
        getOuterHTML(params: { nodeId: number }): Promise<{ outerHTML: string }>;
        getBoxModel(params: { backendNodeId?: number; nodeId?: number }): Promise<{ model: { content: number[] } }>;
      };
      Network: {
        enable(): Promise<void>;
        requestWillBeSent(callback: (params: any) => void): void;
        responseReceived(callback: (params: any) => void): void;
        loadingFinished?(callback: (params: any) => void): void;
      };
      Input: {
        dispatchKeyEvent(params: {
          type: string;
          key?: string;
          text?: string;
          modifiers?: number;
        }): Promise<void>;
        dispatchMouseEvent(params: {
          type: string;
          x: number;
          y: number;
          button?: string;
          clickCount?: number;
          deltaX?: number;
          deltaY?: number;
          buttons?: number;
        }): Promise<void>;
      };
      Emulation: {
        setDeviceMetricsOverride(params: {
          width: number;
          height: number;
          deviceScaleFactor: number;
          mobile: boolean;
        }): Promise<void>;
      };
      Accessibility?: {
        enable?(): Promise<void>;
      };
      Overlay?: {
        enable?(): Promise<void>;
      };
      send(method: string, params?: any): Promise<any>;
      on(event: string, callback: (params: any) => void): void;
      close(): Promise<void>;
    }
  }

  function CDP(options?: CDP.Options): Promise<CDP.Client>;

  namespace CDP {
    function List(options?: { port?: number; host?: string }): Promise<any[]>;
  }

  export = CDP;
}
