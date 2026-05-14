//
//  TextService.swift
//  RewriteAI
//
//  Created by Maitreya Sinha on 14/05/2026.
//

import Foundation
import Cocoa

class TextService {
    static let shared = TextService()
    
    // Create a variable to "Remember" where the text should go
    private var lastFocusedElement: AXUIElement?

    func captureFocus() {
        let systemWide = AXUIElementCreateSystemWide()
        var focused: AnyObject?
        if AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focused) == .success {
            self.lastFocusedElement = (focused as! AXUIElement)
        }
    }

    func replaceText(with newText: String) {
        guard let element = self.lastFocusedElement else {
            // Fallback to Cmd+V if focus was lost
            return
        }
        // This "Injects" the text into the exact box you grabbed earlier
        // Even if the user clicked away to another window!
        AXUIElementSetAttributeValue(element, kAXSelectedTextAttribute as CFString, newText as CFTypeRef)
        self.lastFocusedElement = nil // Clear for next time
    }
    
    
    func getSelectedText() -> String? {
            let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                self.simulateKey(keyCode: 0x08, flags: .maskCommand) // 0x08 is 'C'
        
        
                Thread.sleep(forTimeInterval: 0.2)
        
        let selectedText = pasteboard.string(forType: .string)
        
        return selectedText
}
    
    private func simulatePasteFallback(with newText: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)
        self.simulateKey(keyCode: 0x09, flags: .maskCommand) // Cmd+V
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
