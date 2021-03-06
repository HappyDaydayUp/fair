/*
 * Copyright (C) 2005-present, 58.com.  All rights reserved.
 * Use of this source code is governed by a BSD type license that can be
 * found in the LICENSE file.
 */

import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart' show md5;
import 'package:path/path.dart' as path;

import 'helper.dart' show FlatCompiler;

class ArchiveBuilder extends PostProcessBuilder with FlatCompiler {
  @override
  FutureOr<void> build(PostProcessBuildStep buildStep) async {
    final dir = path.join('build', 'fair');
    Directory(dir).createSync(recursive: true);
    final bundleName = path.join(
        dir,
        buildStep.inputId.path
            .replaceAll(inputExtensions.first, '.fair.json')
            .replaceAll('/', '_')
            .replaceAll('\\', '_'));
    final bytes = await buildStep.readInputAsBytes();
    final file = File(bundleName)..writeAsBytesSync(bytes);
    if (file.lengthSync() > 0) {
      buildStep.deletePrimaryInput();
    }
    var bin = await compile(file.absolute.path);
    if (bin.success) {
      print('[Fair] FlatBuffer format generated for ${file.path}');
    }
    final buffer = StringBuffer();
    buffer.writeln('# Generated by Fair on ${DateTime.now()}.\n');
    final source =
        buildStep.inputId.path.replaceAll(inputExtensions.first, '.dart');
    buffer.writeln('source: ${buildStep.inputId.package}|$source');
    final digest = md5.convert(bytes).toString();
    buffer.writeln('md5: $digest');
    buffer.writeln('json: ${buildStep.inputId.package}|${file.path}');
    if (bin.success) {
      buffer.writeln('bin: ${buildStep.inputId.package}|${bin.data}');
    }
    buffer.writeln('date: ${DateTime.now()}');
    File('${bundleName.replaceAll('.json', '.metadata')}')
        .writeAsStringSync(buffer.toString());

    print('[Fair] New bundle generated => ${file.path}');
  }

  @override
  Iterable<String> get inputExtensions => ['.bundle.json'];
}
