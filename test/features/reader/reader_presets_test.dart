import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:venera_next/foundation/app.dart';
import 'package:venera_next/foundation/appdata.dart';
import 'package:venera_next/features/reader/reader_presets.dart';

void main() {
  group('ReaderPreset.fromMap', () {
    test('round-trips a valid preset', () {
      final preset = ReaderPreset(
        id: 'p1',
        name: '横屏双页',
        rotation: readerPresetRotationLandscape,
        settings: const {'readerMode': 'dualPage', 'readerBrightness': 50},
      );
      final restored = ReaderPreset.fromMap(preset.toMap());
      expect(restored, isNotNull);
      expect(restored!.id, 'p1');
      expect(restored.name, '横屏双页');
      expect(restored.rotation, readerPresetRotationLandscape);
      expect(restored.settings, {
        'readerMode': 'dualPage',
        'readerBrightness': 50,
      });
    });

    test('rejects invalid entries', () {
      expect(ReaderPreset.fromMap(null), isNull);
      expect(ReaderPreset.fromMap('not a map'), isNull);
      expect(ReaderPreset.fromMap({'name': 'no id'}), isNull);
      expect(ReaderPreset.fromMap({'id': 'p1'}), isNull);
      expect(ReaderPreset.fromMap({'id': 'p1', 'name': ''}), isNull);
    });

    test('filters unknown setting keys and normalizes rotation', () {
      final preset = ReaderPreset.fromMap({
        'id': 'p2',
        'name': '竖屏连续',
        'rotation': 'invalid',
        'settings': {
          'readerMode': 'continuousTopToBottom',
          'notAReaderSetting': 1,
        },
      });
      expect(preset, isNotNull);
      expect(preset!.rotation, readerPresetRotationAuto);
      expect(preset.settings, {'readerMode': 'continuousTopToBottom'});
    });
  });

  test('readerPresetButtonId uses the stable prefix format', () {
    expect(readerPresetButtonId('p1'), 'preset:p1');
    expect('preset:p1'.startsWith(readerPresetButtonIdPrefix), isTrue);
  });

  test('captureReaderPreset maps rotation and reads effective settings', () {
    final previousMode = appdata.settings['readerMode'];
    final previousBrightness = appdata.settings['readerBrightness'];
    try {
      appdata.settings['readerMode'] = 'dualPage';
      appdata.settings['readerBrightness'] = 42;

      final landscape = captureReaderPreset(
        id: 'p1',
        name: '横屏双页',
        rotation: true,
      );
      expect(landscape.rotation, readerPresetRotationLandscape);
      expect(landscape.settings['readerMode'], 'dualPage');
      expect(landscape.settings['readerBrightness'], 42);

      final portrait = captureReaderPreset(
        id: 'p2',
        name: '竖屏连续',
        rotation: false,
      );
      expect(portrait.rotation, readerPresetRotationPortrait);

      final auto = captureReaderPreset(id: 'p3', name: '跟随系统');
      expect(auto.rotation, readerPresetRotationAuto);
    } finally {
      appdata.settings['readerMode'] = previousMode;
      appdata.settings['readerBrightness'] = previousBrightness;
    }
  });

  test('setPresetInBottomBar appends and removes the preset button', () {
    final dataDir = Directory.systemTemp.createTempSync('venera-presets-');
    addTearDown(() {
      if (dataDir.existsSync()) {
        dataDir.deleteSync(recursive: true);
      }
    });
    App.dataPath = dataDir.path;

    final previousBar = appdata.settings['readerBottomBarButtons'];
    try {
      appdata.settings['readerBottomBarButtons'] = List<String>.from(
        defaultReaderBottomBarButtons,
      );

      setPresetInBottomBar('p1', true);
      expect(appdata.settings['readerBottomBarButtons'], contains('preset:p1'));

      setPresetInBottomBar('p1', false);
      expect(
        appdata.settings['readerBottomBarButtons'],
        isNot(contains('preset:p1')),
      );
    } finally {
      appdata.settings['readerBottomBarButtons'] = previousBar;
    }
  });

  test('deleteReaderPreset removes the preset and its bottom bar button', () {
    final dataDir = Directory.systemTemp.createTempSync('venera-presets-');
    addTearDown(() {
      if (dataDir.existsSync()) {
        dataDir.deleteSync(recursive: true);
      }
    });
    App.dataPath = dataDir.path;

    final previousPresets = appdata.settings['readerPresets'];
    final previousBar = appdata.settings['readerBottomBarButtons'];
    try {
      final preset = ReaderPreset(
        id: 'p1',
        name: '横屏双页',
        rotation: readerPresetRotationLandscape,
        settings: const {'readerMode': 'dualPage'},
      );
      appdata.settings['readerPresets'] = [preset.toMap()];
      appdata.settings['readerBottomBarButtons'] = ['favorite', 'preset:p1'];

      deleteReaderPreset('p1');

      expect(listReaderPresets(), isEmpty);
      expect(appdata.settings['readerBottomBarButtons'], ['favorite']);
    } finally {
      appdata.settings['readerPresets'] = previousPresets;
      appdata.settings['readerBottomBarButtons'] = previousBar;
    }
  });
}
