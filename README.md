# Thuraya Flutter Frontend

This project is the Flutter mobile client for Thuraya. The Home map uses
MapLibre with OpenFreeMap and loads restaurant marker data from the Thuraya
backend's visible-bounds endpoint.

## Structure

```text
lib/
  core/
    constants/   Shared spacing and asset paths
    network/     Minimal API URL and JSON HTTP client
    routing/     Route names and route creation
    theme/       Colors, typography, and ThemeData
  features/
    home/        Home map, supported regions, location, and marker loading
    trending/    Arabic trending screen implemented from Figma
  l10n/          English/Arabic source strings and generated localization code
  app.dart       MaterialApp configuration
  main.dart      Application entry point
```

Feature screens should be added under `lib/features/<feature>/presentation/`.
Add shared widgets under `lib/core/widgets/` only after a real reuse case
exists.

## Assets

- Put raster images in `assets/images/`.
- Put image-based icons in `assets/icons/`.
- Put approved font files in `assets/fonts/`, then register them in
  `pubspec.yaml`.
- Add asset path constants to `AppAssets` instead of repeating string paths.

The image and icon directories and Tajawal font weights used by the supplied
Figma screen are registered in `pubspec.yaml`.

## Localization and RTL

User-facing strings belong in `lib/l10n/app_en.arb` and `app_ar.arb`. Flutter's
localization generation and Material delegates select Arabic and provide RTL
layout direction automatically. Prefer directional Flutter APIs such as
`EdgeInsetsDirectional`, `AlignmentDirectional`, and `start`/`end` so layouts
work in both directions.

## Run and verify

### Backend map endpoint

The Android emulator defaults to `http://10.0.2.2:5088`, which reaches the
backend running on the Windows host. The iOS simulator defaults to
`http://localhost:5088`. For a physical device or deployed environment, pass
the reachable API origin at build/run time:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5088
```

Use HTTPS for deployed builds. Android cleartext HTTP is enabled only for the
debug manifest, and iOS permits an HTTP exception only for `localhost`.

Start the backend from the repository root before running the Android app:

```powershell
dotnet run --project backend/src/Thuraya.Api/Thuraya.Api.csproj --launch-profile http
```

No Google Maps API key or billing account is used. The map uses the custom
Thuraya light style in `assets/map/thuraya_map_style.json`, based on OpenFreeMap
Bright data and resources. Marker requests are sent to `/api/restaurants/map`
after the map camera becomes idle. Tapping a restaurant annotation selects it and
shows a compact preview over the map. Tapping that preview opens the shared details
page and loads `/api/restaurants/{restaurantId}`; returning keeps the Home route
and its map state in the navigation stack.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```
