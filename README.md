# Pagify

[![pub package](https://img.shields.io/pub/v/easy_pagination.svg)](https://pub.dev/packages/easy_pagination)
[![GitHub stars](https://img.shields.io/github/stars/ahmedemara231/pagination_helper.svg?style=social&label=Star)](https://github.com/ahmedemara231/pagination_helper)
[![GitHub forks](https://img.shields.io/github/forks/ahmedemara231/pagination_helper.svg?style=social&label=Fork)](https://github.com/ahmedemara231/pagination_helper/fork)
[![GitHub issues](https://img.shields.io/github/issues/ahmedemara231/pagination_helper.svg)](https://github.com/ahmedemara231/pagination_helper/issues)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/emara24)

A powerful and flexible Flutter package for implementing paginated lists and grids with built-in loading states, error handling, and optional Advanced network connectivity management.


- ✅ **reverse pagination with grid view**

![Reverse Grid View](https://github.com/user-attachments/assets/2327113d-6de1-4d39-b340-8f14f94b70c8)

- ✅ **normal pagination with list view**

![Normal List View](https://github.com/user-attachments/assets/b87c7a71-6495-4376-b1af-58c56bdd500b)


## 🚀 Features

- 🔄 **Automatic Pagination**: Seamless infinite scrolling with customizable page loading
- 📱 **ListView, GridView & PageView Support**: Switch between list, grid, and page layouts effortlessly
- 🌐 **Network Connectivity**: Built-in network status monitoring and error handling
- 🎯 **Flexible Error Mapping**: Custom error handling for Dio and HTTP exceptions
- ↕️ **Reverse Pagination**: Support for reverse scrolling (chat-like interfaces)
- 🎨 **Customizable UI**: Custom loading, error, and empty state widgets
- 🎮 **Controller Support**: Programmatic control over data and scroll position
- 🔍 **Rich Data Operations**: Filter, sort, add, remove, and manipulate list data
- 📊 **Status Callbacks**: Real-time pagination status updates
- ⚡ **State Getters**: Access loading, success, and error states directly from controller
- 🔃 **Manual Load More**: Programmatically trigger pagination to load next page
- 📋 **Items Access**: Get current data list and length at any time
- 💾 **Offline Caching**: Built-in support for caching data locally and restoring it when offline
- 🔁 **Refresh & Reload**: Reset to page 1 or mark list as changed programmatically
- 📍 **Scroll Position Callbacks**: React to scroll reaching top, bottom, or middle

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pagify: <latest>
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

## 🎯 Quick Start

#### 1. ListView Implementation

```dart
import 'package:flutter/material.dart';
import 'package:pagify/pagify.dart';
import 'package:dio/dio.dart';

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
    errorWhenDio: (DioException e) => PagifyApiRequestException(
      e.message ?? 'Network error',
      pagifyFailure: RequestFailureData(
        statusCode: e.response?.statusCode,
        statusMsg: e.response?.statusMessage,
      ),
    ),
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

#### 3. PageView Implementation

```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Paginated Pages')),
    body: Pagify<ArticleResponse, Article>.pageView(
      controller: controller,
      asyncCall: _fetchArticles,
      mapper: _mapArticleResponse,
      errorMapper: _errorMapper,
      itemBuilder: _buildArticlePage,
      pageSnapping: true,
      allowImplicitScrolling: false,
      onPageChanged: (index) {
        print('Now on page $index');
      },
    ),
  );
}

Widget _buildArticlePage(BuildContext context, List<Article> data, int index, Article article) {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(article.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text(article.body),
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

### Using Advanced Controller Features

```dart
class _AdvancedControllerExampleState extends State<AdvancedControllerExample> {
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
        title: Text('Advanced Features Demo'),
        actions: [
          if (controller.isLoading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Total Items: ${controller.getItemsLength}'),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            color: controller.isSuccess ? Colors.green :
                   controller.isError ? Colors.red : Colors.grey,
            child: Text(
              controller.isSuccess ? 'Success' :
              controller.isError ? 'Error' :
              controller.isLoading ? 'Loading...' : 'Ready',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Pagify<ApiResponse, Post>.listView(
              controller: controller,
              // ... other properties
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "loadMore",
            onPressed: () async {
              await controller.loadMore();
              print('Current items: ${controller.items.length}');
            },
            child: Icon(Icons.refresh),
            tooltip: 'Load More',
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: () => controller.refresh(), // Reset to page 1
            child: Icon(Icons.replay),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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

### Scroll Position Callbacks

Use `onScrollPositionChanged` to react when the user reaches the top, bottom, or middle of the list.

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  onScrollPositionChanged: (position, isMaxTop, isMaxBottom, isMiddle) {
    if (isMaxBottom) {
      print('Reached the bottom');
    } else if (isMaxTop) {
      print('Reached the top');
    } else if (isMiddle) {
      print('Scrolling in the middle');
    }
  },
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

### Offline Caching

Enable offline support by providing a cache key and serialization functions. When the API call fails, Pagify will automatically restore data from the cache.

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  asyncCall: _fetchPosts,
  mapper: _mapResponse,
  errorMapper: _errorMapper,
  itemBuilder: _buildPostItem,

  // Cache configuration
  cacheKey: 'posts_cache',
  cacheToJson: (post) => post.toJson(),
  cacheFromJson: (json) => Post.fromJson(json),
  onSaveCache: (key, items) {
    // Persist to local storage (e.g., SharedPreferences, Hive, etc.)
    prefs.setString(key, jsonEncode(items));
  },
  onReadCache: (key) {
    // Restore from local storage; return null or [] if nothing cached
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  },
)
```

> All five cache parameters (`cacheKey`, `cacheToJson`, `cacheFromJson`, `onSaveCache`, `onReadCache`) must be provided together to enable caching.

### Suppress Error UI When List Has Data

Use `ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty` to keep the existing list visible when a subsequent page request fails, instead of replacing it with the error widget.

```dart
Pagify<ApiResponse, Post>.listView(
  controller: controller,
  ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty: true,
  // ... other properties
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
      case PagifyAsyncCallStatus.makeChangesInList:
        print('List was modified locally');
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

### Retry Example (important)

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
      onError: (context, page, e) async {
        await Future.delayed(const Duration(seconds: 2));
        count++;
        if (count > 3) return;
        _controller.retry();
        log('page : $page');
        if (e is PagifyNetworkException) {
          log('check your internet connection');
        } else if (e is PagifyApiRequestException) {
          log('check your server ${e.msg}');
        } else {
          log('other error ...!');
        }
      },
      controller: _controller,
      asyncCall: (context, page) async => await _fetchData(page),
      mapper: (response) => PagifyData(
        data: response.items,
        paginationData: PaginationData(
          totalPages: response.totalPages,
          perPage: 10,
        ),
      ),
      itemBuilder: (context, data, index, element) => Center(
        child: Text(element, style: TextStyle(fontSize: 20)),
      ),
    ),
  );
}
```


## 📱 Controller Methods & Properties

### Properties (Getters)

| Property | Type | Description |
|----------|------|-------------|
| `items` | `List<E>` | Get current data list (immutable copy) |
| `getItemsLength` | `int` | Get data list length |
| `isLoading` | `bool` | Check if current state is loading |
| `isSuccess` | `bool` | Check if current state is success |
| `isError` | `bool` | Check if current state is error |

### Methods

| Method | Description |
|--------|-------------|
| `loadMore()` | Force fetch data with the next page |
| `refresh()` | Reset and refetch from page 1 |
| `reload()` | Mark list as changed and refresh state |
| `retry()` | Remake the last failed request |
| `addItem(E item)` | Add item to the end of the list |
| `addItemAt(int index, E item)` | Insert item at specific index |
| `addAtBeginning(E item)` | Add item at the beginning |
| `removeItem(E item)` | Remove specific item |
| `removeAt(int index)` | Remove item at index |
| `removeWhere(bool Function(E) condition)` | Remove items matching condition |
| `replaceWith(int index, E item)` | Replace item at index |
| `filter(bool Function(E) condition)` | Get filtered list without modifying the source |
| `filterAndUpdate(bool Function(E) condition)` | Filter in-place and update the displayed list |
| `assignToFullData()` | Restore the list to the full unfiltered data |
| `sort(int Function(E, E) compare)` | Sort list in-place |
| `clear()` | Remove all items |
| `getRandomItem()` | Get a random item, or `null` if list is empty |
| `accessElement(int index)` | Safely access item at index; returns `null` if out of range |
| `moveToMaxBottom({Duration?, Curve?})` | Scroll to bottom with animation (default: 300ms, easeOutQuad) |
| `moveToMaxTop({Duration?, Curve?})` | Scroll to top with animation (default: 400ms, easeOutQuad) |
| `dispose()` | Dispose controller and release resources |

## 🔄 Pagination Status

```dart
enum PagifyAsyncCallStatus {
  initial,            // Before first request
  loading,            // Request in progress
  success,            // Request completed successfully
  makeChangesInList,  // List was modified locally (add/remove/sort/etc.)
  error,              // General error occurred
  networkError,       // Network connectivity error
}
```

## 📋 Full Widget Parameters Reference

### Common Parameters (all constructors)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `PagifyController<Model>` | required | Controls pagination state and data |
| `asyncCall` | `Future<FullResponse> Function(BuildContext, int)` | required | API call receiving page number |
| `mapper` | `PagifyData<Model> Function(FullResponse)` | required | Maps response to `PagifyData` |
| `errorMapper` | `PagifyErrorMapper` | required | Maps Dio/HTTP exceptions to Pagify errors |
| `itemBuilder` | `Widget Function(BuildContext, List<Model>, int, Model)` | required | Builds each list item |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | Padding around the list |
| `physics` | `ScrollPhysics?` | null | Scroll physics |
| `cacheExtent` | `double?` | null | Cache extent for the viewport |
| `isReverse` | `bool` | `false` | Reverse scroll direction |
| `showNoDataAlert` | `bool` | `false` | Show alert when no more data |
| `loadingBuilder` | `Widget?` | null | Custom loading indicator widget |
| `errorBuilder` | `Widget Function(PagifyException)?` | null | Custom error state widget |
| `emptyListView` | `Widget?` | null | Widget shown when list is empty |
| `ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty` | `bool` | `false` | Keep showing list when a later page fails |
| `listenToNetworkConnectivityChanges` | `bool` | `false` | Enable network monitoring |
| `onConnectivityChanged` | `FutureOr<void> Function(bool)?` | null | Callback when connectivity changes |
| `noConnectionText` | `String?` | null | Custom text for no-connection error |
| `onUpdateStatus` | `FutureOr<void> Function(PagifyAsyncCallStatus)?` | null | Called on every status change |
| `onLoading` | `FutureOr<void> Function()?` | null | Called before loading starts |
| `onSuccess` | `FutureOr<void> Function(BuildContext, List<Model>)?` | null | Called on successful data load |
| `onError` | `FutureOr<void> Function(BuildContext, int, PagifyException)?` | null | Called on error (provides page number) |
| `onScrollPositionChanged` | `void Function(ScrollPosition, bool isMaxTop, bool isMaxBottom, bool isMiddle)?` | null | Called when scroll position changes |
| `cacheKey` | `String?` | null | Key for offline cache |
| `cacheToJson` | `Map<String, dynamic> Function(Model)?` | null | Serialize item to JSON for caching |
| `cacheFromJson` | `Model Function(Map<String, dynamic>)?` | null | Deserialize item from JSON cache |
| `onSaveCache` | `void Function(String, List<Map<String, dynamic>>)?` | null | Persist cache to local storage |
| `onReadCache` | `List<Map<String, dynamic>>? Function(String)?` | null | Read cache from local storage |

### ListView-only Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `itemExtent` | `double?` | null | Fixed height per item |
| `scrollDirection` | `Axis?` | null | Scroll axis (vertical / horizontal) |
| `shrinkWrap` | `bool?` | null | Shrink-wrap content to list size |

### GridView-only Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `crossAxisCount` | `int?` | null | Number of columns |
| `childAspectRatio` | `double?` | `1.0` | Width-to-height ratio of each cell |
| `mainAxisSpacing` | `double?` | null | Spacing between rows |
| `crossAxisSpacing` | `double?` | null | Spacing between columns |

### PageView-only Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pageController` | `PageController?` | null | External controller for the PageView |
| `pageSnapping` | `bool?` | `true` | Snap to page boundaries |
| `allowImplicitScrolling` | `bool?` | `false` | Keep adjacent pages in memory |
| `onPageChanged` | `void Function(int)?` | null | Called when the visible page changes |
| `scrollDirection` | `Axis?` | null | Scroll axis (vertical / horizontal) |

## 🎯 Error Handling

### Exception Hierarchy

| Class | Extends | Description |
|-------|---------|-------------|
| `PagifyException` | `Exception` | Base exception — carries a `msg` string |
| `PagifyNetworkException` | `PagifyException` | Thrown when there is no network connectivity |
| `PagifyApiRequestException` | `PagifyException` | Thrown when the API call fails (Dio or HTTP) |

`PagifyApiRequestException` also carries a `pagifyFailure` of type `RequestFailureData`:

| Field | Type | Description |
|-------|------|-------------|
| `statusCode` | `int?` | HTTP status code returned by the server |
| `statusMsg` | `String?` | HTTP status message returned by the server |

### PagifyErrorMapper

```dart
PagifyErrorMapper(
  errorWhenDio: (DioException e) {
    String msg;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        msg = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        msg = 'Server response timeout.';
        break;
      case DioExceptionType.badResponse:
        msg = 'Server returned ${e.response?.statusCode}';
        break;
      default:
        msg = e.response?.data?.toString() ?? 'Network error occurred';
    }
    return PagifyApiRequestException(
      msg,
      pagifyFailure: RequestFailureData(
        statusCode: e.response?.statusCode,
        statusMsg: e.response?.statusMessage,
      ),
    );
  }, // use this if you are using Dio

  // errorWhenHttp: (HttpException e) => PagifyApiRequestException(
  //   e.message,
  //   pagifyFailure: RequestFailureData.initial(),
  // ), // use this if you are using http package
)
```

### Handling errors by type in `onError`

```dart
onError: (context, page, exception) {
  if (exception is PagifyNetworkException) {
    // No internet connection
    print('No connection: ${exception.msg}');
  } else if (exception is PagifyApiRequestException) {
    // Server / API error
    print('API error ${exception.pagifyFailure.statusCode}: ${exception.msg}');
  } else {
    // Unknown error
    print('Error: ${exception.msg}');
  }
}
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

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/emara24)
