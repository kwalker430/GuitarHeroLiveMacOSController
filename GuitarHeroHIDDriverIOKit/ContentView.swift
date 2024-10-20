//
//  ContentView.swift
//  GuitarHeroHIDDriverIOKit
//
//  Created by Kevin Walker on 10/18/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var guitarHeroDriver = GuitarHeroHIDDriver()

    var body: some View {
        VStack {
            Text("Guitar Hero HID Driver")
                .font(.largeTitle)
                .padding()

            Spacer()

            // Show the current status message from the driver
            Text(guitarHeroDriver.statusMessage)
                .font(.headline)
                .padding()

            if guitarHeroDriver.isConnected {
                Text("Controller is connected!")
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("Controller is not connected.")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()

            // Optionally, add a button or action to force recheck connection
            Button(action: {
                guitarHeroDriver.setupHIDManager()
            }) {
                Text("Reinitialize Driver")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .onAppear {
            // Initialize the HID driver when the view appears
            guitarHeroDriver.setupHIDManager()

            // Start the run loop to listen for input from the device
            DispatchQueue.global().async {
                CFRunLoopRun()
            }
        }
    }
}
