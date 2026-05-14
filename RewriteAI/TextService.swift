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
    func getSelectedText() -> String? {
            let pasteboard = NSPasteboard.general
            let originalContent = pasteboard.string(forType: .string)
        
        // 1. Clear clipboard and simulate Cmd+C
                pasteboard.clearContents()
                self.simulateKey(keyCode: 0x08, flags: .maskCommand) // 0x08 is 'C'
        
        // 2. Wait a tiny bit for the OS to finish the copy
                Thread.sleep(forTimeInterval: 0.2)
        
        let selectedText = pasteboard.string(forType: .string)
        
        // 3. Restore original content if needed (optional)
        // pasteboard.setString(originalContent ?? "", forType: .string)
        return selectedText
}

    func replaceSelectedText(with newText: String) {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(newText, forType: .string)
            
            // Simulate Cmd+V
            self.simulateKey(keyCode: 0x09, flags: .maskCommand) // 0x09 is 'V'
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
