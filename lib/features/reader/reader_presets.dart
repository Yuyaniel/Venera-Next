import 'package:venera_next/foundation/appdata.dart';

/// 阅读设置预设方案的数据模型与存取逻辑。
///
/// 复用 appdata.settings 的现有持久化机制（"readerPresets" 键），
/// 预设按钮复用第二阶段的底栏按钮排序表（"readerBottomBarButtons"）。
/// 屏幕方向捕获自阅读器内部的内容方向状态（ReaderState.rotation）。

/// 底栏中预设按钮的 id 前缀，格式为 "preset:<方案id>"。
const readerPresetButtonIdPrefix = 'preset:';

/// 生成底栏按钮 id。
String readerPresetButtonId(String presetId) =>
    '$readerPresetButtonIdPrefix$presetId';

/// 阅读器内容方向的存储值：auto（跟随系统）/ portrait（竖屏）/ landscape（横屏）。
const readerPresetRotationAuto = 'auto';
const readerPresetRotationPortrait = 'portrait';
const readerPresetRotationLandscape = 'landscape';

class ReaderPreset {
  const ReaderPreset({
    required this.id,
    required this.name,
    required this.rotation,
    required this.settings,
  });

  /// 稳定 id，重命名不影响底栏按钮的引用。
  final String id;

  final String name;

  /// auto | portrait | landscape，对应 ReaderState.rotation 的 null / false / true。
  final String rotation;

  /// 捕获的阅读设置，键为 [readerPresetKeys] 的子集。
  final Map<String, dynamic> settings;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'rotation': rotation,
    'settings': settings,
  };

  /// 从持久化数据恢复，过滤掉已失效的设置键，格式非法时返回 null。
  static ReaderPreset? fromMap(dynamic value) {
    if (value is! Map) return null;
    final id = value['id'];
    final name = value['name'];
    if (id is! String || id.isEmpty) return null;
    if (name is! String || name.isEmpty) return null;
    final rawSettings = value['settings'];
    final settings = <String, dynamic>{
      if (rawSettings is Map)
        for (final entry in rawSettings.entries)
          if (readerPresetKeys.contains(entry.key)) entry.key: entry.value,
    };
    return ReaderPreset(
      id: id,
      name: name,
      rotation: switch (value['rotation']) {
        readerPresetRotationPortrait => readerPresetRotationPortrait,
        readerPresetRotationLandscape => readerPresetRotationLandscape,
        _ => readerPresetRotationAuto,
      },
      settings: settings,
    );
  }
}

/// 生成新的方案 id。
String newReaderPresetId() => 'p${DateTime.now().microsecondsSinceEpoch}';

/// 读取全部预设方案。
List<ReaderPreset> listReaderPresets() {
  final value = appdata.settings['readerPresets'];
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (ReaderPreset.fromMap(item) case final preset?) preset,
  ];
}

/// 按 id 查找预设方案，不存在时返回 null。
ReaderPreset? findReaderPreset(String id) {
  for (final preset in listReaderPresets()) {
    if (preset.id == id) return preset;
  }
  return null;
}

/// 持久化全部预设方案。
void saveReaderPresets(List<ReaderPreset> presets) {
  appdata.settings['readerPresets'] = [
    for (final preset in presets) preset.toMap(),
  ];
  appdata.saveData();
}

/// 捕获当前有效的阅读设置（漫画专属 > 设备专属 > 全局）为预设。
///
/// [rotation] 为阅读器当前的内容方向（ReaderState.rotation）；
/// 在阅读器外打开管理页时传 null，表示跟随系统。
ReaderPreset captureReaderPreset({
  required String id,
  required String name,
  bool? rotation,
  String? comicId,
  String? sourceKey,
}) {
  final settings = {
    for (final key in readerPresetKeys)
      key: appdata.settings.getReaderSetting(
        comicId ?? '',
        sourceKey ?? '',
        key,
      ),
  };
  return ReaderPreset(
    id: id,
    name: name,
    rotation: switch (rotation) {
      true => readerPresetRotationLandscape,
      false => readerPresetRotationPortrait,
      _ => readerPresetRotationAuto,
    },
    settings: settings,
  );
}

/// 添加 / 移除方案的底栏快捷按钮（追加到末尾，可在底栏管理页调整顺序）。
void setPresetInBottomBar(String presetId, bool enabled) {
  final buttonId = readerPresetButtonId(presetId);
  final saved = appdata.settings['readerBottomBarButtons'];
  final bar = saved is List
      ? List<String>.from(saved)
      : List<String>.from(defaultReaderBottomBarButtons);
  bar.remove(buttonId);
  if (enabled) {
    bar.add(buttonId);
  }
  appdata.settings['readerBottomBarButtons'] = bar;
  appdata.saveData();
}

/// 删除方案；若已添加到底栏，同时移除对应的底栏按钮。
void deleteReaderPreset(String presetId) {
  final presets = listReaderPresets()
    ..removeWhere((preset) => preset.id == presetId);
  appdata.settings['readerPresets'] = [
    for (final preset in presets) preset.toMap(),
  ];
  final saved = appdata.settings['readerBottomBarButtons'];
  final bar = saved is List
      ? List<String>.from(saved)
      : List<String>.from(defaultReaderBottomBarButtons);
  bar.remove(readerPresetButtonId(presetId));
  appdata.settings['readerBottomBarButtons'] = bar;
  appdata.saveData();
}
