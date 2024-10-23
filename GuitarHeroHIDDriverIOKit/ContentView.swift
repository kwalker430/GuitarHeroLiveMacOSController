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

            // Display the current status message from the driver
            Text(guitarHeroDriver.statusMessage)
                .font(.headline)
                .padding()

            // Show the button and strum bar state if connected
            if guitarHeroDriver.isConnected {
                Text("Controller is connected!")
                    .foregroundColor(.green)
                    .padding()

                Text("Button State: \(guitarHeroDriver.buttonState)")
                    .padding()
                
                Text("Strum Bar Position: \(guitarHeroDriver.axisState)")
                    .padding()
            } else {
                Text("Controller is not connected.")
                    .foregroundColor(.red)
                    .padding()
            }

            Spacer()

            // Button to reinitialize the driver
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
            guitarHeroDriver.setupHIDManager()

            // Start the run loop in a background thread
            DispatchQueue.global().async {
                CFRunLoopRun()
            }
        }
    }
}
