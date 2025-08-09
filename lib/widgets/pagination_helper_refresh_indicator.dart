import 'package:flutter/material.dart';

class PagifyRefreshIndicator extends StatelessWidget {

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? refreshIndicatorBackgroundColor;
  final Color? refreshIndicatorColor;
  const PagifyRefreshIndicator({super.key,
    required this.onRefresh,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
        backgroundColor: refreshIndicatorBackgroundColor,
        color: refreshIndicatorColor,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: onRefresh,
        child: child
    );
  }
}
