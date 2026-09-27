//
//  TextService.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Foundation
import Cocoa

/// Service handling target app focus capture, text selection via AXUIElement or Cmd+C, and text injection
class TextService {
    static let shared = TextService()
    
    private var lastFocusedElement: AXUIElement?

    /// Captures the currently active UI element (e.g. text field in Notes, Chrome, Slack)
    func captureFocus() {
        if let focused = getFocusedUIElement() {
            self.lastFocusedElement = focused
        }
    }

    /// Reads currently selected text, attempting direct Accessibility API read first, with Cmd+C pasteboard fallback
    func getSelectedText() async -> String? {
        // Attempt 1: Direct Accessibility API read from focused element
        if let focusedElement = lastFocusedElement ?? getFocusedUIElement() {
            var selectedValue: AnyObject?
            let result = AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, &selectedValue)
            if result == .success, let text = selectedValue as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }
        
        // Attempt 2: Fallback using Cmd+C simulation and pasteboard inspect
        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount
        
        // 0x08 is virtual key code for 'C'
        self.simulateKey(keyCode: 0x08, flags: .maskCommand)
        
        // Non-blocking sleep giving macOS clipboard time to process key event
        try? await Task.sleep(nanoseconds: 150_000_000)
        
        if pasteboard.changeCount != initialChangeCount {
            return pasteboard.string(forType: .string)
        }
        
        return pasteboard.string(forType: .string)
    }

    /// Replaces the selected text in the focused app using Accessibility API or Cmd+V fallback
    func replaceText(with newText: String) {
        if let element = self.lastFocusedElement {
            let result = AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, newText as CFTypeRef)
            self.lastFocusedElement = nil
            
            if result == .success {
                return
            }
        }
        
        // Fallback for apps (like Electron or WebViews) that don't support direct AX text setting
        simulatePasteFallback(with: newText)
    }

    private func getFocusedUIElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
           let target = focused {
            return (target as! AXUIElement)
        }
        return nil
    }

    private func simulatePasteFallback(with newText: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)
        
        // 0x09 is virtual key code for 'V'
        self.simulateKey(keyCode: 0x09, flags: .maskCommand)
    }

    private func simulateKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        
        keyDown?.flags = flags
        keyUp?.flags = flags
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
