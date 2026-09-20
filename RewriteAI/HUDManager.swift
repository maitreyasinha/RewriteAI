//
//  HUDManager.swift
//  RewriteAI
//
//  Created by Antigravity on 20/09/2026.
//

import AppKit

/// Floating overlay HUD displaying feedback while AI processing is active
@MainActor
class HUDManager {
    static let shared = HUDManager()
    
    private var hudWindow: NSPanel?

    /// Shows the floating "Rewriting..." panel near the center of the screen
    func show() {
        if hudWindow != nil { return }
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 130, height: 40),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.backgroundColor = NSColor.black.withAlphaComponent(0.85)
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .mainMenu
        panel.isMovableByWindowBackground = true
        panel.center()
        
        let stack = NSStackView(frame: panel.contentView?.bounds ?? .zero)
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        
        let spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.startAnimation(nil)
        
        let label = NSTextField(labelWithString: "Rewriting...")
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .medium)
        
        stack.addArrangedSubview(spinner)
        stack.addArrangedSubview(label)
        panel.contentView?.addSubview(stack)
        
        panel.orderFrontRegardless()
        self.hudWindow = panel
    }

    /// Hides and dismisses the floating HUD panel
    func hide() {
        hudWindow?.orderOut(nil)
        hudWindow = nil
    }
}
