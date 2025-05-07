import SwiftUI
import WebKit
import AppKit

struct WebView: NSViewRepresentable {
    let url: URL
    // Add a reference to communicate with parent view
    var webViewStore: WebViewStore
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .default()
        
        // Enable WebAuthn/FIDO for passkey authentication
        if #available(macOS 13.0, *) {
            // WebAuthentication API is enabled by default in newer macOS versions
            // The 'isWebAuthenticationEnabled' property was removed in later SDK versions
        }
        
        let js = """
        // Function to clean the UI
        function cleanUI() {
            // Elements to remove
            const elementsToRemove = [
                '.AppHeader-globalBar',
                '.AppHeader-user',
                '.AppHeader-search',
                'nav[aria-label="Global"]',
                '.Layout-sidebar',
                '.AppHeader-context',
                '.AppHeader',
                '.Header',
                'header',
                '.footer',
                'footer',
                '.gh-header-sticky',
                '.tabnav',
                '.breadcrumb',
                '.js-header-wrapper',
                '.gh-header',
                '.flash',
                '.pagehead',
                '.commit-tease',
                '.file-navigation',
                '.repository-content > .gutter-condensed',
                '.repository-content > nav'
            ];
            
            elementsToRemove.forEach(selector => {
                document.querySelectorAll(selector).forEach(el => {
                    el.style.display = 'none';
                    // Alternative: el.remove();
                });
            });
            
            // Focus on Copilot chat container - enhance UI
            const chatContainer = document.querySelector('.copilot-chat-container');
            if (chatContainer) {
                chatContainer.style.maxWidth = '100%';
                chatContainer.style.width = '100%';
                chatContainer.style.margin = '0';
                chatContainer.style.padding = '0';
                
                // Try to get parent elements and make them take full width
                let parent = chatContainer.parentElement;
                while (parent && parent !== document.body) {
                    parent.style.maxWidth = '100%';
                    parent.style.width = '100%';
                    parent.style.margin = '0';
                    parent.style.padding = '0';
                    parent = parent.parentElement;
                }
            }
        }
        
        // Run on initial load
        document.addEventListener('DOMContentLoaded', cleanUI);
        
        // Run periodically to catch any dynamically loaded elements
        setInterval(cleanUI, 1000);
        
        // Also run on any navigation changes or ajax completions
        window.addEventListener('load', cleanUI);
        document.addEventListener('readystatechange', cleanUI);
        """
        
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        
        let wkWebView = WKWebView(frame: .zero, configuration: config)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.uiDelegate = context.coordinator // Add UI delegate for features like window.open handling
        
        // Set initial background color to prevent white flash
        wkWebView.setValue(false, forKey: "drawsBackground")
        
        // Set the background color to a dark blue similar to GitHub's theme
        // This color will show until the actual page loads
        wkWebView.layer?.backgroundColor = NSColor(calibratedRed: 13/255, green: 17/255, blue: 23/255, alpha: 1.0).cgColor
        
        // Store the webView reference
        webViewStore.webView = wkWebView
        
        return wkWebView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.load(URLRequest(url: url))
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // Intercept link clicks and decide which ones should open in external browser
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if it's a link click
            if navigationAction.navigationType == .linkActivated {
                guard let url = navigationAction.request.url else {
                    decisionHandler(.allow)
                    return
                }
                
                // Check if the URL is within GitHub Copilot domain
                let copilotDomains = ["github.com/copilot", "github.com/github-copilot", "copilot.github.com"]
                let isWithinApp = copilotDomains.contains { domain in
                    url.absoluteString.contains(domain)
                }
                
                if !isWithinApp {
                    // Open the URL in the default browser
                    NSWorkspace.shared.open(url)
                    decisionHandler(.cancel) // Don't load in our WebView
                    return
                }
            }
            
            // Allow the navigation within the app
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Execute custom JavaScript each time navigation completes
            let cleanupScript = """
            // Run cleanup after page fully loads
            setTimeout(() => {
                // Same cleanup function from the main script
                const elementsToRemove = [
                    '.AppHeader-globalBar',
                    '.AppHeader-user',
                    '.AppHeader-search',
                    'nav[aria-label="Global"]',
                    '.Layout-sidebar',
                    '.AppHeader-context',
                    '.AppHeader',
                    '.Header',
                    'header',
                    '.footer',
                    'footer'
                ];
                
                elementsToRemove.forEach(selector => {
                    document.querySelectorAll(selector).forEach(el => {
                        el.style.display = 'none';
                    });
                });
                
                // Remove padding from the top of the main content area
                const mainContent = document.querySelector('.application-main');
                if (mainContent) {
                    mainContent.style.paddingTop = '0';
                }
                
                // Focus specifically on GitHub Copilot chat container
                const chatContainer = document.querySelector('.copilot-chat-container');
                if (chatContainer) {
                    chatContainer.style.maxWidth = '100%';
                    chatContainer.style.width = '100%';
                    chatContainer.style.margin = '0';
                    chatContainer.style.padding = '0';
                    // Remove added padding
                    chatContainer.style.paddingTop = '0';
                }
                
                // Remove padding from conversation container if it exists
                const conversationContent = document.querySelector('.conversation-container');
                if (conversationContent) {
                    conversationContent.style.paddingTop = '0';
                }
            }, 1000);
            """
            
            webView.evaluateJavaScript(cleanupScript, completionHandler: nil)
            
            // Add improved button detection for better functionality
            let fixButtonsScript = """
            // Function to find buttons more precisely on GitHub Copilot interface
            function findAndMarkButton(ariaLabel) {
                // Try different selectors for buttons (GitHub's UI can vary)
                const selectors = [
                    `[aria-label="${ariaLabel}"]`,
                    `button[aria-label="${ariaLabel}"]`,
                    `a[aria-label="${ariaLabel}"]`,
                    `div[aria-label="${ariaLabel}"]`,
                    `*[title="${ariaLabel}"]`,
                    `*[data-testid*="${ariaLabel.toLowerCase().replace(/\\s+/g, '-')}"]`
                ];
                
                for (const selector of selectors) {
                    const button = document.querySelector(selector);
                    if (button) {
                        // Mark the button so we can find it later
                        button.setAttribute('data-copilot-app-button', ariaLabel);
                        return true;
                    }
                }
                
                // Try to find by text content if aria-label isn't working
                const allButtons = document.querySelectorAll('button, a[role="button"], [role="button"]');
                for (const button of allButtons) {
                    if (button.textContent && button.textContent.includes(ariaLabel)) {
                        button.setAttribute('data-copilot-app-button', ariaLabel);
                        return true;
                    }
                }
                
                return false;
            }
            
            // Find and mark all the buttons we need to interact with
            const buttonLabels = [
                'Open conversations', 
                'New conversation', 
                'Select model', 
                'Open workbench',
                'Menu',
                'Copy',
                'Share'
            ];
            
            buttonLabels.forEach(findAndMarkButton);
            
            // Set up an observer to find buttons as they appear in the DOM
            const observer = new MutationObserver(() => {
                buttonLabels.forEach(findAndMarkButton);
            });
            
            observer.observe(document.body, { 
                childList: true, 
                subtree: true 
            });
            """
            
            webView.evaluateJavaScript(fixButtonsScript, completionHandler: nil)
        }
        
        // Handle window.open requests by opening in default browser
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // When a link tries to open in a new window/tab
            if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
            return nil
        }
        
        // Handle JavaScript that tries to open new windows
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = NSAlert()
            alert.messageText = "Alert"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.runModal()
            completionHandler()
        }
        
        // Handle JavaScript confirm dialogs
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = NSAlert()
            alert.messageText = "Confirm"
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn)
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            // Intentionally left empty - removed previous themeColorHandler implementation
        }
    }
}

// Class to store and share the WebView instance
class WebViewStore: ObservableObject {
    @Published var webView: WKWebView?
    
    func executeJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        webView?.evaluateJavaScript(script, completionHandler: completion)
    }
}

struct ContentView: View {
    // Store the WebView instance so we can interact with it
    @StateObject private var webViewStore = WebViewStore()
    
    var body: some View {
        // WebView without the custom toolbar
        WebView(url: URL(string: "https://github.com/copilot")!, webViewStore: webViewStore)
            .edgesIgnoringSafeArea(.all)
            .frame(width: 980, height: 658)
    }
}

// Preview for SwiftUI canvas
#Preview {
    ContentView()
}
