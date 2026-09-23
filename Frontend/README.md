# SafeWay London - iOS app

This is the iOS app for my final year project, SafeWay London. It compares public transport routes in London (using TfL data) by how much **historical recorded crime** they pass near on the walking parts.

The app does **not** predict safety. It only compares past police-recorded crime data, so the app always says "exposure" and never "safe", "dangerous" or "risk".

## What it does

- Register / log in
- Search a journey between two places in London (or start from your current location)
- Compare the routes by time and by crime exposure
- Show each route on a map: tube lines in their TfL colours, buses in red, and walking parts dashed and coloured by exposure (green = lower, amber = moderate, orange-red = higher)
- Full-screen navigation that follows your location

## Tech stack

- Swift + SwiftUI (MVVM with `@Observable`)
- MapKit and CoreLocation
- JWT login, token saved in the Keychain
- Talks to the Node/Express backend with `URLSession` (async/await)
- No third-party libraries

## Setup

You need a **Mac with Xcode 16 or newer**. The app works on iOS 17 or newer (any iPhone simulator with iOS 17+). It cannot run on Windows.

**1. Start the backend first**

Follow the README in the `Backend` folder (`docker compose up -d`, then `npm run dev`). Check that http://localhost:3000/api/health opens in a browser and shows `"status":"ok"`.

**2. Run the app**

1. Open `SawayLondon.xcodeproj` in Xcode.
2. At the top, choose an iPhone simulator (iOS 17 or later).
3. Press **Cmd+R**.
4. When iOS asks for location permission, choose "Allow While Using App".

The small pill at the top of the home screen should say "API: ok" with a green dot. If it is red, the backend is not running.

**3. Try a journey**

1. Tap **Create Account** and register with any email and a password with at least 8 characters.
2. In the simulator, tap the x next to "Current Location" and type `Victoria Station` in **From**. Type `Liverpool Street Station` in **To**.
3. Tap **Compare routes**. If a list of places appears, pick one for each search.

You should see 2 or 3 routes. Tap a route to see it on the map.

The simulator has no GPS and its default location is in the USA (Cupertino), so "Current Location" will not find routes in London. To use it anyway, in the Simulator menu choose **Features > Location > Custom Location** and enter latitude `51.5152`, longitude `-0.1419` (central London).

## Project structure

```
SawayLondon/
├── SawayLondonApp.swift       # app entry point
├── ContentView.swift          # shows login or home depending on the session
├── Config/APIConfig.swift     # backend URL
├── Models/                    # User, Journey/Leg, ExposureBand
├── Auth/                      # SessionStore, KeychainService
├── Networking/                # APIClient, AuthAPI (auth + journey calls)
├── ViewModels/                # JourneyViewModel, RecentSearchesStore
├── Views/                     # all the screens
└── Utils/                     # location manager, colours, distance helpers
```

## Troubleshooting

| Problem | Fix |
|---|---|
| Pill at the top is red / "Connecting..." | The backend is not running, or the database is still loading. Check http://localhost:3000/api/health |
| "Getting location..." never ends, or "Current Location" says you are in the USA | Set a London location in the Simulator (Features > Location > Custom Location), or tap the x and type the start place |
| Build errors | Product > Clean Build Folder (Cmd+Shift+K), then run again |
| Running on a real iPhone | In [APIConfig.swift](SawayLondon/Config/APIConfig.swift) change `baseURL` to your Mac's IP (for example `http://192.168.1.20:3000`). Both must be on the same Wi-Fi. |

## Notes

- The backend URL is `http://localhost:3000` (plain HTTP). `Info.plist` has `NSAllowsLocalNetworking` so iOS allows this. A real deployment would need HTTPS.
- There are no payments or subscriptions. `PaywallView` and `Entitlements` are only placeholders.
