import Carbon
import Cocoa

class HotkeyManager {
    private var hotKeys: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]
    private var handlerRef: EventHandlerRef?
    private var retainedSelf: Unmanaged<HotkeyManager>?

    func register(id: UInt32, modifiers: UInt32, keyCode: UInt32, handler: @escaping () -> Void) {
        handlers[id] = handler

        if handlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            retainedSelf = Unmanaged.passRetained(self)
            let ptr = retainedSelf!.toOpaque()

            let status = InstallEventHandler(
                GetEventDispatcherTarget(),
                { _, event, userData -> OSStatus in
                    guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                    let mgr = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    var hotKeyID = EventHotKeyID()
                    GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )
                    NSLog("[Nudge] Hotkey fired: id=\(hotKeyID.id)")
                    mgr.handlers[hotKeyID.id]?()
                    return noErr
                },
                1, &eventType, ptr, &handlerRef
            )
            NSLog("[Nudge] InstallEventHandler status: \(status)")
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4E554447), id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &ref)
        NSLog("[Nudge] RegisterEventHotKey id=\(id) key=\(keyCode) mod=\(modifiers) status=\(status)")
        if let ref { hotKeys[id] = ref }
    }

    func unregisterAll() {
        for (_, ref) in hotKeys { UnregisterEventHotKey(ref) }
        hotKeys.removeAll()
        handlers.removeAll()
    }

    deinit {
        unregisterAll()
        retainedSelf?.release()
    }
}
