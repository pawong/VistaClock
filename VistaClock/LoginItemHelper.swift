import Foundation
import ServiceManagement

/// Registers or removes the bundled login helper app that launches VistaClock at login.
enum LoginItemHelper {
    private static let helperIdentifier = "com.Mazookie.VistaClockLoginHelper"

    static func setLoginItemEnabled(_ enabled: Bool) {
        let service = SMAppService.loginItem(identifier: helperIdentifier)
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else if service.status == .enabled {
                try service.unregister()
            }
        } catch {
            NSLog("Failed to change login item state: %@", String(describing: error))
        }
    }
}
