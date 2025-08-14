# Pagify

A powerful and flexible Flutter package for implementing pagination with both ListView and GridView support. This package handles infinite scrolling, pull-to-refresh, loading states, error handling, and network connectivity checks automatically.

## Features

- ✅ **Dual View Support**: Both ListView and GridView implementations
- ✅ **Infinite Scrolling**: Automatic loading of next pages when scrolling reaches the end
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
  pagify: ^0.0.8
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
class ExampleModel{
  List<String> items;
  int totalPages;

  ExampleModel({
    required this.items,
    required this.totalPages
  });
}

class PagifyExample extends StatefulWidget {
  const PagifyExample({super.key});

  @override
  State<PagifyExample> createState() => _PagifyExampleState();
}

class _PagifyExampleState extends State<PagifyExample> {
  Future<ExampleModel> _fetchData(int currentPage) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate api call with current page
    final items = List.generate(25, (index) => 'Item $index');
    return ExampleModel(items: items, totalPages: 4);
  }

  late PagifyController<String> _PagifyController;
  @override
  void initState() {
    _PagifyController = PagifyController<String>();
    super.initState();
  }

  @override
  void dispose() {
    _PagifyController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: Pagify<ExampleModel, String>.listView(
          controller: _PagifyController,
          asyncCall: (page)async => await _fetchData(page),
          mapper: (response) => PagifyData(
              data: response.items,
              paginationData: PaginationData(
                totalPages: response.totalPages,
                perPage: 10,
              )
          ),
          errorMapper: ErrorMapper(
            errorWhenDio: (e) => e.response?.data['errorMsg'], // if you using Dio
            errorWhenHttp: (e) => e.message, // if you using Http
          ),
          itemBuilder: (data, index, element) => Text(data[index])
        )
      ),
    );
  }
}

### GridView Implementation

```dart
Pagify<ExampleModel, String>.gridView(
          childAspectRatio: 2,
          mainAxisSpacing: 10,
          crossAxisCount: 12,
          controller: _PagifyController,
          asyncCall: (page)async => await _fetchData(page),
          mapper: (response) => PagifyData(
              data: response.items,
              paginationData: PaginationData(
                totalPages: response.totalPages,
                perPage: 10,
              )
          ),
          errorMapper: ErrorMapper(
            errorWhenDio: (e) => e.response?.data['errorMsg'], // if you using Dio
            errorWhenHttp: (e) => e.message, // if you using Http
          ),
          itemBuilder: (data, index, element) => Text(data[index])
        )
```

### Custom Loading Widget

```dart
Pagify<ExampleModel, String>.listView(
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
Pagify<ExampleModel, String>.listView(
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

The `PagifyController` provides various methods to programmatically control the pagination:

```dart
final controller = PagifyController<MyModel>();

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

Your API response should be mappable to `PagifyData`:

```dart
class ApiResponse {
  final List<MyModel> items;
  final int perPage;
  final int totalPages;

  ApiResponse({
    required this.items,
    required this.perPage,
    required this.totalPages,
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

### Pagify.listView Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `controller` | `PagifyController<Model>` | Controller for managing pagination state | ✅ |
| `asyncCall` | `Future<Response> Function(int currentPage)` | Function to fetch data for given page | ✅ |
| `mapper` | `PagifyControllerData<Model> Function(Response)` | Maps API response to required format | ✅ |
| `errorMapper` | `ErrorMapper` | Handles different types of errors | ✅ |
| `itemBuilder` | `Widget Function(List<Model>, int, Model)` | Builds individual list items | ✅ |
| `onUpdateStatus` | `FutureOr<void> Function(PagifyAsyncCallStatus)?` | Callback for status changes | ❌ |
| `isReverse` | `bool` | Enable reverse pagination | ❌ |
| `onSuccess` | `Function(int currentPage, List<Model> data)?` | Success callback | ❌ |
| `onError` | `Function(int currentPage, String errorMessage)?` | Error callback | ❌ |
| `loadingBuilder` | `Widget?` | Custom loading widget | ❌ |
| `errorBuilder` | `Widget Function(String errorMsg)?` | Custom error widget | ❌ |
| `shrinkWrap` | `bool?` | ListView shrinkWrap property | ❌ |
| `scrollDirection` | `Axis?` | Scroll direction | ❌ |
| `emptyListText` | `String?` | Text shown when list is empty | ❌ |
| `noConnectionText` | `String?` | Text shown when no internet connection | ❌ |

### Pagify.gridView Additional Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `crossAxisCount` | `int?` | Number of columns in grid |
| `childAspectRatio` | `double?` | Aspect ratio of grid items |
| `mainAxisSpacing` | `double?` | Spacing between rows |
| `crossAxisSpacing` | `double?` | Spacing between columns |

## Async Call Status

The package provides different status states through `PagifyAsyncCallStatus`:

```dart
enum PagifyAsyncCallStatus {
  initial,    // Initial state
  loading,    // Data is being loaded
  success,    // Data loaded successfully
  error,      // General error occurred
  networkError, // Network connectivity error
}
```

You can listen to status changes:

```dart
Pagify.listView(
  // ... other parameters
  onUpdateStatus: (status) {
    switch (status) {
      case PagifyAsyncCallStatus.loading:
        // Show loading indicator in app bar
        break;
      case PagifyAsyncCallStatus.error:
        // Show error snackbar
        break;
      case PagifyAsyncCallStatus.networkError:
        // Show network error dialog
        break;
      case PagifyAsyncCallStatus.success:
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
