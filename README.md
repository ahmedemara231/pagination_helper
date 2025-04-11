# PaginatedList Widget

A Flutter widget for implementing infinite scrolling lists with pagination functionality.

## Overview

`PaginatedList` is a versatile Flutter widget that handles pagination for list data. It automatically fetches more data when the user scrolls to the bottom of the list, maintaining the scroll position during loading to ensure a smooth user experience.

## Features

- Generic implementation to work with any data type
- Automatic loading of next page when reaching the end of the list
- Customizable item builder for flexible list item rendering
- Optional custom loading indicator
- Smart scroll position retention during loading
- Support for mapping API responses to data models

## Installation

No additional installation required. Just copy the provided files into your project.

## Usage

### Basic Example

```dart
PaginatedList<ApiResponse, UserModel>(
  asyncCall: (page) => userRepository.getUsers(page: page),
  mapper: (response) => DataListAndPaginationData<UserModel>(
    data: response.users,
    paginationData: PaginationData(totalPages: response.totalPages),
  ),
  builder: (items, index) => UserListItem(user: items[index]),
  loadingBuilder: const CustomLoadingIndicator(),
)
```

### Required Parameters

- `asyncCall`: Function that fetches data for a given page number
- `mapper`: Function that extracts the list items and pagination data from the response
- `builder`: Function that builds the UI for each item in the list

### Optional Parameters

- `loadingBuilder`: Custom widget to display while loading data (defaults to CircularProgressIndicator)

## Type Parameters

- `T`: The type of the API response (e.g., ApiResponse, Map<String, dynamic>)
- `E`: The type of items in the list (e.g., UserModel, Product)

## Helper Classes

### DataListAndPaginationData

Container class that holds both the list items and pagination metadata.

```dart
DataListAndPaginationData<UserModel>(
  data: usersList,
  paginationData: PaginationData(totalPages: 10),
)
```

### PaginationData

Class for storing pagination metadata.

```dart
PaginationData(
  totalPages: 10,
  // Other pagination fields available for expansion
)
```

### RetainableScrollController

Extended ScrollController that can retain and restore scroll position.

## Implementation Details

1. When initialized, the widget fetches the first page of data
2. A scroll listener monitors when the user reaches the bottom of the list
3. When bottom is reached, it loads the next page while maintaining scroll position
4. New items are appended to the existing list

## Example: User List with Pagination

```dart
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: PaginatedList<UserResponse, User>(
        asyncCall: (page) => UserService.getUsers(page: page),
        mapper: (response) => DataListAndPaginationData(
          data: response.users,
          paginationData: PaginationData(totalPages: response.meta.totalPages),
        ),
        builder: (users, index) => UserListTile(user: users[index]),
        loadingBuilder: const LoadingIndicator(),
      ),
    );
  }
}
```

## Notes

- Make sure your API returns the total number of pages for proper pagination
- The list automatically handles loading states and appending new items
- Scroll position is maintained during loading to prevent UI jumps
