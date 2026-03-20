# 🗺️ map_adapter_sdk

A Flutter SDK that provides a unified abstraction layer for multiple map providers such as Google Maps and Mapbox using an adapter-based architecture.

## 🚀 Overview

`map_adapter_sdk` is designed to decouple your application from specific map providers by introducing a clean and scalable architecture. It allows you to switch between map engines without modifying your business logic or UI.

## ✨ Features

* 🔄 Multi-provider support (Google Maps, Mapbox)
* 🧩 Adapter-based architecture
* 📍 Unified domain models (`MapLatLng`, `MapMarker`, `MapPolyline`, etc.)
* ⚡ Seamless provider switching
* 🧪 Easy to test and mock
* 🧱 Clean and maintainable architecture
* 🔌 Ready for future integrations (Huawei Maps, OpenStreetMap)

## 🏗️ Architecture

The SDK is organized into:

* **Models**: Platform-independent map entities
* **Adapters**: Provider-specific implementations
* **Controllers**: Unified API for map operations
* **Mappers**: Conversion between domain models and SDK types

## 🎯 Use Cases

* Applications that need to support multiple map providers
* Projects requiring flexibility and scalability
* Apps targeting different ecosystems (Google / Huawei)
* Teams avoiding vendor lock-in

## 📦 Example

```dart
final controller = PlatformMapController.init(...);

await controller.animateCameraLatLngZoom(
  MapLatLng(latitude: -2.17, longitude: -79.92),
  16,
);
```

## 🔮 Roadmap

* 🔹 Clustering support
* 🔹 Route drawing and navigation
* 🔹 Offline map support
* 🔹 AI-driven map interactions

## 🤝 Contributions

Contributions, issues, and feature requests are welcome.

## 📄 License

MIT License
