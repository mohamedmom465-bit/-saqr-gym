import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/store.dart';
import '../ui/widgets.dart';
import 'feedback.dart';

class BackupService {
  /// مشاركة نسخة احتياطية (درايف / واتساب / ملفات)
  static Future<void> share(BuildContext context) async {
    try {
      final file = await store.buildBackupFile();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'نسخة احتياطية - نظام صقر',
        text: 'نسخة احتياطية من تطبيق SAQR GYM',
      );
      await store.markManualBackup();
      Fx.toast('✅ اتشاركت النسخة الاحتياطية');
    } catch (e) {
      Fx.toast('⚠️ مقدرناش نشارك الملف: $e', duration: const Duration(seconds: 4));
    }
  }

  /// حفظ نسخة في فولدر التنزيلات/المستندات على الجهاز
  static Future<void> saveToDevice(BuildContext context) async {
    try {
      final file = await store.buildBackupFile();
      Directory? target;
      if (Platform.isAndroid) {
        const downloads = '/storage/emulated/0/Download';
        if (await Directory(downloads).exists()) {
          target = Directory(downloads);
        }
      }
      target ??= await getApplicationDocumentsDirectory();
      final dest = File('${target.path}/${file.uri.pathSegments.last}');
      await dest.writeAsBytes(await file.readAsBytes());
      await store.markManualBackup();
      Fx.toast('✅ اتحفظت النسخة هنا:\n${dest.path}',
          duration: const Duration(seconds: 5));
    } catch (e) {
      Fx.toast('⚠️ مقدرناش نحفظ الملف، جرب "مشاركة" بدلها');
    }
  }

  /// استيراد نسخة احتياطية (بتشتغل كمان مع ملفات نسخة الويب القديمة)
  static Future<void> import(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      'هيتم استبدال كل البيانات الحالية بالنسخة اللي هتستوردها. متأكد؟',
      danger: true,
    );
    if (!ok) return;
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.any);
      final path = res?.files.single.path;
      if (path == null) return;
      final done = await store.importBackup(File(path));
      Fx.toast(done
          ? '✅ اتستوردت النسخة الاحتياطية بنجاح'
          : '⚠️ الملف مش نسخة احتياطية صحيحة');
    } catch (e) {
      Fx.toast('⚠️ حصلت مشكلة وإحنا بنقرأ الملف');
    }
  }
}
