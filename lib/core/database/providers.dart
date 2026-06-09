import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/database.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase.instance;
}
