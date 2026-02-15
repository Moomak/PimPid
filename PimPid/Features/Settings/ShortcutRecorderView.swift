import AppKit
import SwiftUI

/// Notification เมื่อผู้ใช้เปลี่ยน shortcut
extension Notification.Name {
    static let shortcutPreferenceDidChange = Notification.Name("shortcutPreferenceDidChange")
}

/// View ที่รับ key down แล้วบันทึกเป็น shortcut (ใช้ NSViewRepresentable + รับฟัง key)
struct ShortcutRecorderView: NSViewRepresentable {
    let currentShortcut: String
    let onRecord: (UInt16, UInt) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let v = ShortcutRecorderNSView()
        v.onRecord = onRecord
        v.setDisplay(currentShortcut)
        return v
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.setDisplay(currentShortcut)
    }
}

final class ShortcutRecorderNSView: NSView {
    var onRecord: ((UInt16, UInt) -> Void)?
    private let label = NSTextField(labelWithString: "")
    private let button = NSButton(title: "กดปุ่มที่ต้องการ…", target: nil, action: nil)
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .labelColor
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(startRecording)
        addSubview(label)
        addSubview(button)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        label.sizeToFit()
        label.frame = CGRect(x: 0, y: bounds.midY - label.bounds.height / 2, width: label.bounds.width, height: label.bounds.height)
        button.sizeToFit()
        let bw = min(button.bounds.width + 20, bounds.width - label.bounds.width - 12)
        button.frame = CGRect(x: bounds.width - bw, y: bounds.midY - 18, width: bw, height: 36)
    }

    func setDisplay(_ text: String) {
        label.stringValue = text
        needsLayout = true
    }

    @objc private func startRecording() {
        isRecording = true
        button.title = "กดปุ่ม shortcut…"
        window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if !isRecording { super.keyDown(with: event); return }
        // ไม่ใช้ปุ่ม modifier อย่างเดียวเป็น shortcut
        let modifierKeyCodes: Set<UInt16> = [55, 56, 57, 58, 59, 60, 61] // command, shift, option, control, etc.
        if modifierKeyCodes.contains(event.keyCode) { return }
        let mod = event.modifierFlags.intersection(NSEvent.ModifierFlags([.command, .shift, .option, .control]))
        onRecord?(event.keyCode, mod.rawValue)
        ShortcutPreference.set(keyCode: event.keyCode, modifierFlags: mod.rawValue)
        setDisplay(ShortcutPreference.displayString(keyCode: event.keyCode, modifierFlags: mod.rawValue))
        button.title = "ตั้ง shortcut"
        isRecording = false
        window?.makeFirstResponder(nil)
        NotificationCenter.default.post(name: .shortcutPreferenceDidChange, object: nil)
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            button.title = "ตั้ง shortcut"
        }
        return true
    }
}
