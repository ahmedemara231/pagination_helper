# Pagify

[![pub package](https://img.shields.io/pub/v/easy_pagination.svg)](https://pub.dev/packages/easy_pagination)
[![GitHub stars](https://img.shields.io/github/stars/ahmedemara231/pagination_helper.svg?style=social&label=Star)](https://github.com/ahmedemara231/pagination_helper)
[![GitHub forks](https://img.shields.io/github/forks/ahmedemara231/pagination_helper.svg?style=social&label=Fork)](https://github.com/ahmedemara231/pagination_helper/fork)
[![GitHub issues](https://img.shields.io/github/issues/ahmedemara231/pagination_helper.svg)](https://github.com/ahmedemara231/pagination_helper/issues)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful and flexible Flutter package for implementing paginated lists and grids with built-in loading states, error handling, and optional Advanced network connectivity management.


- ✅ **reverse pagination with grid view**

![Reverse Grid View](https://github.com/user-attachments/assets/2327113d-6de1-4d39-b340-8f14f94b70c8)

- ✅ **normal pagination with list view**

![Normal List View](https://github.com/user-attachments/assets/b87c7a71-6495-4376-b1af-58c56bdd500b)


## 🚀 Features

- 🔄 **Automatic Pagination**: Seamless infinite scrolling with customizable page loading
- 📱 **ListView & GridView Support**: Switch between list and grid layouts effortlessly  
- 🌐 **Network Connectivity**: Built-in network status monitoring and error handling
- 🎯 **Flexible Error Mapping**: Custom error handling for Dio and HTTP exceptions
- ↕️ **Reverse Pagination**: Support for reverse scrolling (chat-like interfaces)
- 🎨 **Customizable UI**: Custom loading, error, and empty state widgets
- 🎮 **Controller Support**: Programmatic control over data and scroll position
- 🔍 **Rich Data Operations**: Filter, sort, add, remove, and manipulate list data
- 📊 **Status Callbacks**: Real-time pagination status updates
- 🎭 **Lottie Animations**: Built-in animated loading and error states

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pagify: ^0.2.2
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

#### 1. ListView Implementation

```dart
import 'package:flutter/material.dart';
import 'package:pagify/pagify.dart';
import 'package:dio/dio.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaginatedListExample(),
    );
  }
}

class PaginatedListExample extends StatefulWidget {
  @override
  _PaginatedListExampleState createState() => _PaginatedListExampleState();
}

class _PaginatedListExampleState extends State<PaginatedListExample> {
  late PagifyController<Post> controller;

  @override
  void initState() {
    super.initState();
    controller = PagifyController<Post>();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paginated Posts')),
      body: Pagify<ApiResponse, Post>.listView(
        controller: controller,
        asyncCall: _fetchPosts,
        mapper: _mapResponse,
        errorMapper: _errorMapper,
        itemBuilder: _buildPostItem,
        onUpdateStatus: (status) {
          print('Pagination status: $status');
        },
      ),
    );
  }

  Future<ApiResponse> _fetchPosts(BuildContext context, int page) async {
    final dio = Dio();
    final response = await dio.get(
      'https://jsonplaceholder.typicode.com/posts',
      queryParameters: {'_page': page, '_limit': 10},
    );
    
    return ApiResponse.fromJson(response.data);
  }

  PagifyData<Post> _mapResponse(ApiResponse response) {
    return PagifyData<Post>(
      data: response.posts,
      paginationData: PaginationData(
        perPage: 10,
        totalPages: response.totalPages,
      ),
    );
  }

  PagifyErrorMapper get _errorMapper => PagifyErrorMapper(
    errorWhenDio: (DioException e) => 'Network error: ${e.message}',
    errorWhenHttp: (HttpException e) => 'HTTP error: ${e.message}',
  );

  Widget _buildPostItem(BuildContext context, List<Post> data, int index, Post post) {
    return ListTile(
      leading: CircleAvatar(child: Text('${post.id}')),
      title: Text(post.title),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
```

#### 2. GridView Implementation

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Photo Grid')),
    body: Pagify<PhotoResponse, Photo>.gridView(
      controller: controller,
      crossAxisCount: 2,
      childAspectRatio: 0.8,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      asyncCall: _fetchPhotos,
      mapper: _mapPhotoResponse,
      errorMapper: _errorMapper,
      itemBuilder: _buildPhotoCard,
    ),
  );
}

Widget _buildPhotoCard(BuildContext context, List<Photo> data, int index, Photo photo) {
  return Card(
    child: Column(
      children: [
        Expanded(
          child: Image.network(
            photo.thumbnailUrl,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            photo.title,
            style: TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
```

## 🎮 Controller Usage

The `PagifyController` provides powerful methods to manipulate your data:

```dart
class ControllerExample extends StatefulWidget {
  @override
  _ControllerExampleState createState() => _ControllerExampleState();
}

class _ControllerExampleState extends State<ControllerExample> {
  late PagifyController<Post> controller;

  @override
  void initState() {
    super.initState();
    controller = PagifyController<Post>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Controller Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _filterPosts,
          ),
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _sortPosts,
          ),
        ],
      ),
      body: Pagify<ApiResponse, Post>.listView(
        controller: controller,
        // ... other properties
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: _addRandomPost,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "scroll",
            onPressed: () => controller.moveToMaxBottom(),
            child: Icon(Icons.arrow_downward),
          ),
        ],
      ),
    );
  }

  void _filterPosts() {
    controller.filterAndUpdate((post) => post.title.contains('et'));
  }

  void _sortPosts() {
    controller.sort((a, b) => a.title.compareTo(b.title));
  }

  void _addRandomPost() {
    final randomPost = Post(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Post ${DateTime.now()}',
      body: 'This is a dynamically added post',
      userId: 1,
    );
    controller.addItem(randomPost);
  }
}
```

## 🔧 Advanced Configuration

### Network Connectivity Monitoring

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  listenToNetworkConnectivityChanges: true,
  onConnectivityChanged: (isConnected) {
    if (isConnected) {
      print('Network restored');
    } else {
      print('Network lost');
    }
  },
  noConnectionText: 'Please check your internet connection',
  // ... other properties
)
```

### Custom Loading and Error States

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  loadingBuilder: Container(
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.blue),
        SizedBox(height: 16),
        Text('Loading awesome content...'),
      ],
    ),
  ),
  errorBuilder: (PagifyException error) => Container(
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        SizedBox(height: 16),
        Text(error.msg, textAlign: TextAlign.center),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => controller.refresh(),
          child: Text('Retry'),
        ),
      ],
    ),
  ),
  emptyListView: Container(
    padding: EdgeInsets.all(20),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No posts available'),
      ],
    ),
  ),
  // ... other properties
)
```

### Reverse Pagination (Chat-like)

```dart
Pagify<MessageResponse, Message>.listView(
  controller: controller,
  isReverse: true,  // Messages appear from bottom
  asyncCall: _fetchMessages,
  mapper: _mapMessages,
  errorMapper: _errorMapper,
  itemBuilder: _buildMessage,
  onSuccess: (context, data) {
    print('Loaded ${data.length} messages');
  },
)
```

### Status Callbacks

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  onUpdateStatus: (PagifyAsyncCallStatus status) {
    switch (status) {
      case PagifyAsyncCallStatus.loading:
        print('Loading data...');
        break;
      case PagifyAsyncCallStatus.success:
        print('Data loaded successfully');
        break;
      case PagifyAsyncCallStatus.error:
        print('Error occurred');
        break;
      case PagifyAsyncCallStatus.networkError:
        print('Network error');
        break;
      case PagifyAsyncCallStatus.initial:
        print('Initial state');
        break;
    }
  },
  onLoading: () => print('About to start loading'),
  onSuccess: (context, data) => print('Success: ${data.length} items'),
  onError: (context, page, exception) => print('Error on page $page: ${exception.msg}'),
  // ... other properties
)
```

### retry function example (important)

```dart
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: Pagify<ExampleModel, String>.gridView(
            showNoDataAlert: true,
            onLoading: () => log('loading now ...!'),
            onSuccess: (context, data) => log('the data is ready $data'),
            onError: (context, page, e) async{
            await Future.delayed(const Duration(seconds: 2));
            count++;
            if(count > 3){
              return;
            }
            _controller.retry();
              log('page : $page');
              if(e is PagifyNetworkException){
                log('check your internet connection');

              }else if(e is ApiRequestException){
                log('check your server ${e.msg}');

              }else{
                log('other error ...!');
              }
            },
            controller: _controller,
            asyncCall: (context, page)async => await _fetchData(page),
            mapper: (response) => PagifyData(
                data: response.items,
                paginationData: PaginationData(
                  totalPages: response.totalPages,
                  perPage: 10,
                )
            ),
            itemBuilder: (context, data, index, element) => Center(
                child: AppText(element, fontSize: 20,).paddingSymmetric(vertical: 10)
            )
        )
    );
  }
```


## 📱 Controller Methods

| Method | Description |
|--------|-------------|
| `retry()` | remake the last request if it failed for example |
| `addItem(E item)` | Add item to the end of the list |
| `addItemAt(int index, E item)` | Insert item at specific index |
| `addAtBeginning(E item)` | Add item at the beginning |
| `removeItem(E item)` | Remove specific item |
| `removeAt(int index)` | Remove item at index |
| `removeWhere(bool Function(E) condition)` | Remove items matching condition |
| `replaceWith(int index, E item)` | Replace item at index |
| `filter(bool Function(E) condition)` | Get filtered list (non-destructive) |
| `filterAndUpdate(bool Function(E) condition)` | Filter and update list |
| `sort(int Function(E, E) compare)` | Sort list in-place |
| `clear()` | Remove all items |
| `getRandomItem()` | Get random item from list |
| `accessElement(int index)` | Safe access to item at index |
| `moveToMaxBottom()` | Scroll to bottom with animation |
| `moveToMaxTop()` | Scroll to top with animation |

## 🔄 Pagination Status

```dart
enum PagifyAsyncCallStatus {
  initial,      // Before first request
  loading,      // Request in progress
  success,      // Request completed successfully
  error,        // General error occurred
  networkError, // Network connectivity error
}
```

## 🎯 Error Handling

```dart
PagifyErrorMapper(
  errorWhenDio: (DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server response timeout.';
      case DioExceptionType.badResponse:
        return 'Server returned ${e.response?.statusCode}';
      default:
        return 'Network error occurred.';
    }
  },
  errorWhenHttp: (HttpException e) => 'HTTP Error: ${e.message}',
)
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⭐ Show Your Support

If this package helped you, please give it a ⭐ on [GitHub](https://github.com/ahmedemara231/pagination_helper) and like it on [pub.dev](https://pub.dev/packages/pagify)!

---

Made ❤️ by [Ahmed Emara](https://github.com/ahmedemara231)
[linkedIn](https://www.linkedin.com/in/ahmed-emara-11550526a/)
