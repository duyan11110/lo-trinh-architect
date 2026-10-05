/// Thin wrapper around package:json_schema for the fixed schema files in
/// schemas/*.json. Returns human-readable messages, not the raw ValidationError
/// objects, so rule code can just prepend "does not match schema: ".
library schema_validator;

import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';

import 'repo.dart';

class SchemaValidator {
  final Repo repo;
  final Map<String, JsonSchema> _cache = {};

  SchemaValidator(this.repo);

  JsonSchema _load(String schemaFileName) {
    return _cache.putIfAbsent(schemaFileName, () {
      final text = File(repo.path('schemas/$schemaFileName')).readAsStringSync();
      return JsonSchema.create(jsonDecode(text));
    });
  }

  /// Validates [instance] (plain Map/List/String/num/bool/null) against the
  /// named schema file. Returns a list of "<instancePath> <message>" strings;
  /// empty means valid.
  List<String> validate(String schemaFileName, dynamic instance) {
    final schema = _load(schemaFileName);
    final result = schema.validate(instance, parseJson: false);
    return result.errors
        .map((e) => '${e.instancePath.isEmpty ? "/" : e.instancePath} ${e.message}')
        .toList();
  }
}
