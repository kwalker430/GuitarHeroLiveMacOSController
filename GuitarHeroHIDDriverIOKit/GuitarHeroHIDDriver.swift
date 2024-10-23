//
//  GuitarHeroHIDDriver.swift
//  GuitarHeroHIDDriverIOKit
//
//  Created by Kevin Walker on 10/23/24.
//

import Foundation
import SwiftUI
import IOBluetooth
import IOKit.hid

class GuitarHeroHIDDriver: ObservableObject {
    var ioHIDManager: IOHIDManager!
    
    @Published var statusMessage: String = "Initializing..."
    @Published var isConnected: Bool = false
    
    // States to track button and strum bar inputs
    @Published var buttonState: UInt8 = 0
    @Published var axisState: Int8 = 0

    var inputBuffer = [UInt8]() // Buffer to accumulate multiple reports

    let expectedReportSize = 27 // Adjust to the actual expected report size

    init() {
        setupHIDManager()
    }

    // Set up the HID manager to detect the Guitar Hero Live controller
    func setupHIDManager() {
        ioHIDManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,  // HID Usage page for generic desktop
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_GamePad         // Usage ID for gamepad
        ]

        IOHIDManagerSetDeviceMatching(ioHIDManager, matchingDict as CFDictionary)
        
        // Pass self context to the callbacks
        IOHIDManagerRegisterDeviceMatchingCallback(ioHIDManager, deviceMatchingCallback, Unmanaged.passUnretained(self).toOpaque())
        IOHIDManagerRegisterDeviceRemovalCallback(ioHIDManager, deviceRemovalCallback, Unmanaged.passUnretained(self).toOpaque())

        IOHIDManagerScheduleWithRunLoop(ioHIDManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(ioHIDManager, IOOptionBits(kIOHIDOptionsTypeNone))

        DispatchQueue.main.async {
            self.statusMessage = "Waiting for Guitar Hero controller to connect..."
        }

        print("HID Manager setup complete")
    }

    // Callback when a matching device (Guitar Hero controller) is connected
    let deviceMatchingCallback: IOHIDDeviceCallback = { context, result, sender, device in
        guard let context = context else {
            print("Error: Context is nil")
            return
        }

        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context).takeUnretainedValue()

        DispatchQueue.main.async {
            selfPointer.isConnected = true
            selfPointer.statusMessage = "Guitar Hero controller connected! Listening for inputs..."
        }

        IOHIDDeviceRegisterInputReportCallback(device, UnsafeMutablePointer<UInt8>.allocate(capacity: 256), 256, selfPointer.inputReportCallback, Unmanaged.passUnretained(selfPointer).toOpaque())
    }

    // Callback when the Guitar Hero controller is removed
    let deviceRemovalCallback: IOHIDDeviceCallback = { context, result, sender, device in
        guard let context = context else {
            print("Error: Context is nil")
            return
        }

        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context).takeUnretainedValue()

        DispatchQueue.main.async {
            selfPointer.isConnected = false
            selfPointer.statusMessage = "Guitar Hero controller disconnected."
        }
    }

    // Callback to handle incoming HID reports (button presses, strumming, etc.)
    let inputReportCallback: IOHIDReportCallback = { context, result, sender, type, reportID, report, reportLength in
        guard reportLength > 0 else {
            print("Error: Received empty HID report")
            return
        }

        guard let context = context else {
            print("Error: Context is nil")
            return
        }

        let reportData = Data(bytes: report, count: reportLength)
        let selfPointer = Unmanaged<GuitarHeroHIDDriver>.fromOpaque(context).takeUnretainedValue()

        // Append report data to the buffer
        selfPointer.inputBuffer.append(contentsOf: reportData)

        // Process the buffer if it contains a full report
        if selfPointer.inputBuffer.count >= selfPointer.expectedReportSize {
            // Parse button data from reportData[0] and strum bar data from reportData[4]
            let buttonData = selfPointer.inputBuffer[0]  // Button data at byte 0
            let strumBarData = Int8(bitPattern: selfPointer.inputBuffer[4])  // Strum bar data at byte 4

            // Update the button state
            if buttonData != selfPointer.buttonState {
                print("Button pressed: \(buttonData)")
                selfPointer.buttonState = buttonData
            }

            // Update the strum bar state
            if strumBarData != selfPointer.axisState {
                print("Strum bar moved: \(strumBarData)")
                selfPointer.axisState = strumBarData
            }

            // Update UI with both button and strum bar states
            DispatchQueue.main.async {
                selfPointer.statusMessage = "Button: \(selfPointer.buttonState), Strum bar: \(selfPointer.axisState)"
            }

            // Clear the input buffer after processing
            selfPointer.inputBuffer.removeAll()
        }
    }
}
