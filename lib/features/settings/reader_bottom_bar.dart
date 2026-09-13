import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:venera_next/components/appbar.dart';
import 'package:venera_next/features/reader/bottom_bar.dart';
import 'package:venera_next/features/reader/reader_presets.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/context.dart';
import 'package:venera_next/foundation/translations.dart';

/// 阅读器底栏按钮管理页面。
///
/// 列表内为「已显示」按钮（可按长按拖拽排序），移除按钮即隐藏；
/// 通过右上角「Add」把已隐藏的按钮加回；「Reset」恢复默认布局。
class ReaderBottomBarButtonsPage extends StatefulWidget {
  const ReaderBottomBarButtonsPage({super.key});

  @override
  State<ReaderBottomBarButtonsPage> createState() =>
      _ReaderBottomBarButtonsPageState();
}

class _ReaderBottomBarButtonsPageState
    extends State<ReaderBottomBarButtonsPage> {
  late List<String> _visible;

  final _scrollController = ScrollController();

  var _reorderKey = UniqueKey();

  /// 当前平台下可用的按钮（默认顺序），包含已存在的预设方案按钮。
  List<String> get _availableIds => [
    ...defaultReaderBottomBarButtons.where(readerBottomBarButtonAvailable),
    ...listReaderPresets().map((preset) => readerPresetButtonId(preset.id)),
  ];

  @override
  void initState() {
    super.initState();
    _visible = _loadVisible();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _loadVisible() {
    final saved = List<String>.from(
      appdata.settings['readerBottomBarButtons'] ?? const <String>[],
    );
    final available = _availableIds;
    return [
      for (final id in saved)
        if (available.contains(id)) id,
    ];
  }

  void _save() {
    appdata.settings['readerBottomBarButtons'] = List<String>.from(_visible);
    appdata.saveData();
  }

  void _remove(String id) {
    setState(() {
      _visible.remove(id);
    });
    _save();
  }

  void _reset() {
    setState(() {
      _visible = List<String>.from(_availableIds);
    });
    _save();
  }

  void _showAddDialog() {
    final canAdd = [
      for (final id in _availableIds)
        if (!_visible.contains(id)) id,
    ];
    if (canAdd.isEmpty) return;

    final selected = <String>[];
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add".tl),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final id in canAdd)
                      CheckboxListTile(
                        value: selected.contains(id),
                        title: Text(readerBottomBarButtonTitle(id)),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back".tl),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _visible.addAll(selected);
                          });
                          _save();
                          Navigator.pop(context);
                        },
                  child: Text("Add".tl),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTile(String id) {
    return ListTile(
      key: Key(id),
      leading: Icon(readerBottomBarButtonIcon(id)),
      title: Text(readerBottomBarButtonTitle(id)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Remove".tl,
            onPressed: () => _remove(id),
            icon: const Icon(Icons.visibility_off_outlined),
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _visible.map(_buildTile).toList();
    final hasHidden = _availableIds.length > _visible.length;

    return Scaffold(
      appBar: Appbar(
        title: Text("Bottom bar buttons".tl),
        actions: [
          if (hasHidden)
            TextButton(onPressed: _showAddDialog, child: Text("Add".tl)),
          TextButton(onPressed: _reset, child: Text("Reset".tl)),
        ],
      ),
      body: _visible.isEmpty
          ? Center(child: Text("No buttons shown".tl))
          : ReorderableBuilder<String>(
              key: _reorderKey,
              scrollController: _scrollController,
              longPressDelay: App.isDesktop
                  ? const Duration(milliseconds: 100)
                  : const Duration(milliseconds: 500),
              dragChildBoxDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              onReorder: (reorderFunc) {
                setState(() {
                  _visible = List<String>.from(reorderFunc(_visible));
                });
                _save();
              },
              children: tiles,
              builder: (children) {
                return ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: context.padding.bottom + 16),
                  children: children,
                );
              },
            ),
    );
  }
}
