# Medisafe by Arian – Medication Reminder Prototype

This project is a simplified prototype inspired by the Medisafe app.  
It was created for the Apple Developer Academy challenge “CH2 – Developed Solution”.

## What the app does

- Shows a **blue header** with the user name and current date.
- Shows a **weekly day strip** where the selected day is highlighted.
- For each day it lists the **medications** with:
  - Time
  - Medication name
  - Dosage
  - Button to add a note about side effects / how the user felt.

## Features I implemented

**Add Notes / Side Effects**
   - Each medication row has an **“Add Note”** (or “Edit Note”) button.
   - Tapping it opens a full-screen editor.
   - The user can write how they felt after taking the drug (side effects, mood, etc.).
   - Notes are attached to that specific dose.

## Tech details

- **Language:** Swift
- **Framework:** SwiftUI
- **Minimum iOS:** 17 (simulator iPhone 17 / iPhone 16 used in testing)
- **Persistence:** `@AppStorage` for username (minimal persistence)

## How to run the project

1. Clone or download this repo.
2. Open `Medisafe.xcodeproj` in **Xcode**.
3. Select an **iPhone simulator** (e.g. iPhone 17) or a real device.
4. Press **Run** (⌘R).
