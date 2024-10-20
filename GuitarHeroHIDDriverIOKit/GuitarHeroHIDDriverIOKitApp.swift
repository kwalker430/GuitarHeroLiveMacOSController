import Foundation
import SwiftUI
import IOBluetooth
import IOKit.hid

@main
struct GuitarHeroHIDDriverIOKitApp: App {
    
    // Initialize the driver inside the app lifecycle
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize the HID driver when the app launches
                    let guitarHeroDriver = GuitarHeroHIDDriver()
                    
                    // Run the main run loop to listen for input from the device
                    CFRunLoopRun()
                }
        }
    }
}

class GuitarHeroHIDDriver: ObservableObject {
    var ioHIDManager: IOHIDManager!
    
    @Published var statusMessage: String = "Initializing..."
    @Published var isConnected: Bool = false
    var inputBuffer = [UInt8]() // Buffer to collect inputs over time

    init() {
        setupHIDManager()
    }

    // Set up the HID manager to detect the Guitar Hero Live controller
    func setupHIDManager() {
        ioHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        
        // Define matching criteria for the Guitar Hero controller using its HID Usage page and usage ID
        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,  // HID Usage page for generic desktop
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_GamePad         // Usage ID for gamepad
        ]
        
        IOHIDManagerSetDeviceMatching(ioHIDManager, matchingDict as CFDictionary)

        // Register a callback for when HID devices are connected
        IOHIDManagerRegisterDeviceMatchingCallback(ioHIDManager, deviceMatchingCallback, Unmanaged.passUnretained(self).toOpaque())
        
        // Register a callback for when HID devices are disconnected
        IOHIDManagerRegisterDeviceRemovalCallback(ioHIDManager, deviceRemovalCallback, nil)

        // Schedule with the run loop
        IOHIDManagerScheduleWithRunLoop(ioHIDManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        // Open the HID manager
        IOHIDManagerOpen(ioHIDManager, IOOptionBits(kIOHIDOptionsTypeNone))

        DispatchQueue.main.async {
            self.statusMessage = "Waiting for Guitar Hero controller to connect..."
        }

        print("HID Manager setup complete")
    }

    // Callback when a matching device (Guitar Hero controller) is connected
    let deviceMatchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
        print("Guitar Hero controller connected: \(device)")
        
        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context!).takeUnretainedValue()
        
        // Update the UI to reflect connection status
        DispatchQueue.main.async {
            selfPointer.isConnected = true
            selfPointer.statusMessage = "Guitar Hero controller connected! Listening for button presses..."
        }

        // Register a report callback to handle input from the device
        IOHIDDeviceRegisterInputReportCallback(device, UnsafeMutablePointer<UInt8>.allocate(capacity: 256), 256, selfPointer.inputReportCallback, nil)
    }

    // Callback when the Guitar Hero controller is removed
    let deviceRemovalCallback: IOHIDDeviceCallback = { context, result, sender, device in
        print("Guitar Hero controller disconnected")
        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context!).takeUnretainedValue()

        // Update the UI to reflect disconnection
        DispatchQueue.main.async {
            selfPointer.isConnected = false
            selfPointer.statusMessage = "Guitar Hero controller disconnected."
        }
    }

    // Callback to handle incoming HID reports (button presses, strumming, etc.)
    let inputReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
        let reportData = Data(bytes: report, count: reportLength)
        print("Received HID report: \(reportData)")

        // Retrieve the instance of the driver
        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context!).takeUnretainedValue()

        // Collect inputs into buffer for a short period to handle multi-inputs
        selfPointer.inputBuffer.append(contentsOf: reportData)

        DispatchQueue.main.async {
            // Update the UI to show button press detection
            selfPointer.statusMessage = "Button press detected! Data: \(reportData.map { String(format: "%02x", $0) }.joined())"
        }

        // Process the buffer after a short delay and reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selfPointer.inputBuffer.removeAll()
        }
    }
}



//// Your existing GuitarHeroHIDDriver class
//class GuitarHeroHIDDriver {
//    var ioHIDManager: IOHIDManager!
//
//    init() {
//        setupHIDManager()
//    }
//
//    func setupHIDManager() {
//        ioHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
//        
//        let matchingDict: [String: Any] = [
//            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
//            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_GamePad
//        ]
//        
//        IOHIDManagerSetDeviceMatching(ioHIDManager, matchingDict as CFDictionary)
//
//        IOHIDManagerRegisterDeviceMatchingCallback(ioHIDManager, deviceMatchingCallback, Unmanaged.passUnretained(self).toOpaque())
//        IOHIDManagerRegisterDeviceRemovalCallback(ioHIDManager, deviceRemovalCallback, nil)
//        IOHIDManagerScheduleWithRunLoop(ioHIDManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
//        IOHIDManagerOpen(ioHIDManager, IOOptionBits(kIOHIDOptionsTypeNone))
//
//        print("HID Manager setup complete")
//    }
//
//    let deviceMatchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
//        print("Guitar Hero controller connected: \(device)")
//        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context!).takeUnretainedValue()
//        IOHIDDeviceRegisterInputReportCallback(device, UnsafeMutablePointer<UInt8>.allocate(capacity: 256), 256, selfPointer.inputReportCallback, nil)
//    }
//
//    let deviceRemovalCallback: IOHIDDeviceCallback = { context, result, sender, device in
//        print("Guitar Hero controller disconnected")
//    }
//
//    let inputReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
//        let reportData = Data(bytes: report, count: reportLength)
//        print("Received HID report: \(reportData)")
//    }
//    
//    
//}
