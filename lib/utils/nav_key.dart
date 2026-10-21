// FILE: utils/nav_key.dart
// Global navigatorKey — lets services navigate without a BuildContext (e.g. push tap).

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
