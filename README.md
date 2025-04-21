# Easy Pagination

A flexible and customizable Flutter package for handling paginated data with minimal setup.

## Features

- Support for both ListView and GridView pagination
- Automatic pagination handling on scroll
- Pull-to-refresh functionality
- Customizable loading and error states
- Network connectivity handling
- Controller for advanced data manipulation

## Installation

Add this to your `pubspec.yaml` file:

```yaml
dependencies:
  easy_pagination: ^0.0.1
```

Then run:

```
flutter pub get
```

## Usage

### Basic Example

```dart
EasyPagination<ApiResponse, DataModel>.listView(
  asyncCall: (page) => apiService.fetchData(page),
  mapper: (response) => DataListAndPaginationData(
    data: response.items,
    paginationData: PaginationData(
      totalPages: response.totalPages,
    )
  ),
  errorMapper: ErrorMapper(
    errorWhenDio: (e) => 'Network error occurred',
    errorWhenHttp: (e) => 'Server error occurred',
  ),
  itemBuilder: (data, index) => ListTile(
    title: Text(data[index].title),
    subtitle: Text(data[index].description),
  ),
)
```

### GridView Example

```dart
EasyPagination<ApiResponse, DataModel>.gridView(
  asyncCall: (page) => apiService.fetchData(page),
  mapper: (response) => DataListAndPaginationData(
    data: response.items,
    paginationData: PaginationData(
      totalPages: response.totalPages,
    )
  ),
  errorMapper: ErrorMapper(
    errorWhenDio: (e) => 'Network error occurred',
    errorWhenHttp: (e) => 'Server error occurred',
  ),
  itemBuilder: (data, index) => Card(
    child: Column(
      children: [
        Image.network(data[index].imageUrl),
        Text(data[index].title)
      ],
    ),
  ),
  crossAxisCount: 2,
  childAspectRatio: 0.75,
  mainAxisSpacing: 10,
  crossAxisSpacing: 10,
)
```

## Parameters

### Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `asyncCall` | `Future<T> Function(int currentPage)` | Function to fetch a page of data |
| `mapper` | `DataListAndPaginationData<E> Function(T response)` | Function to map the API response to data and pagination information |
| `errorMapper` | `ErrorMapper` | Object that maps different error types to error messages |
| `itemBuilder` | `Widget Function(List<E> data, int index)` | Builder function for list items |
| `onSuccess` | `Function(List<E> data)?` | Optional callback when data is successfully loaded |
| `onError` | `Function(String errorMessage)?` | Optional callback when an error occurs |
| `scrollPhysics` | `ScrollPhysics?` | Optional scroll physics for the list |
| `showNoDataAlert` | `bool` | Whether to show an alert when there is no more data |
| `refreshIndicatorBackgroundColor` | `Color?` | Background color for the refresh indicator |
| `refreshIndicatorColor` | `Color?` | Color for the refresh indicator |
| `loadingBuilder` | `Widget?` | Custom widget for loading state |
| `errorBuilder` | `Widget Function(String errorMsg)?` | Custom builder for error state |
| `controller` | `EasyPaginationController<E>?` | Optional controller for advanced data manipulation |
| `shrinkWrap` | `bool?` | Whether the list should shrink-wrap its contents |
| `scrollDirection` | `Axis?` | Direction in which the list scrolls |

### GridView Specific Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `crossAxisCount` | `int?` | Number of columns in the grid |
| `mainAxisSpacing` | `double?` | Space between rows |
| `crossAxisSpacing` | `double?` | Space between columns |
| `childAspectRatio` | `double?` | Aspect ratio of grid items |

## Advanced Usage

### Using the EasyPaginationController

```dart
final controller = EasyPaginationController<DataModel>();

// Later in your code
EasyPagination<ApiResponse, DataModel>.listView(
  controller: controller,
  // other parameters...
)

// Access and manipulate data
final randomItem = controller.getRandomItem();
final filteredItems = controller.filter((item) => item.isActive);
controller.sort((a, b) => a.name.compareTo(b.name));
```

## Error Handling

The package handles different types of errors:

1. **Network Errors**: Automatically detected and displayed with appropriate UI
2. **API Errors**: Handled based on your `ErrorMapper` configuration
3. **General Exceptions**: Captured and presented with fallback UIs

## Dependencies

This package requires:
- `dio`: For network requests
- `connectivity_plus`: For network connectivity checking
- `lottie`: For animated loading and error states

## License

This package is available under the MIT License.
