import 'package:flutter/material.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/translations.dart';

/// 阅读器底栏按钮的静态元数据，供底栏渲染与管理页面复用。
///
/// 按钮的点击逻辑（依赖阅读器上下文）仍保留在 scaffold.dart 中，
/// 这里只提供展示所需的名称、图标与平台可用性。

String readerBottomBarButtonTitle(String id) {
  switch (id) {
    case 'favorite':
      return "Collect the image".tl;
    case 'fullscreen':
      return "Full Screen".tl;
    case 'rotation':
      return "Screen Rotation".tl;
    case 'brightness':
      return "Reader brightness".tl;
    case 'autoPageTurning':
      return "Auto Page Turning".tl;
    case 'chapters':
      return "Chapters".tl;
    case 'save':
      return "Save Image".tl;
    case 'share':
      return "Share".tl;
    default:
      return id;
  }
}

IconData readerBottomBarButtonIcon(String id) {
  switch (id) {
    case 'favorite':
      return Icons.favorite_border;
    case 'fullscreen':
      return Icons.fullscreen;
    case 'rotation':
      return Icons.screen_rotation;
    case 'brightness':
      return Icons.brightness_6;
    case 'autoPageTurning':
      return Icons.timer;
    case 'chapters':
      return Icons.library_books;
    case 'save':
      return Icons.download;
    case 'share':
      return Icons.share;
    default:
      return Icons.help_outline;
  }
}

/// 按钮在当前平台是否可用。不可用（如 Android 下的全屏）不会出现在底栏，
/// 也不应出现在管理页面中。
bool readerBottomBarButtonAvailable(String id) {
  switch (id) {
    case 'fullscreen':
      return App.isDesktop;
    case 'rotation':
      return App.isAndroid;
    default:
      return true;
  }
}