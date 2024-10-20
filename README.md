# GuitarHeroLiveMacOSController

**GuitarHeroLiveMacOsController** is a macOS application built using **IOKit** and **SwiftUI** to interface with the **Guitar Hero Live Wireless Controller**. This project provides real-time connection management, button press detection, and user-friendly feedback in the UI to guide users through the pairing process and controller interactions.

## Features:
- **Real-time HID Input Handling**: Captures and processes input from the Guitar Hero Live Wireless Controller using IOKit.
- **Connection Status Feedback**: Notifies the user when the controller is paired, connected, or disconnected.
- **Button Press Detection**: Detects and displays information on button presses and strumming in real-time.
- **SwiftUI-based User Interface**: A simple UI that shows connection status and allows users to reinitialize the driver if needed.

## How It Works:
1. **Initialize the Driver**: When the app is launched, it sets up the HID manager and waits for the Guitar Hero Live controller to connect via Bluetooth.
2. **Connection Detection**: Once paired, the app will notify the user with a "Controller Connected" message.
3. **Button Press Monitoring**: When a button is pressed or the strum bar is used, the app captures the HID report and displays the button press data in the UI.

## Requirements:
- **macOS** (Tested on macOS 14.6 or later)
- **Swift** 5.0
- **Xcode** 11 or later
- **Guitar Hero Live Wireless Controller**

## Usage:
1. Clone the repository:
   ```bash
   git clone https://github.com/kwalker430/GuitarHeroLiveMacOsController.git
