# Changelog

All notable changes to the **Pagify** package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.3.0]

### Added
- `Pagify.pageView` constructor for `PageView`-based pagination.
- `refresh` method on `PagifyController` to programmatically refresh data.
- `items` getter on `PagifyController` for direct access to the current list.
- Helper getters: `isLoading`, `isError`, `isSuccess` on `PagifyController`.
- `loadMore` method for manual pagination triggers.
- `listLength` getter for quick access to the current item count.

### Changed
- Improved refresh logic and scroll position handling.
- Initialized `_totalPages` for safer early access.

### Removed
- Lottie dependency and all Lottie-based animations.
- `PagifyRefreshIndicator` widget (refresh is now handled internally).

---

## [0.2.6]

### Added
- Support for both `ListView` and `GridView` implementations.
- `assignToFullData` function for use cases like search filtering.

### Changed
- Moved extensions to a dedicated directory for better code organization.

---

## [0.2.4]

### Added
- `PagifyFailure` data class with `statusCode` and `message` fields.
- `onScrollPositionChanged` callback property.

### Changed
- Enhanced reverse pagination with `itemExtent` support.
- Improved scroll performance with `cacheExtent` option.

---

## [0.2.0]

### Added
- `retry` function on `PagifyController`.
- `onConnectivityChanged` callback for network status changes.
- Helper functions: `isLoading`, `isError`, `isSuccess`.
- `loadMore` and list data access utilities on the controller.

### Changed
- Enhanced `onError` callback with `ApiRequestException` for full control over error handling.
- `BuildContext` is now provided in important callbacks.
- Toast notifications are now optional (removed by default).
- Fully documented all public APIs.

---

## [0.0.5]

### Added
- Network connectivity monitoring via `connectivity_plus`.
- Connection status stream for reactive network state handling.
- Reverse pagination support.
- `moveToTop` / `moveToBottom` controller methods.
- `currentPage` parameter in `onSuccess` and `onError` callbacks.
- Empty list state handling with customizable view.

### Changed
- Updated controller and main class architecture.
- Improved notification logic when adding new items.

### Fixed
- List alignment issues when using reverse mode.
- Adding elements to an empty list.

---

## [0.0.3]

### Added
- No-more-data indicator when all pages are loaded.
- Example project for pub.dev.

### Changed
- Scroll physics set to `AlwaysScrollableScrollPhysics` to support `RefreshIndicator`.

### Fixed
- Asset path resolution.

---

## [0.0.1]

### Added
- Initial release of Pagify.
- Paginated data fetching with automatic scroll-based loading.
- Support for both **Dio** and **http** packages.
- `RefreshIndicator` integration with proper state management.
- Customizable error and loading widget builders.
- Network error handler with retry support.
- Controller pattern for managing pagination state.
