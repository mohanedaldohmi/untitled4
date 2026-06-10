import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/models/download_task_model.dart';
import 'services/storage/hive_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);

  // Register Hive adapters
  Hive.registerAdapter(DownloadTaskModelAdapter());

  // Open Hive boxes
  await HiveStorageService.openBoxes();

  // Initialize AdMob
  await MobileAds.instance.initialize();

  runApp(
    const ProviderScope(
      child: VideoDownloaderProApp(),
    ),
  );
}
