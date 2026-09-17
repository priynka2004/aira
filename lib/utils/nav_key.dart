import 'package:flutter/material.dart';

/// Attached to [MaterialApp] in main.dart. Lets code outside the widget
/// tree (push-notification tap handlers, deep links, etc.) push routes
/// without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
