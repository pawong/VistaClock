import Foundation
import ServiceManagement

@objc public class LoginItemHelper: NSObject {
    @objc public static func setLoginItemEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                let appService = SMAppService.loginItem(identifier: "com.Mazookie.VistaClockLoginHelper")
                if enabled {
                    try appService.register()
                } else {
                    try appService.unregister()
                }
            } catch {
                NSLog("Failed to change login item state: %@", String(describing: error))
            }
        }
    }
}
