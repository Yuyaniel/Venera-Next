import 'package:flutter/material.dart';
import 'package:venera_next/components/appbar.dart';
import 'package:venera_next/components/message.dart';
import 'package:venera_next/features/reader/reader_presets.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/foundation/translations.dart';

/// 阅读设置预设方案管理页面。
///
/// 支持新建（捕获当前有效阅读设置）、重命名、用当前设置覆盖、删除，
/// 以及把方案作为快捷按钮添加 / 移出阅读器底栏（复用第二阶段底栏管理）。
/// 在阅读器内打开时（携带 comicId / comicSource / currentRotation），
/// 捕获与展示遵循漫画专属 > 设备专属 > 全局的既有设置层级。
class ReaderPresetsPage extends StatefulWidget {
  const ReaderPresetsPage({
    super.key,
    this.comicId,
    this.comicSource,
    this.currentRotation,
  });

  final String? comicId;

  final String? comicSource;

  /// 打开时的阅读器内容方向（ReaderState.rotation），null 表示跟随系统。
  final bool? currentRotation;

  @override
  State<ReaderPresetsPage> createState() => _ReaderPresetsPageState();
}

class _ReaderPresetsPageState extends State<ReaderPresetsPage> {
  late List<ReaderPreset> _presets;

  @override
  void initState() {
    super.initState();
    _presets = listReaderPresets();
  }

  void _refresh() {
    setState(() {
      _presets = listReaderPresets();
    });
  }

  bool _isInBottomBar(String presetId) {
    final bar = appdata.settings['readerBottomBarButtons'];
    if (bar is! List) return false;
    return bar.contains(readerPresetButtonId(presetId));
  }

  String _rotationLabel(String rotation) => switch (rotation) {
    readerPresetRotationPortrait => "Portrait".tl,
    readerPresetRotationLandscape => "Landscape".tl,
    _ => "Follow System".tl,
  };

  String _modeLabel(String key) => switch (key) {
    'waterfallTopToBottom' => "Waterfall (Top to Bottom)".tl,
    'dualPage' => "Dual Page".tl,
    'galleryLeftToRight' => "Gallery (Left to Right)".tl,
    'galleryRightToLeft' => "Gallery (Right to Left)".tl,
    'galleryTopToBottom' => "Gallery (Top to Bottom)".tl,
    'continuousLeftToRight' => "Continuous (Left to Right)".tl,
    'continuousRightToLeft' => "Continuous (Right to Left)".tl,
    'continuousTopToBottom' => "Continuous (Top to Bottom)".tl,
    _ => key,
  };

  String _summary(ReaderPreset preset) {
    final mode = preset.settings['readerMode'];
    final parts = [_rotationLabel(preset.rotation)];
    if (mode is String) {
      parts.add(_modeLabel(mode));
    }
    return parts.join(' · ');
  }

  ReaderPreset _capture(String id, String name) {
    return captureReaderPreset(
      id: id,
      name: name,
      rotation: widget.currentRotation,
      comicId: widget.comicId,
      sourceKey: widget.comicSource,
    );
  }

  void _createPreset() {
    showInputDialog(
      context: context,
      title: "New Preset".tl,
      hintText: "Preset name".tl,
      confirmText: "Create",
      onConfirm: (name) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          return "Invalid input".tl;
        }
        saveReaderPresets([
          ..._presets,
          _capture(newReaderPresetId(), trimmed),
        ]);
        _refresh();
        return null;
      },
    );
  }

  void _renamePreset(ReaderPreset preset) {
    showInputDialog(
      context: context,
      title: "Rename".tl,
      initialValue: preset.name,
      confirmText: "Confirm",
      onConfirm: (name) {
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          return "Invalid input".tl;
        }
        saveReaderPresets([
          for (final item in _presets)
            if (item.id == preset.id)
              ReaderPreset(
                id: item.id,
                name: trimmed,
                rotation: item.rotation,
                settings: item.settings,
              )
            else
              item,
        ]);
        _refresh();
        return null;
      },
    );
  }

  void _overwritePreset(ReaderPreset preset) {
    saveReaderPresets([
      for (final item in _presets)
        if (item.id == preset.id) _capture(item.id, item.name) else item,
    ]);
    _refresh();
  }

  void _deletePreset(ReaderPreset preset) {
    showConfirmDialog(
      context: context,
      title: "Delete preset".tl,
      content:
          "The preset will be deleted. If it is on the bottom bar, its button will be removed as well."
              .tl,
      onConfirm: () {
        deleteReaderPreset(preset.id);
        _refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        title: Text("Reading Presets".tl),
        actions: [
          TextButton(onPressed: _createPreset, child: Text("New Preset".tl)),
        ],
      ),
      body: _presets.isEmpty
          ? Center(child: Text("No presets yet".tl))
          : ListView(
              children: [
                for (final preset in _presets)
                  ListTile(
                    leading: const Icon(Icons.auto_stories),
                    title: Text(preset.name),
                    subtitle: Text(_summary(preset)),
                    onTap: () => _renamePreset(preset),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: "Update with current settings".tl,
                          onPressed: () => _overwritePreset(preset),
                          icon: const Icon(Icons.refresh),
                        ),
                        IconButton(
                          tooltip: "Delete".tl,
                          onPressed: () => _deletePreset(preset),
                          icon: const Icon(Icons.delete_outline),
                        ),
                        Switch(
                          value: _isInBottomBar(preset.id),
                          onChanged: (value) {
                            setPresetInBottomBar(preset.id, value);
                            _refresh();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
