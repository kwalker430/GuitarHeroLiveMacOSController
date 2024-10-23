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
        //IOHIDManagerOpen(ioHIDManager, IOOptionBits(kIOHIDOptionsTypeSeizeDevice)) // uncomment this to lock input to our app only
        
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

        // Log the raw HID report data for debugging
        print("HID report data: \(reportData.map { String(format: "%02x", $0) })")

        // Parse the button input (assuming button input is at index 0)
        let buttonData = reportData[0]
        var newButtonState: UInt8? = nil
        if buttonData != selfPointer.buttonState {
            newButtonState = buttonData
            print("Button state updated: \(buttonData)")
        }

        // Parse the strum bar input (assuming strum bar data is at index 4)
        let strumBarData = Int8(bitPattern: reportData[4])
        var newAxisState: Int8? = nil

        // Ensure the strum bar input is processed even when a button is held down
        if strumBarData == -128 && newButtonState != nil {
            // Ignore this reset if caused by a button press
            print("Ignoring strum bar reset to neutral (-128) caused by button press")
        } else if strumBarData == -1 || strumBarData == 0 {
            // Always update strum bar when it's in a valid state (-1 or 0)
            newAxisState = strumBarData
            print("Strum bar state updated: \(strumBarData)")
        }

        // Update the button state and strum bar state independently, ensuring neither is blocked
        if let newButtonState = newButtonState {
            selfPointer.buttonState = newButtonState
        }
        if let newAxisState = newAxisState {
            selfPointer.axisState = newAxisState
        }

        // Update the UI with the current state of both inputs
        DispatchQueue.main.async {
            selfPointer.statusMessage = "Button: \(selfPointer.buttonState), Strum bar: \(selfPointer.axisState)"
        }
    }
}
