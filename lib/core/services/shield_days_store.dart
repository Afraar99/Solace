/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persists daily shield check-ins (app presence + NSFW filter days).
class ShieldDaysStore {
  ShieldDaysStore._();
  static final ShieldDaysStore instance = ShieldDaysStore._();

  static const _fileName = 'solace_shield_days.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// dateKey (yyyy-MM-dd) → {app: bool, nsfw: bool}
  Future<Map<String, Map<String, bool>>> load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return {};
      final out = <String, Map<String, bool>>{};
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is Map) {
          out[entry.key.toString()] = {
            'app': v['app'] == true,
            'nsfw': v['nsfw'] == true,
          };
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, Map<String, bool>> data) async {
    final file = await _file;
    await file.writeAsString(jsonEncode(data));
  }

  Future<Map<String, Map<String, bool>>> markToday({
    required bool appPresent,
    required bool nsfwOn,
  }) async {
    final data = await load();
    final key = _dateKey(DateTime.now());
    final existing = data[key] ?? {'app': false, 'nsfw': false};
    data[key] = {
      'app': existing['app'] == true || appPresent,
      'nsfw': existing['nsfw'] == true || nsfwOn,
    };
    await save(data);
    return data;
  }

  static String dateKey(DateTime d) => _dateKey(d);

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
