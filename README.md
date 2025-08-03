# EasyPagination

A powerful and flexible Flutter package for implementing pagination with both ListView and GridView support. This package handles infinite scrolling, pull-to-refresh, loading states, error handling, and network connectivity checks automatically.

## Features

- ✅ **Dual View Support**: Both ListView and GridView implementations
- ✅ **Infinite Scrolling**: Automatic loading of next pages when scrolling reaches the end
- ✅ **Pull-to-Refresh**: Built-in refresh indicator support
- ✅ **Network Awareness**: Automatic network connectivity checking
- ✅ **Error Handling**: Comprehensive error handling for HTTP and Dio exceptions
- ✅ **Loading States**: Customizable loading indicators and states
- ✅ **Reverse Pagination**: Support for reverse scrolling (useful for chat interfaces)
- ✅ **Controller Support**: Programmatic control over pagination data and scroll behavior
- ✅ **Customizable UI**: Custom error builders, loading widgets, and empty state messages
- ✅ **Memory Efficient**: Optimized scroll position retention during data loading

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  easy_pagination: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Dependencies

This package uses the following dependencies:
- `connectivity_plus` - for network connectivity checking
- `dio - http` (optional) - for enhanced HTTP error handling
- `lottie` (optional) - for default loading animations

## Basic Usage

### ListView Implementation

```dart
import 'package:flutter/material.dart';
import 'package:easy_pagination/easy_pagination.dart';

class MyPaginatedList extends StatefulWidget {
  @override
  _MyPaginatedListState createState() => _MyPaginatedListState();
}

class _MyPaginatedListState extends State<MyPaginatedList> {
  final EasyPaginationController<MyModel> controller = EasyPaginationController<MyModel>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paginated List')),
      body: EasyPagination.listView(
        controller: controller,
        asyncCall: (currentPage) => fetchData(currentPage),
        mapper: (response) => DataListAndPaginationData(
          data: response.items,
          paginationData: PaginationData(
            perPage: response.perPage,
            totalPages: response.totalPages,
          ),
        ),
        errorMapper: ErrorMapper(
          errorWhenDio: (e) => "Network error: ${e.message}",
          errorWhenHttp: (e) => "HTTP error: ${e.message}",
        ),
        itemBuilder: (data, index, item) => ListTile(
          title: Text(item.title),
          subtitle: Text(item.description),
        ),
      ),
    );
  }

  Future<ApiResponse> fetchData(int page) async {
    // Your API call implementation
    final response = await apiService.getData(page: page);
    return ApiResponse.fromJson(response.data);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### GridView Implementation

```dart
EasyPagination.gridView(
  controller: controller,
  crossAxisCount: 2,
  childAspectRatio: 0.8,
  mainAxisSpacing: 10.0,
  crossAxisSpacing: 10.0,
  asyncCall: (currentPage) => fetchData(currentPage),
  mapper: (response) => DataListAndPaginationData(
    data: response.items,
    paginationData: PaginationData(
      perPage: response.perPage,
      totalPages: response.totalPages,
    ),
  ),
  errorMapper: ErrorMapper(
    errorWhenDio: (e) => "Error: ${e.message}",
  ),
  itemBuilder: (data, index, item) => Card(
    child: Column(
      children: [
        Image.network(item.imageUrl),
        Text(item.title),
      ],
    ),
  ),
)
```

## Advanced Configuration

### Custom Error Handling

```dart
EasyPagination.listView(
  // ... other parameters
  errorMapper: ErrorMapper(
    errorWhenDio: (DioException e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return "Connection timeout. Please try again.";
        case DioExceptionType.receiveTimeout:
          return "Server response timeout.";
        case DioExceptionType.badResponse:
          return "Server error: ${e.response?.statusCode}";
        default:
          return "Network error occurred.";
      }
    },
    errorWhenHttp: (HttpException e) => "HTTP Error: ${e.message}",
  ),
  onError: (currentPage, errorMessage) {
    print("Error on page $currentPage: $errorMessage");
    // Handle error (show snackbar, log, etc.)
  },
  errorBuilder: (errorMsg) => Container(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [
        Icon(Icons.error, color: Colors.red, size: 64),
        SizedBox(height: 16),
        Text(errorMsg, textAlign: TextAlign.center),
        ElevatedButton(
          onPressed: () => controller.refresh(),
          child: Text('Retry'),
        ),
      ],
    ),
  ),
)
```

### Custom Loading Widget

```dart
EasyPagination.listView(
  // ... other parameters
  loadingBuilder: Container(
    height: 100,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 8),
          Text('Loading more items...'),
        ],
      ),
    ),
  ),
)
```

### Reverse Pagination (Chat-like Interface)

```dart
EasyPagination.listView(
  controller: controller,
  isReverse: true, // Enable reverse pagination
  asyncCall: (currentPage) => fetchOlderMessages(currentPage),
  mapper: (response) => DataListAndPaginationData(
    data: response.messages,
    paginationData: PaginationData(
      perPage: response.perPage,
      totalPages: response.totalPages,
    ),
  ),
  // ... rest of configuration
)
```

## Controller Methods

The `EasyPaginationController` provides various methods to programmatically control the pagination:

```dart
final controller = EasyPaginationController<MyModel>();

// Add items
controller.addItem(newItem);
controller.addItemAt(0, newItem);
controller.addAtBeginning(newItem);

// Remove items
controller.removeItem(item);
controller.removeAt(index);
controller.removeWhere((item) => item.id == targetId);

// Update items
controller.replaceWith(index, updatedItem);

// Filter and sort
controller.filterAndUpdate((item) => item.isActive);
controller.sort((a, b) => a.name.compareTo(b.name));

// Access items
MyModel? item = controller.accessElement(index);
MyModel? randomItem = controller.getRandomItem();
List<MyModel> filteredItems = controller.filter((item) => item.category == 'active');

// Scroll control
await controller.moveToMaxBottom();
await controller.moveToMaxTop();

// Refresh
controller.refresh();

// Clear all items
controller.clear();
```

## Data Models

### Required Response Structure

Your API response should be mappable to `DataListAndPaginationData`:

```dart
class ApiResponse {
  final List<MyModel> items;
  final int perPage;
  final int totalPages;
  final int currentPage;

  ApiResponse({
    required this.items,
    required this.perPage,
    required this.totalPages,
    required this.currentPage,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      items: (json['data'] as List).map((item) => MyModel.fromJson(item)).toList(),
      perPage: json['per_page'],
      totalPages: json['last_page'],
      currentPage: json['current_page'],
    );
  }
}
```

### Model Example

```dart
class MyModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;

  MyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }
}
```

## Configuration Parameters

### EasyPagination.listView Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `controller` | `EasyPaginationController<Model>` | Controller for managing pagination state | ✅ |
| `asyncCall` | `Future<Response> Function(int currentPage)` | Function to fetch data for given page | ✅ |
| `mapper` | `DataListAndPaginationData<Model> Function(Response)` | Maps API response to required format | ✅ |
| `errorMapper` | `ErrorMapper` | Handles different types of errors | ✅ |
| `itemBuilder` | `Widget Function(List<Model>, int, Model)` | Builds individual list items | ✅ |
| `onUpdateStatus` | `FutureOr<void> Function(AsyncCallStatus)?` | Callback for status changes | ❌ |
| `isReverse` | `bool` | Enable reverse pagination | ❌ |
| `onSuccess` | `Function(int currentPage, List<Model> data)?` | Success callback | ❌ |
| `onError` | `Function(int currentPage, String errorMessage)?` | Error callback | ❌ |
| `loadingBuilder` | `Widget?` | Custom loading widget | ❌ |
| `errorBuilder` | `Widget Function(String errorMsg)?` | Custom error widget | ❌ |
| `shrinkWrap` | `bool?` | ListView shrinkWrap property | ❌ |
| `scrollDirection` | `Axis?` | Scroll direction | ❌ |
| `emptyListText` | `String?` | Text shown when list is empty | ❌ |
| `noConnectionText` | `String?` | Text shown when no internet connection | ❌ |

### EasyPagination.gridView Additional Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `crossAxisCount` | `int?` | Number of columns in grid |
| `childAspectRatio` | `double?` | Aspect ratio of grid items |
| `mainAxisSpacing` | `double?` | Spacing between rows |
| `crossAxisSpacing` | `double?` | Spacing between columns |

## Async Call Status

The package provides different status states through `AsyncCallStatus`:

```dart
enum AsyncCallStatus {
  initial,    // Initial state
  loading,    // Data is being loaded
  success,    // Data loaded successfully
  error,      // General error occurred
  networkError, // Network connectivity error
}
```

You can listen to status changes:

```dart
EasyPagination.listView(
  // ... other parameters
  onUpdateStatus: (status) {
    switch (status) {
      case AsyncCallStatus.loading:
        // Show loading indicator in app bar
        break;
      case AsyncCallStatus.error:
        // Show error snackbar
        break;
      case AsyncCallStatus.networkError:
        // Show network error dialog
        break;
      case AsyncCallStatus.success:
        // Hide any error states
        break;
    }
  },
)
```

## Error Handling

### Custom Error Messages

```dart
ErrorMapper(
  errorWhenDio: (DioException e) {
    if (e.response?.statusCode == 401) {
      return "Authentication failed. Please login again.";
    } else if (e.response?.statusCode == 404) {
      return "Data not found.";
    } else if (e.response?.statusCode == 500) {
      return "Server error. Please try again later.";
    }
    return "Something went wrong.";
  },
  errorWhenHttp: (HttpException e) => "Connection error: ${e.message}",
)
```

## Best Practices

1. **Always dispose controllers**: Call `controller.dispose()` in your widget's dispose method
2. **Handle empty states**: Provide meaningful empty state messages
3. **Implement proper error handling**: Use custom error builders for better user experience
4. **Optimize item builders**: Keep item builders lightweight for smooth scrolling
5. **Use appropriate page sizes**: Balance between performance and user experience
6. **Handle network states**: Provide offline indicators when appropriate

## Example Project

For a complete example, check the `/example` folder in the package repository.

## Troubleshooting

### Common Issues

1. **Controller not updating UI**
   - Ensure you're calling `controller.refresh()` after manual data changes
   - Verify the controller is properly initialized

2. **Network errors not handled**
   - Make sure `connectivity_plus` is properly added to dependencies
   - Implement both `errorWhenDio` and `errorWhenHttp` in ErrorMapper

3. **Scroll position not retained**
   - This is handled automatically by `RetainableScrollController`
   - If issues persist, check if you're modifying data outside the controller

4. **Memory leaks**
   - Always call `controller.dispose()` in your widget's dispose method
   - Avoid holding references to controllers in static variables

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### Version 1.0.0
- Initial release
- ListView and GridView support
- Network connectivity checking
- Comprehensive error handling
- Controller-based data management
