# Pagination Helper

[![pub package](https://img.shields.io/pub/v/easy_pagination.svg)](https://pub.dev/packages/easy_pagination)
[![GitHub stars](https://img.shields.io/github/stars/ahmedemara231/pagination_helper.svg?style=social&label=Star)](https://github.com/ahmedemara231/pagination_helper)
[![GitHub forks](https://img.shields.io/github/forks/ahmedemara231/pagination_helper.svg?style=social&label=Fork)](https://github.com/ahmedemara231/pagination_helper/fork)
[![GitHub issues](https://img.shields.io/github/issues/ahmedemara231/pagination_helper.svg)](https://github.com/ahmedemara231/pagination_helper/issues)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible Flutter package for implementing pagination with both ListView and GridView support. This package handles infinite scrolling, loading states, error handling, and network connectivity checks automatically.

- ✅ **normal pagination**:
  
![Image](https://github.com/user-attachments/assets/b87c7a71-6495-4376-b1af-58c56bdd500b)

- ✅ **reverse pagination**:
  
![Image](https://github.com/user-attachments/assets/893daf9e-2bf9-410c-a075-b70941065f8c)

## 🚀 Features

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

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  easy_pagination: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Dependencies

This package uses the following dependencies:
- `connectivity_plus` - for network connectivity checking
- `dio` (optional) - for enhanced HTTP error handling
- `http` (optional) - for basic HTTP error handling
- `lottie` (optional) - for default loading animations

## 🎯 Quick Start

### Basic ListView Example

```dart
import 'package:flutter/material.dart';
import 'package:easy_pagination/easy_pagination.dart';

class MyPaginatedList extends StatefulWidget {
  @override
  _MyPaginatedListState createState() => _MyPaginatedListState();
}

class _MyPaginatedListState extends State<MyPaginatedList> {
  final EasyPaginationController<MyModel> controller = 
      EasyPaginationController<MyModel>();

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

### GridView Example

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

## 🔧 Advanced Usage

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
            onError: (context, page, e) {
            log('page : $page');
            if(e is PagifyNetworkException){
              log('check your internet connection');

            }else if(e is ApiRequestException){
              log('check your server ${e.msg}');

            }else{
              log('other error ...!');
            }
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

### Reverse Pagination (Chat-like)

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

## 🎮 Controller Methods

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

## 📊 Data Models

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

## 📋 API Reference

### ListView Parameters

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

### GridView Additional Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `crossAxisCount` | `int?` | Number of columns in grid |
| `childAspectRatio` | `double?` | Aspect ratio of grid items |
| `mainAxisSpacing` | `double?` | Spacing between rows |
| `crossAxisSpacing` | `double?` | Spacing between columns |

## 📱 Status Management

The package provides different status states through `AsyncCallStatus`:

```dart
enum PagifyAsyncCallStatus {
  initial,     // Initial state
  loading,     // Data is being loaded
  success,     // Data loaded successfully
  error,       // General error occurred
  networkError, // Network connectivity error
}
```

You can listen to status changes:

```dart
EasyPagination.listView(
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

## ⚠️ Error Handling Best Practices

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

## 💡 Best Practices

- **Always dispose controllers**: Call `controller.dispose()` in your widget's dispose method
- **Handle empty states**: Provide meaningful empty state messages
- **Implement proper error handling**: Use custom error builders for better user experience
- **Optimize item builders**: Keep item builders lightweight for smooth scrolling
- **Use appropriate page sizes**: Balance between performance and user experience
- **Handle network states**: Provide offline indicators when appropriate

## 📖 Example

For a complete example, check the `/example` folder in the package repository.

## 🐛 Troubleshooting

### Common Issues

- **Memory leaks**
  - Always call `controller.dispose()` in your widget's dispose method
  - Avoid holding references to controllers in static variables

## 🤝 Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) and submit pull requests to our repository.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

If you have any questions or need help with implementation, please [open an issue](https://github.com/ahmedemara231/pagination_helper/issues) on GitHub.

## ⭐ Show Your Support

If this package helped you, please give it a ⭐ on [GitHub](https://github.com/ahmedemara231/pagination_helper) and like it on [pub.dev](https://pub.dev/packages/pagify)!

---

Made with ❤️ by [Ahmed Emara](https://github.com/ahmedemara231)
[linkedIn](https://www.linkedin.com/in/ahmed-emara-11550526a/)
