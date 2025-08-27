part of '../pagify.dart';

/// Defines the type of list ranking to use in [Pagify].
enum _RankingType {
  /// Displays items in a [GridView].
  gridView,

  /// Displays items in a [ListView].
  listView
}


/// extension to check the current type
extension _Checking on _RankingType{

  /// check if the current type is [GridView]
  bool get isGridView => this == _RankingType.gridView;

  /// check if the current type is [ListView]
  bool get isListView => this == _RankingType.listView;
}