import 'dart:io';
import '../src/build_runner.dart';

Future<void> main(List<String> args) async {
  exitCode = await runBuild(args);
}
