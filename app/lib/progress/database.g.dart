// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class LessonProgress extends Table
    with TableInfo<LessonProgress, LessonProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LessonProgress(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'new\', \'opened\', \'read\', \'passed\'))',
  );
  static const VerificationMeta _firstOpenedAtMeta = const VerificationMeta(
    'firstOpenedAt',
  );
  late final GeneratedColumn<String> firstOpenedAt = GeneratedColumn<String>(
    'first_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  late final GeneratedColumn<String> readAt = GeneratedColumn<String>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _passedAtMeta = const VerificationMeta(
    'passedAt',
  );
  late final GeneratedColumn<String> passedAt = GeneratedColumn<String>(
    'passed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  late final GeneratedColumn<double> bestScore = GeneratedColumn<double>(
    'best_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _scrollRatioMeta = const VerificationMeta(
    'scrollRatio',
  );
  late final GeneratedColumn<double> scrollRatio = GeneratedColumn<double>(
    'scroll_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _prereqWarnedMeta = const VerificationMeta(
    'prereqWarned',
  );
  late final GeneratedColumn<int> prereqWarned = GeneratedColumn<int>(
    'prereq_warned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  late final GeneratedColumn<int> contentVersion = GeneratedColumn<int>(
    'content_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    status,
    firstOpenedAt,
    readAt,
    passedAt,
    bestScore,
    scrollRatio,
    prereqWarned,
    contentVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('first_opened_at')) {
      context.handle(
        _firstOpenedAtMeta,
        firstOpenedAt.isAcceptableOrUnknown(
          data['first_opened_at']!,
          _firstOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('passed_at')) {
      context.handle(
        _passedAtMeta,
        passedAt.isAcceptableOrUnknown(data['passed_at']!, _passedAtMeta),
      );
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
    }
    if (data.containsKey('scroll_ratio')) {
      context.handle(
        _scrollRatioMeta,
        scrollRatio.isAcceptableOrUnknown(
          data['scroll_ratio']!,
          _scrollRatioMeta,
        ),
      );
    }
    if (data.containsKey('prereq_warned')) {
      context.handle(
        _prereqWarnedMeta,
        prereqWarned.isAcceptableOrUnknown(
          data['prereq_warned']!,
          _prereqWarnedMeta,
        ),
      );
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  LessonProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      firstOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_opened_at'],
      ),
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}read_at'],
      ),
      passedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passed_at'],
      ),
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_score'],
      ),
      scrollRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scroll_ratio'],
      )!,
      prereqWarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prereq_warned'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_version'],
      ),
    );
  }

  @override
  LessonProgress createAlias(String alias) {
    return LessonProgress(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class LessonProgressData extends DataClass
    implements Insertable<LessonProgressData> {
  final String? lessonId;
  final String status;
  final String? firstOpenedAt;
  final String? readAt;
  final String? passedAt;
  final double? bestScore;

  /// 0..1
  final double scrollRatio;
  final int prereqWarned;
  final int? contentVersion;
  const LessonProgressData({
    this.lessonId,
    required this.status,
    this.firstOpenedAt,
    this.readAt,
    this.passedAt,
    this.bestScore,
    required this.scrollRatio,
    required this.prereqWarned,
    this.contentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || lessonId != null) {
      map['lesson_id'] = Variable<String>(lessonId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || firstOpenedAt != null) {
      map['first_opened_at'] = Variable<String>(firstOpenedAt);
    }
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<String>(readAt);
    }
    if (!nullToAbsent || passedAt != null) {
      map['passed_at'] = Variable<String>(passedAt);
    }
    if (!nullToAbsent || bestScore != null) {
      map['best_score'] = Variable<double>(bestScore);
    }
    map['scroll_ratio'] = Variable<double>(scrollRatio);
    map['prereq_warned'] = Variable<int>(prereqWarned);
    if (!nullToAbsent || contentVersion != null) {
      map['content_version'] = Variable<int>(contentVersion);
    }
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      lessonId: lessonId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonId),
      status: Value(status),
      firstOpenedAt: firstOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firstOpenedAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      passedAt: passedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(passedAt),
      bestScore: bestScore == null && nullToAbsent
          ? const Value.absent()
          : Value(bestScore),
      scrollRatio: Value(scrollRatio),
      prereqWarned: Value(prereqWarned),
      contentVersion: contentVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(contentVersion),
    );
  }

  factory LessonProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressData(
      lessonId: serializer.fromJson<String?>(json['lesson_id']),
      status: serializer.fromJson<String>(json['status']),
      firstOpenedAt: serializer.fromJson<String?>(json['first_opened_at']),
      readAt: serializer.fromJson<String?>(json['read_at']),
      passedAt: serializer.fromJson<String?>(json['passed_at']),
      bestScore: serializer.fromJson<double?>(json['best_score']),
      scrollRatio: serializer.fromJson<double>(json['scroll_ratio']),
      prereqWarned: serializer.fromJson<int>(json['prereq_warned']),
      contentVersion: serializer.fromJson<int?>(json['content_version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lesson_id': serializer.toJson<String?>(lessonId),
      'status': serializer.toJson<String>(status),
      'first_opened_at': serializer.toJson<String?>(firstOpenedAt),
      'read_at': serializer.toJson<String?>(readAt),
      'passed_at': serializer.toJson<String?>(passedAt),
      'best_score': serializer.toJson<double?>(bestScore),
      'scroll_ratio': serializer.toJson<double>(scrollRatio),
      'prereq_warned': serializer.toJson<int>(prereqWarned),
      'content_version': serializer.toJson<int?>(contentVersion),
    };
  }

  LessonProgressData copyWith({
    Value<String?> lessonId = const Value.absent(),
    String? status,
    Value<String?> firstOpenedAt = const Value.absent(),
    Value<String?> readAt = const Value.absent(),
    Value<String?> passedAt = const Value.absent(),
    Value<double?> bestScore = const Value.absent(),
    double? scrollRatio,
    int? prereqWarned,
    Value<int?> contentVersion = const Value.absent(),
  }) => LessonProgressData(
    lessonId: lessonId.present ? lessonId.value : this.lessonId,
    status: status ?? this.status,
    firstOpenedAt: firstOpenedAt.present
        ? firstOpenedAt.value
        : this.firstOpenedAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    passedAt: passedAt.present ? passedAt.value : this.passedAt,
    bestScore: bestScore.present ? bestScore.value : this.bestScore,
    scrollRatio: scrollRatio ?? this.scrollRatio,
    prereqWarned: prereqWarned ?? this.prereqWarned,
    contentVersion: contentVersion.present
        ? contentVersion.value
        : this.contentVersion,
  );
  LessonProgressData copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      firstOpenedAt: data.firstOpenedAt.present
          ? data.firstOpenedAt.value
          : this.firstOpenedAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      passedAt: data.passedAt.present ? data.passedAt.value : this.passedAt,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      scrollRatio: data.scrollRatio.present
          ? data.scrollRatio.value
          : this.scrollRatio,
      prereqWarned: data.prereqWarned.present
          ? data.prereqWarned.value
          : this.prereqWarned,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressData(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('readAt: $readAt, ')
          ..write('passedAt: $passedAt, ')
          ..write('bestScore: $bestScore, ')
          ..write('scrollRatio: $scrollRatio, ')
          ..write('prereqWarned: $prereqWarned, ')
          ..write('contentVersion: $contentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lessonId,
    status,
    firstOpenedAt,
    readAt,
    passedAt,
    bestScore,
    scrollRatio,
    prereqWarned,
    contentVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressData &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.firstOpenedAt == this.firstOpenedAt &&
          other.readAt == this.readAt &&
          other.passedAt == this.passedAt &&
          other.bestScore == this.bestScore &&
          other.scrollRatio == this.scrollRatio &&
          other.prereqWarned == this.prereqWarned &&
          other.contentVersion == this.contentVersion);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressData> {
  final Value<String?> lessonId;
  final Value<String> status;
  final Value<String?> firstOpenedAt;
  final Value<String?> readAt;
  final Value<String?> passedAt;
  final Value<double?> bestScore;
  final Value<double> scrollRatio;
  final Value<int> prereqWarned;
  final Value<int?> contentVersion;
  final Value<int> rowid;
  const LessonProgressCompanion({
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.firstOpenedAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.passedAt = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.scrollRatio = const Value.absent(),
    this.prereqWarned = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    this.lessonId = const Value.absent(),
    required String status,
    this.firstOpenedAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.passedAt = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.scrollRatio = const Value.absent(),
    this.prereqWarned = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : status = Value(status);
  static Insertable<LessonProgressData> custom({
    Expression<String>? lessonId,
    Expression<String>? status,
    Expression<String>? firstOpenedAt,
    Expression<String>? readAt,
    Expression<String>? passedAt,
    Expression<double>? bestScore,
    Expression<double>? scrollRatio,
    Expression<int>? prereqWarned,
    Expression<int>? contentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (firstOpenedAt != null) 'first_opened_at': firstOpenedAt,
      if (readAt != null) 'read_at': readAt,
      if (passedAt != null) 'passed_at': passedAt,
      if (bestScore != null) 'best_score': bestScore,
      if (scrollRatio != null) 'scroll_ratio': scrollRatio,
      if (prereqWarned != null) 'prereq_warned': prereqWarned,
      if (contentVersion != null) 'content_version': contentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressCompanion copyWith({
    Value<String?>? lessonId,
    Value<String>? status,
    Value<String?>? firstOpenedAt,
    Value<String?>? readAt,
    Value<String?>? passedAt,
    Value<double?>? bestScore,
    Value<double>? scrollRatio,
    Value<int>? prereqWarned,
    Value<int?>? contentVersion,
    Value<int>? rowid,
  }) {
    return LessonProgressCompanion(
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      firstOpenedAt: firstOpenedAt ?? this.firstOpenedAt,
      readAt: readAt ?? this.readAt,
      passedAt: passedAt ?? this.passedAt,
      bestScore: bestScore ?? this.bestScore,
      scrollRatio: scrollRatio ?? this.scrollRatio,
      prereqWarned: prereqWarned ?? this.prereqWarned,
      contentVersion: contentVersion ?? this.contentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (firstOpenedAt.present) {
      map['first_opened_at'] = Variable<String>(firstOpenedAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<String>(readAt.value);
    }
    if (passedAt.present) {
      map['passed_at'] = Variable<String>(passedAt.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<double>(bestScore.value);
    }
    if (scrollRatio.present) {
      map['scroll_ratio'] = Variable<double>(scrollRatio.value);
    }
    if (prereqWarned.present) {
      map['prereq_warned'] = Variable<int>(prereqWarned.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<int>(contentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('firstOpenedAt: $firstOpenedAt, ')
          ..write('readAt: $readAt, ')
          ..write('passedAt: $passedAt, ')
          ..write('bestScore: $bestScore, ')
          ..write('scrollRatio: $scrollRatio, ')
          ..write('prereqWarned: $prereqWarned, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class QuizAttempt extends Table with TableInfo<QuizAttempt, QuizAttemptData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  QuizAttempt(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'lesson\', \'module\', \'review\', \'gate\'))',
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  late final GeneratedColumn<String> finishedAt = GeneratedColumn<String>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _questionIdsMeta = const VerificationMeta(
    'questionIds',
  );
  late final GeneratedColumn<String> questionIds = GeneratedColumn<String>(
    'question_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    refId,
    startedAt,
    finishedAt,
    score,
    total,
    questionIds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_attempt';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAttemptData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('question_ids')) {
      context.handle(
        _questionIdsMeta,
        questionIds.isAcceptableOrUnknown(
          data['question_ids']!,
          _questionIdsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionIdsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizAttemptData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAttemptData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finished_at'],
      ),
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      ),
      questionIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_ids'],
      )!,
    );
  }

  @override
  QuizAttempt createAlias(String alias) {
    return QuizAttempt(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class QuizAttemptData extends DataClass implements Insertable<QuizAttemptData> {
  final int id;
  final String kind;
  final String refId;

  /// lesson id | track/module | review session id | gate id
  final String startedAt;
  final String? finishedAt;

  /// NULL = đang dở (kể cả gate tạm dừng)
  final int? score;
  final int? total;
  final String questionIds;
  const QuizAttemptData({
    required this.id,
    required this.kind,
    required this.refId,
    required this.startedAt,
    this.finishedAt,
    this.score,
    this.total,
    required this.questionIds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['ref_id'] = Variable<String>(refId);
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(finishedAt);
    }
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    map['question_ids'] = Variable<String>(questionIds);
    return map;
  }

  QuizAttemptCompanion toCompanion(bool nullToAbsent) {
    return QuizAttemptCompanion(
      id: Value(id),
      kind: Value(kind),
      refId: Value(refId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
      questionIds: Value(questionIds),
    );
  }

  factory QuizAttemptData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAttemptData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String>(json['ref_id']),
      startedAt: serializer.fromJson<String>(json['started_at']),
      finishedAt: serializer.fromJson<String?>(json['finished_at']),
      score: serializer.fromJson<int?>(json['score']),
      total: serializer.fromJson<int?>(json['total']),
      questionIds: serializer.fromJson<String>(json['question_ids']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'ref_id': serializer.toJson<String>(refId),
      'started_at': serializer.toJson<String>(startedAt),
      'finished_at': serializer.toJson<String?>(finishedAt),
      'score': serializer.toJson<int?>(score),
      'total': serializer.toJson<int?>(total),
      'question_ids': serializer.toJson<String>(questionIds),
    };
  }

  QuizAttemptData copyWith({
    int? id,
    String? kind,
    String? refId,
    String? startedAt,
    Value<String?> finishedAt = const Value.absent(),
    Value<int?> score = const Value.absent(),
    Value<int?> total = const Value.absent(),
    String? questionIds,
  }) => QuizAttemptData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    score: score.present ? score.value : this.score,
    total: total.present ? total.value : this.total,
    questionIds: questionIds ?? this.questionIds,
  );
  QuizAttemptData copyWithCompanion(QuizAttemptCompanion data) {
    return QuizAttemptData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      score: data.score.present ? data.score.value : this.score,
      total: data.total.present ? data.total.value : this.total,
      questionIds: data.questionIds.present
          ? data.questionIds.value
          : this.questionIds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('score: $score, ')
          ..write('total: $total, ')
          ..write('questionIds: $questionIds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    refId,
    startedAt,
    finishedAt,
    score,
    total,
    questionIds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAttemptData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.score == this.score &&
          other.total == this.total &&
          other.questionIds == this.questionIds);
}

class QuizAttemptCompanion extends UpdateCompanion<QuizAttemptData> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> refId;
  final Value<String> startedAt;
  final Value<String?> finishedAt;
  final Value<int?> score;
  final Value<int?> total;
  final Value<String> questionIds;
  const QuizAttemptCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.score = const Value.absent(),
    this.total = const Value.absent(),
    this.questionIds = const Value.absent(),
  });
  QuizAttemptCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String refId,
    required String startedAt,
    this.finishedAt = const Value.absent(),
    this.score = const Value.absent(),
    this.total = const Value.absent(),
    required String questionIds,
  }) : kind = Value(kind),
       refId = Value(refId),
       startedAt = Value(startedAt),
       questionIds = Value(questionIds);
  static Insertable<QuizAttemptData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<String>? startedAt,
    Expression<String>? finishedAt,
    Expression<int>? score,
    Expression<int>? total,
    Expression<String>? questionIds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (score != null) 'score': score,
      if (total != null) 'total': total,
      if (questionIds != null) 'question_ids': questionIds,
    });
  }

  QuizAttemptCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? refId,
    Value<String>? startedAt,
    Value<String?>? finishedAt,
    Value<int?>? score,
    Value<int?>? total,
    Value<String>? questionIds,
  }) {
    return QuizAttemptCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      score: score ?? this.score,
      total: total ?? this.total,
      questionIds: questionIds ?? this.questionIds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(finishedAt.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (questionIds.present) {
      map['question_ids'] = Variable<String>(questionIds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('score: $score, ')
          ..write('total: $total, ')
          ..write('questionIds: $questionIds')
          ..write(')'))
        .toString();
  }
}

class QuizAnswer extends Table with TableInfo<QuizAnswer, QuizAnswerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  QuizAnswer(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  late final GeneratedColumn<int> attemptId = GeneratedColumn<int>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES quiz_attempt(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  late final GeneratedColumn<String> answeredAt = GeneratedColumn<String>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _flaggedMeta = const VerificationMeta(
    'flagged',
  );
  late final GeneratedColumn<int> flagged = GeneratedColumn<int>(
    'flagged',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    attemptId,
    questionId,
    answer,
    correct,
    answeredAt,
    flagged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_answer';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAnswerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    if (data.containsKey('flagged')) {
      context.handle(
        _flaggedMeta,
        flagged.isAcceptableOrUnknown(data['flagged']!, _flaggedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attemptId, questionId};
  @override
  QuizAnswerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAnswerData(
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answered_at'],
      )!,
      flagged: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flagged'],
      )!,
    );
  }

  @override
  QuizAnswer createAlias(String alias) {
    return QuizAnswer(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(attempt_id, question_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class QuizAnswerData extends DataClass implements Insertable<QuizAnswerData> {
  final int attemptId;
  final String questionId;
  final String answer;

  /// JSON: ["b"] | ["a","c"] | ["b","d","c","a"] | ["utf-8"]
  final int correct;

  /// 0/1
  final String answeredAt;
  final int flagged;
  const QuizAnswerData({
    required this.attemptId,
    required this.questionId,
    required this.answer,
    required this.correct,
    required this.answeredAt,
    required this.flagged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attempt_id'] = Variable<int>(attemptId);
    map['question_id'] = Variable<String>(questionId);
    map['answer'] = Variable<String>(answer);
    map['correct'] = Variable<int>(correct);
    map['answered_at'] = Variable<String>(answeredAt);
    map['flagged'] = Variable<int>(flagged);
    return map;
  }

  QuizAnswerCompanion toCompanion(bool nullToAbsent) {
    return QuizAnswerCompanion(
      attemptId: Value(attemptId),
      questionId: Value(questionId),
      answer: Value(answer),
      correct: Value(correct),
      answeredAt: Value(answeredAt),
      flagged: Value(flagged),
    );
  }

  factory QuizAnswerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAnswerData(
      attemptId: serializer.fromJson<int>(json['attempt_id']),
      questionId: serializer.fromJson<String>(json['question_id']),
      answer: serializer.fromJson<String>(json['answer']),
      correct: serializer.fromJson<int>(json['correct']),
      answeredAt: serializer.fromJson<String>(json['answered_at']),
      flagged: serializer.fromJson<int>(json['flagged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attempt_id': serializer.toJson<int>(attemptId),
      'question_id': serializer.toJson<String>(questionId),
      'answer': serializer.toJson<String>(answer),
      'correct': serializer.toJson<int>(correct),
      'answered_at': serializer.toJson<String>(answeredAt),
      'flagged': serializer.toJson<int>(flagged),
    };
  }

  QuizAnswerData copyWith({
    int? attemptId,
    String? questionId,
    String? answer,
    int? correct,
    String? answeredAt,
    int? flagged,
  }) => QuizAnswerData(
    attemptId: attemptId ?? this.attemptId,
    questionId: questionId ?? this.questionId,
    answer: answer ?? this.answer,
    correct: correct ?? this.correct,
    answeredAt: answeredAt ?? this.answeredAt,
    flagged: flagged ?? this.flagged,
  );
  QuizAnswerData copyWithCompanion(QuizAnswerCompanion data) {
    return QuizAnswerData(
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      answer: data.answer.present ? data.answer.value : this.answer,
      correct: data.correct.present ? data.correct.value : this.correct,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      flagged: data.flagged.present ? data.flagged.value : this.flagged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAnswerData(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('flagged: $flagged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(attemptId, questionId, answer, correct, answeredAt, flagged);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAnswerData &&
          other.attemptId == this.attemptId &&
          other.questionId == this.questionId &&
          other.answer == this.answer &&
          other.correct == this.correct &&
          other.answeredAt == this.answeredAt &&
          other.flagged == this.flagged);
}

class QuizAnswerCompanion extends UpdateCompanion<QuizAnswerData> {
  final Value<int> attemptId;
  final Value<String> questionId;
  final Value<String> answer;
  final Value<int> correct;
  final Value<String> answeredAt;
  final Value<int> flagged;
  final Value<int> rowid;
  const QuizAnswerCompanion({
    this.attemptId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.answer = const Value.absent(),
    this.correct = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.flagged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizAnswerCompanion.insert({
    required int attemptId,
    required String questionId,
    required String answer,
    required int correct,
    required String answeredAt,
    this.flagged = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attemptId = Value(attemptId),
       questionId = Value(questionId),
       answer = Value(answer),
       correct = Value(correct),
       answeredAt = Value(answeredAt);
  static Insertable<QuizAnswerData> custom({
    Expression<int>? attemptId,
    Expression<String>? questionId,
    Expression<String>? answer,
    Expression<int>? correct,
    Expression<String>? answeredAt,
    Expression<int>? flagged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attemptId != null) 'attempt_id': attemptId,
      if (questionId != null) 'question_id': questionId,
      if (answer != null) 'answer': answer,
      if (correct != null) 'correct': correct,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (flagged != null) 'flagged': flagged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizAnswerCompanion copyWith({
    Value<int>? attemptId,
    Value<String>? questionId,
    Value<String>? answer,
    Value<int>? correct,
    Value<String>? answeredAt,
    Value<int>? flagged,
    Value<int>? rowid,
  }) {
    return QuizAnswerCompanion(
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      answer: answer ?? this.answer,
      correct: correct ?? this.correct,
      answeredAt: answeredAt ?? this.answeredAt,
      flagged: flagged ?? this.flagged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attemptId.present) {
      map['attempt_id'] = Variable<int>(attemptId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<String>(answeredAt.value);
    }
    if (flagged.present) {
      map['flagged'] = Variable<int>(flagged.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAnswerCompanion(')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('flagged: $flagged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReviewItem extends Table with TableInfo<ReviewItem, ReviewItemData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReviewItem(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (kind IN (\'question\', \'term\'))',
  );
  static const VerificationMeta _sourceLessonMeta = const VerificationMeta(
    'sourceLesson',
  );
  late final GeneratedColumn<String> sourceLesson = GeneratedColumn<String>(
    'source_lesson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  late final GeneratedColumn<int> tier = GeneratedColumn<int>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  late final GeneratedColumn<String> dueAt = GeneratedColumn<String>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastResultMeta = const VerificationMeta(
    'lastResult',
  );
  late final GeneratedColumn<int> lastResult = GeneratedColumn<int>(
    'last_result',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _timesSeenMeta = const VerificationMeta(
    'timesSeen',
  );
  late final GeneratedColumn<int> timesSeen = GeneratedColumn<int>(
    'times_seen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta(
    'retired',
  );
  late final GeneratedColumn<int> retired = GeneratedColumn<int>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    kind,
    sourceLesson,
    tier,
    dueAt,
    lastResult,
    timesSeen,
    retired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_item';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewItemData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source_lesson')) {
      context.handle(
        _sourceLessonMeta,
        sourceLesson.isAcceptableOrUnknown(
          data['source_lesson']!,
          _sourceLessonMeta,
        ),
      );
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('last_result')) {
      context.handle(
        _lastResultMeta,
        lastResult.isAcceptableOrUnknown(data['last_result']!, _lastResultMeta),
      );
    }
    if (data.containsKey('times_seen')) {
      context.handle(
        _timesSeenMeta,
        timesSeen.isAcceptableOrUnknown(data['times_seen']!, _timesSeenMeta),
      );
    }
    if (data.containsKey('retired')) {
      context.handle(
        _retiredMeta,
        retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId};
  @override
  ReviewItemData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewItemData(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      sourceLesson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_lesson'],
      ),
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tier'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_at'],
      )!,
      lastResult: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_result'],
      ),
      timesSeen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_seen'],
      )!,
      retired: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retired'],
      )!,
    );
  }

  @override
  ReviewItem createAlias(String alias) {
    return ReviewItem(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ReviewItemData extends DataClass implements Insertable<ReviewItemData> {
  final String? itemId;

  /// question id, hoặc "term:<slug>" cho flashcard thuật ngữ
  final String kind;
  final String? sourceLesson;

  /// lesson id (câu) / introduced_in (term); NULL cho câu gate
  final int tier;

  /// bậc 0..4
  final String dueAt;
  final int? lastResult;
  final int timesSeen;
  final int retired;
  const ReviewItemData({
    this.itemId,
    required this.kind,
    this.sourceLesson,
    required this.tier,
    required this.dueAt,
    this.lastResult,
    required this.timesSeen,
    required this.retired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || sourceLesson != null) {
      map['source_lesson'] = Variable<String>(sourceLesson);
    }
    map['tier'] = Variable<int>(tier);
    map['due_at'] = Variable<String>(dueAt);
    if (!nullToAbsent || lastResult != null) {
      map['last_result'] = Variable<int>(lastResult);
    }
    map['times_seen'] = Variable<int>(timesSeen);
    map['retired'] = Variable<int>(retired);
    return map;
  }

  ReviewItemCompanion toCompanion(bool nullToAbsent) {
    return ReviewItemCompanion(
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      kind: Value(kind),
      sourceLesson: sourceLesson == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceLesson),
      tier: Value(tier),
      dueAt: Value(dueAt),
      lastResult: lastResult == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResult),
      timesSeen: Value(timesSeen),
      retired: Value(retired),
    );
  }

  factory ReviewItemData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewItemData(
      itemId: serializer.fromJson<String?>(json['item_id']),
      kind: serializer.fromJson<String>(json['kind']),
      sourceLesson: serializer.fromJson<String?>(json['source_lesson']),
      tier: serializer.fromJson<int>(json['tier']),
      dueAt: serializer.fromJson<String>(json['due_at']),
      lastResult: serializer.fromJson<int?>(json['last_result']),
      timesSeen: serializer.fromJson<int>(json['times_seen']),
      retired: serializer.fromJson<int>(json['retired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'item_id': serializer.toJson<String?>(itemId),
      'kind': serializer.toJson<String>(kind),
      'source_lesson': serializer.toJson<String?>(sourceLesson),
      'tier': serializer.toJson<int>(tier),
      'due_at': serializer.toJson<String>(dueAt),
      'last_result': serializer.toJson<int?>(lastResult),
      'times_seen': serializer.toJson<int>(timesSeen),
      'retired': serializer.toJson<int>(retired),
    };
  }

  ReviewItemData copyWith({
    Value<String?> itemId = const Value.absent(),
    String? kind,
    Value<String?> sourceLesson = const Value.absent(),
    int? tier,
    String? dueAt,
    Value<int?> lastResult = const Value.absent(),
    int? timesSeen,
    int? retired,
  }) => ReviewItemData(
    itemId: itemId.present ? itemId.value : this.itemId,
    kind: kind ?? this.kind,
    sourceLesson: sourceLesson.present ? sourceLesson.value : this.sourceLesson,
    tier: tier ?? this.tier,
    dueAt: dueAt ?? this.dueAt,
    lastResult: lastResult.present ? lastResult.value : this.lastResult,
    timesSeen: timesSeen ?? this.timesSeen,
    retired: retired ?? this.retired,
  );
  ReviewItemData copyWithCompanion(ReviewItemCompanion data) {
    return ReviewItemData(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      sourceLesson: data.sourceLesson.present
          ? data.sourceLesson.value
          : this.sourceLesson,
      tier: data.tier.present ? data.tier.value : this.tier,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      lastResult: data.lastResult.present
          ? data.lastResult.value
          : this.lastResult,
      timesSeen: data.timesSeen.present ? data.timesSeen.value : this.timesSeen,
      retired: data.retired.present ? data.retired.value : this.retired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemData(')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('sourceLesson: $sourceLesson, ')
          ..write('tier: $tier, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastResult: $lastResult, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('retired: $retired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemId,
    kind,
    sourceLesson,
    tier,
    dueAt,
    lastResult,
    timesSeen,
    retired,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewItemData &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.sourceLesson == this.sourceLesson &&
          other.tier == this.tier &&
          other.dueAt == this.dueAt &&
          other.lastResult == this.lastResult &&
          other.timesSeen == this.timesSeen &&
          other.retired == this.retired);
}

class ReviewItemCompanion extends UpdateCompanion<ReviewItemData> {
  final Value<String?> itemId;
  final Value<String> kind;
  final Value<String?> sourceLesson;
  final Value<int> tier;
  final Value<String> dueAt;
  final Value<int?> lastResult;
  final Value<int> timesSeen;
  final Value<int> retired;
  final Value<int> rowid;
  const ReviewItemCompanion({
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.sourceLesson = const Value.absent(),
    this.tier = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.lastResult = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.retired = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewItemCompanion.insert({
    this.itemId = const Value.absent(),
    required String kind,
    this.sourceLesson = const Value.absent(),
    this.tier = const Value.absent(),
    required String dueAt,
    this.lastResult = const Value.absent(),
    this.timesSeen = const Value.absent(),
    this.retired = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       dueAt = Value(dueAt);
  static Insertable<ReviewItemData> custom({
    Expression<String>? itemId,
    Expression<String>? kind,
    Expression<String>? sourceLesson,
    Expression<int>? tier,
    Expression<String>? dueAt,
    Expression<int>? lastResult,
    Expression<int>? timesSeen,
    Expression<int>? retired,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (sourceLesson != null) 'source_lesson': sourceLesson,
      if (tier != null) 'tier': tier,
      if (dueAt != null) 'due_at': dueAt,
      if (lastResult != null) 'last_result': lastResult,
      if (timesSeen != null) 'times_seen': timesSeen,
      if (retired != null) 'retired': retired,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewItemCompanion copyWith({
    Value<String?>? itemId,
    Value<String>? kind,
    Value<String?>? sourceLesson,
    Value<int>? tier,
    Value<String>? dueAt,
    Value<int?>? lastResult,
    Value<int>? timesSeen,
    Value<int>? retired,
    Value<int>? rowid,
  }) {
    return ReviewItemCompanion(
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      sourceLesson: sourceLesson ?? this.sourceLesson,
      tier: tier ?? this.tier,
      dueAt: dueAt ?? this.dueAt,
      lastResult: lastResult ?? this.lastResult,
      timesSeen: timesSeen ?? this.timesSeen,
      retired: retired ?? this.retired,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (sourceLesson.present) {
      map['source_lesson'] = Variable<String>(sourceLesson.value);
    }
    if (tier.present) {
      map['tier'] = Variable<int>(tier.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<String>(dueAt.value);
    }
    if (lastResult.present) {
      map['last_result'] = Variable<int>(lastResult.value);
    }
    if (timesSeen.present) {
      map['times_seen'] = Variable<int>(timesSeen.value);
    }
    if (retired.present) {
      map['retired'] = Variable<int>(retired.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewItemCompanion(')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('sourceLesson: $sourceLesson, ')
          ..write('tier: $tier, ')
          ..write('dueAt: $dueAt, ')
          ..write('lastResult: $lastResult, ')
          ..write('timesSeen: $timesSeen, ')
          ..write('retired: $retired, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class VocabSeen extends Table with TableInfo<VocabSeen, VocabSeenData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  VocabSeen(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _firstLessonIdMeta = const VerificationMeta(
    'firstLessonId',
  );
  late final GeneratedColumn<String> firstLessonId = GeneratedColumn<String>(
    'first_lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _seenAtMeta = const VerificationMeta('seenAt');
  late final GeneratedColumn<String> seenAt = GeneratedColumn<String>(
    'seen_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [term, firstLessonId, seenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocab_seen';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabSeenData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    }
    if (data.containsKey('first_lesson_id')) {
      context.handle(
        _firstLessonIdMeta,
        firstLessonId.isAcceptableOrUnknown(
          data['first_lesson_id']!,
          _firstLessonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstLessonIdMeta);
    }
    if (data.containsKey('seen_at')) {
      context.handle(
        _seenAtMeta,
        seenAt.isAcceptableOrUnknown(data['seen_at']!, _seenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_seenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {term};
  @override
  VocabSeenData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabSeenData(
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      ),
      firstLessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_lesson_id'],
      )!,
      seenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seen_at'],
      )!,
    );
  }

  @override
  VocabSeen createAlias(String alias) {
    return VocabSeen(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class VocabSeenData extends DataClass implements Insertable<VocabSeenData> {
  final String? term;
  final String firstLessonId;
  final String seenAt;
  const VocabSeenData({
    this.term,
    required this.firstLessonId,
    required this.seenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || term != null) {
      map['term'] = Variable<String>(term);
    }
    map['first_lesson_id'] = Variable<String>(firstLessonId);
    map['seen_at'] = Variable<String>(seenAt);
    return map;
  }

  VocabSeenCompanion toCompanion(bool nullToAbsent) {
    return VocabSeenCompanion(
      term: term == null && nullToAbsent ? const Value.absent() : Value(term),
      firstLessonId: Value(firstLessonId),
      seenAt: Value(seenAt),
    );
  }

  factory VocabSeenData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabSeenData(
      term: serializer.fromJson<String?>(json['term']),
      firstLessonId: serializer.fromJson<String>(json['first_lesson_id']),
      seenAt: serializer.fromJson<String>(json['seen_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'term': serializer.toJson<String?>(term),
      'first_lesson_id': serializer.toJson<String>(firstLessonId),
      'seen_at': serializer.toJson<String>(seenAt),
    };
  }

  VocabSeenData copyWith({
    Value<String?> term = const Value.absent(),
    String? firstLessonId,
    String? seenAt,
  }) => VocabSeenData(
    term: term.present ? term.value : this.term,
    firstLessonId: firstLessonId ?? this.firstLessonId,
    seenAt: seenAt ?? this.seenAt,
  );
  VocabSeenData copyWithCompanion(VocabSeenCompanion data) {
    return VocabSeenData(
      term: data.term.present ? data.term.value : this.term,
      firstLessonId: data.firstLessonId.present
          ? data.firstLessonId.value
          : this.firstLessonId,
      seenAt: data.seenAt.present ? data.seenAt.value : this.seenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabSeenData(')
          ..write('term: $term, ')
          ..write('firstLessonId: $firstLessonId, ')
          ..write('seenAt: $seenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(term, firstLessonId, seenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabSeenData &&
          other.term == this.term &&
          other.firstLessonId == this.firstLessonId &&
          other.seenAt == this.seenAt);
}

class VocabSeenCompanion extends UpdateCompanion<VocabSeenData> {
  final Value<String?> term;
  final Value<String> firstLessonId;
  final Value<String> seenAt;
  final Value<int> rowid;
  const VocabSeenCompanion({
    this.term = const Value.absent(),
    this.firstLessonId = const Value.absent(),
    this.seenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabSeenCompanion.insert({
    this.term = const Value.absent(),
    required String firstLessonId,
    required String seenAt,
    this.rowid = const Value.absent(),
  }) : firstLessonId = Value(firstLessonId),
       seenAt = Value(seenAt);
  static Insertable<VocabSeenData> custom({
    Expression<String>? term,
    Expression<String>? firstLessonId,
    Expression<String>? seenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (term != null) 'term': term,
      if (firstLessonId != null) 'first_lesson_id': firstLessonId,
      if (seenAt != null) 'seen_at': seenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabSeenCompanion copyWith({
    Value<String?>? term,
    Value<String>? firstLessonId,
    Value<String>? seenAt,
    Value<int>? rowid,
  }) {
    return VocabSeenCompanion(
      term: term ?? this.term,
      firstLessonId: firstLessonId ?? this.firstLessonId,
      seenAt: seenAt ?? this.seenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (firstLessonId.present) {
      map['first_lesson_id'] = Variable<String>(firstLessonId.value);
    }
    if (seenAt.present) {
      map['seen_at'] = Variable<String>(seenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabSeenCompanion(')
          ..write('term: $term, ')
          ..write('firstLessonId: $firstLessonId, ')
          ..write('seenAt: $seenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StageProgress extends Table
    with TableInfo<StageProgress, StageProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StageProgress(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _gatePassedAtMeta = const VerificationMeta(
    'gatePassedAt',
  );
  late final GeneratedColumn<String> gatePassedAt = GeneratedColumn<String>(
    'gate_passed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bestGateScoreMeta = const VerificationMeta(
    'bestGateScore',
  );
  late final GeneratedColumn<double> bestGateScore = GeneratedColumn<double>(
    'best_gate_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    stage,
    gatePassedAt,
    bestGateScore,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stage_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<StageProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('gate_passed_at')) {
      context.handle(
        _gatePassedAtMeta,
        gatePassedAt.isAcceptableOrUnknown(
          data['gate_passed_at']!,
          _gatePassedAtMeta,
        ),
      );
    }
    if (data.containsKey('best_gate_score')) {
      context.handle(
        _bestGateScoreMeta,
        bestGateScore.isAcceptableOrUnknown(
          data['best_gate_score']!,
          _bestGateScoreMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stage};
  @override
  StageProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StageProgressData(
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      gatePassedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gate_passed_at'],
      ),
      bestGateScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_gate_score'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  StageProgress createAlias(String alias) {
    return StageProgress(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class StageProgressData extends DataClass
    implements Insertable<StageProgressData> {
  final int stage;
  final String? gatePassedAt;
  final double? bestGateScore;
  final int attempts;
  const StageProgressData({
    required this.stage,
    this.gatePassedAt,
    this.bestGateScore,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stage'] = Variable<int>(stage);
    if (!nullToAbsent || gatePassedAt != null) {
      map['gate_passed_at'] = Variable<String>(gatePassedAt);
    }
    if (!nullToAbsent || bestGateScore != null) {
      map['best_gate_score'] = Variable<double>(bestGateScore);
    }
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  StageProgressCompanion toCompanion(bool nullToAbsent) {
    return StageProgressCompanion(
      stage: Value(stage),
      gatePassedAt: gatePassedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(gatePassedAt),
      bestGateScore: bestGateScore == null && nullToAbsent
          ? const Value.absent()
          : Value(bestGateScore),
      attempts: Value(attempts),
    );
  }

  factory StageProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StageProgressData(
      stage: serializer.fromJson<int>(json['stage']),
      gatePassedAt: serializer.fromJson<String?>(json['gate_passed_at']),
      bestGateScore: serializer.fromJson<double?>(json['best_gate_score']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stage': serializer.toJson<int>(stage),
      'gate_passed_at': serializer.toJson<String?>(gatePassedAt),
      'best_gate_score': serializer.toJson<double?>(bestGateScore),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  StageProgressData copyWith({
    int? stage,
    Value<String?> gatePassedAt = const Value.absent(),
    Value<double?> bestGateScore = const Value.absent(),
    int? attempts,
  }) => StageProgressData(
    stage: stage ?? this.stage,
    gatePassedAt: gatePassedAt.present ? gatePassedAt.value : this.gatePassedAt,
    bestGateScore: bestGateScore.present
        ? bestGateScore.value
        : this.bestGateScore,
    attempts: attempts ?? this.attempts,
  );
  StageProgressData copyWithCompanion(StageProgressCompanion data) {
    return StageProgressData(
      stage: data.stage.present ? data.stage.value : this.stage,
      gatePassedAt: data.gatePassedAt.present
          ? data.gatePassedAt.value
          : this.gatePassedAt,
      bestGateScore: data.bestGateScore.present
          ? data.bestGateScore.value
          : this.bestGateScore,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StageProgressData(')
          ..write('stage: $stage, ')
          ..write('gatePassedAt: $gatePassedAt, ')
          ..write('bestGateScore: $bestGateScore, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stage, gatePassedAt, bestGateScore, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StageProgressData &&
          other.stage == this.stage &&
          other.gatePassedAt == this.gatePassedAt &&
          other.bestGateScore == this.bestGateScore &&
          other.attempts == this.attempts);
}

class StageProgressCompanion extends UpdateCompanion<StageProgressData> {
  final Value<int> stage;
  final Value<String?> gatePassedAt;
  final Value<double?> bestGateScore;
  final Value<int> attempts;
  const StageProgressCompanion({
    this.stage = const Value.absent(),
    this.gatePassedAt = const Value.absent(),
    this.bestGateScore = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  StageProgressCompanion.insert({
    this.stage = const Value.absent(),
    this.gatePassedAt = const Value.absent(),
    this.bestGateScore = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  static Insertable<StageProgressData> custom({
    Expression<int>? stage,
    Expression<String>? gatePassedAt,
    Expression<double>? bestGateScore,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (stage != null) 'stage': stage,
      if (gatePassedAt != null) 'gate_passed_at': gatePassedAt,
      if (bestGateScore != null) 'best_gate_score': bestGateScore,
      if (attempts != null) 'attempts': attempts,
    });
  }

  StageProgressCompanion copyWith({
    Value<int>? stage,
    Value<String?>? gatePassedAt,
    Value<double?>? bestGateScore,
    Value<int>? attempts,
  }) {
    return StageProgressCompanion(
      stage: stage ?? this.stage,
      gatePassedAt: gatePassedAt ?? this.gatePassedAt,
      bestGateScore: bestGateScore ?? this.bestGateScore,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (gatePassedAt.present) {
      map['gate_passed_at'] = Variable<String>(gatePassedAt.value);
    }
    if (bestGateScore.present) {
      map['best_gate_score'] = Variable<double>(bestGateScore.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StageProgressCompanion(')
          ..write('stage: $stage, ')
          ..write('gatePassedAt: $gatePassedAt, ')
          ..write('bestGateScore: $bestGateScore, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

class Settings extends Table with TableInfo<Settings, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Setting extends DataClass implements Insertable<Setting> {
  final String? key;
  final String value;
  const Setting({this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String?>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String?>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({
    Value<String?> key = const Value.absent(),
    String? value,
  }) => Setting(
    key: key.present ? key.value : this.key,
    value: value ?? this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String?> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.key = const Value.absent(),
    required String value,
    this.rowid = const Value.absent(),
  }) : value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String?>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Event extends Table with TableInfo<Event, EventData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Event(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  late final GeneratedColumn<String> ts = GeneratedColumn<String>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [id, ts, kind, ref, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ts'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  Event createAlias(String alias) {
    return Event(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EventData extends DataClass implements Insertable<EventData> {
  final int id;
  final String ts;
  final String kind;
  final String? ref;
  final double? value;
  const EventData({
    required this.id,
    required this.ts,
    required this.kind,
    this.ref,
    this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<String>(ts);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || ref != null) {
      map['ref'] = Variable<String>(ref);
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    return map;
  }

  EventCompanion toCompanion(bool nullToAbsent) {
    return EventCompanion(
      id: Value(id),
      ts: Value(ts),
      kind: Value(kind),
      ref: ref == null && nullToAbsent ? const Value.absent() : Value(ref),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory EventData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventData(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<String>(json['ts']),
      kind: serializer.fromJson<String>(json['kind']),
      ref: serializer.fromJson<String?>(json['ref']),
      value: serializer.fromJson<double?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<String>(ts),
      'kind': serializer.toJson<String>(kind),
      'ref': serializer.toJson<String?>(ref),
      'value': serializer.toJson<double?>(value),
    };
  }

  EventData copyWith({
    int? id,
    String? ts,
    String? kind,
    Value<String?> ref = const Value.absent(),
    Value<double?> value = const Value.absent(),
  }) => EventData(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    kind: kind ?? this.kind,
    ref: ref.present ? ref.value : this.ref,
    value: value.present ? value.value : this.value,
  );
  EventData copyWithCompanion(EventCompanion data) {
    return EventData(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      kind: data.kind.present ? data.kind.value : this.kind,
      ref: data.ref.present ? data.ref.value : this.ref,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventData(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ts, kind, ref, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventData &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.kind == this.kind &&
          other.ref == this.ref &&
          other.value == this.value);
}

class EventCompanion extends UpdateCompanion<EventData> {
  final Value<int> id;
  final Value<String> ts;
  final Value<String> kind;
  final Value<String?> ref;
  final Value<double?> value;
  const EventCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.kind = const Value.absent(),
    this.ref = const Value.absent(),
    this.value = const Value.absent(),
  });
  EventCompanion.insert({
    this.id = const Value.absent(),
    required String ts,
    required String kind,
    this.ref = const Value.absent(),
    this.value = const Value.absent(),
  }) : ts = Value(ts),
       kind = Value(kind);
  static Insertable<EventData> custom({
    Expression<int>? id,
    Expression<String>? ts,
    Expression<String>? kind,
    Expression<String>? ref,
    Expression<double>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (kind != null) 'kind': kind,
      if (ref != null) 'ref': ref,
      if (value != null) 'value': value,
    });
  }

  EventCompanion copyWith({
    Value<int>? id,
    Value<String>? ts,
    Value<String>? kind,
    Value<String?>? ref,
    Value<double?>? value,
  }) {
    return EventCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      kind: kind ?? this.kind,
      ref: ref ?? this.ref,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<String>(ts.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('kind: $kind, ')
          ..write('ref: $ref, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class SearchIndex extends Table
    with
        TableInfo<SearchIndex, SearchIndexData>,
        VirtualTableInfo<SearchIndex, SearchIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchIndex(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [lessonId, lang, title, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchIndexData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SearchIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchIndexData(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  SearchIndex createAlias(String alias) {
    return SearchIndex(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(lesson_id UNINDEXED, lang UNINDEXED, title, body, tokenize = "unicode61 remove_diacritics 0")';
}

class SearchIndexData extends DataClass implements Insertable<SearchIndexData> {
  final String lessonId;
  final String lang;
  final String title;
  final String body;
  const SearchIndexData({
    required this.lessonId,
    required this.lang,
    required this.title,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['lang'] = Variable<String>(lang);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  SearchIndexCompanion toCompanion(bool nullToAbsent) {
    return SearchIndexCompanion(
      lessonId: Value(lessonId),
      lang: Value(lang),
      title: Value(title),
      body: Value(body),
    );
  }

  factory SearchIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchIndexData(
      lessonId: serializer.fromJson<String>(json['lesson_id']),
      lang: serializer.fromJson<String>(json['lang']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lesson_id': serializer.toJson<String>(lessonId),
      'lang': serializer.toJson<String>(lang),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  SearchIndexData copyWith({
    String? lessonId,
    String? lang,
    String? title,
    String? body,
  }) => SearchIndexData(
    lessonId: lessonId ?? this.lessonId,
    lang: lang ?? this.lang,
    title: title ?? this.title,
    body: body ?? this.body,
  );
  SearchIndexData copyWithCompanion(SearchIndexCompanion data) {
    return SearchIndexData(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      lang: data.lang.present ? data.lang.value : this.lang,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexData(')
          ..write('lessonId: $lessonId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, lang, title, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchIndexData &&
          other.lessonId == this.lessonId &&
          other.lang == this.lang &&
          other.title == this.title &&
          other.body == this.body);
}

class SearchIndexCompanion extends UpdateCompanion<SearchIndexData> {
  final Value<String> lessonId;
  final Value<String> lang;
  final Value<String> title;
  final Value<String> body;
  final Value<int> rowid;
  const SearchIndexCompanion({
    this.lessonId = const Value.absent(),
    this.lang = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchIndexCompanion.insert({
    required String lessonId,
    required String lang,
    required String title,
    required String body,
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       lang = Value(lang),
       title = Value(title),
       body = Value(body);
  static Insertable<SearchIndexData> custom({
    Expression<String>? lessonId,
    Expression<String>? lang,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (lang != null) 'lang': lang,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchIndexCompanion copyWith({
    Value<String>? lessonId,
    Value<String>? lang,
    Value<String>? title,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return SearchIndexCompanion(
      lessonId: lessonId ?? this.lessonId,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('lang: $lang, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final LessonProgress lessonProgress = LessonProgress(this);
  late final QuizAttempt quizAttempt = QuizAttempt(this);
  late final QuizAnswer quizAnswer = QuizAnswer(this);
  late final ReviewItem reviewItem = ReviewItem(this);
  late final VocabSeen vocabSeen = VocabSeen(this);
  late final StageProgress stageProgress = StageProgress(this);
  late final Settings settings = Settings(this);
  late final Event event = Event(this);
  late final SearchIndex searchIndex = SearchIndex(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lessonProgress,
    quizAttempt,
    quizAnswer,
    reviewItem,
    vocabSeen,
    stageProgress,
    settings,
    event,
    searchIndex,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'quiz_attempt',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('quiz_answer', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $LessonProgressCreateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<String?> lessonId,
      required String status,
      Value<String?> firstOpenedAt,
      Value<String?> readAt,
      Value<String?> passedAt,
      Value<double?> bestScore,
      Value<double> scrollRatio,
      Value<int> prereqWarned,
      Value<int?> contentVersion,
      Value<int> rowid,
    });
typedef $LessonProgressUpdateCompanionBuilder =
    LessonProgressCompanion Function({
      Value<String?> lessonId,
      Value<String> status,
      Value<String?> firstOpenedAt,
      Value<String?> readAt,
      Value<String?> passedAt,
      Value<double?> bestScore,
      Value<double> scrollRatio,
      Value<int> prereqWarned,
      Value<int?> contentVersion,
      Value<int> rowid,
    });

class $LessonProgressFilterComposer
    extends Composer<_$AppDatabase, LessonProgress> {
  $LessonProgressFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstOpenedAt => $composableBuilder(
    column: $table.firstOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passedAt => $composableBuilder(
    column: $table.passedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scrollRatio => $composableBuilder(
    column: $table.scrollRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prereqWarned => $composableBuilder(
    column: $table.prereqWarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $LessonProgressOrderingComposer
    extends Composer<_$AppDatabase, LessonProgress> {
  $LessonProgressOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstOpenedAt => $composableBuilder(
    column: $table.firstOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passedAt => $composableBuilder(
    column: $table.passedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scrollRatio => $composableBuilder(
    column: $table.scrollRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prereqWarned => $composableBuilder(
    column: $table.prereqWarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $LessonProgressAnnotationComposer
    extends Composer<_$AppDatabase, LessonProgress> {
  $LessonProgressAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get firstOpenedAt => $composableBuilder(
    column: $table.firstOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<String> get passedAt =>
      $composableBuilder(column: $table.passedAt, builder: (column) => column);

  GeneratedColumn<double> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<double> get scrollRatio => $composableBuilder(
    column: $table.scrollRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prereqWarned => $composableBuilder(
    column: $table.prereqWarned,
    builder: (column) => column,
  );

  GeneratedColumn<int> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );
}

class $LessonProgressTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          LessonProgress,
          LessonProgressData,
          $LessonProgressFilterComposer,
          $LessonProgressOrderingComposer,
          $LessonProgressAnnotationComposer,
          $LessonProgressCreateCompanionBuilder,
          $LessonProgressUpdateCompanionBuilder,
          (
            LessonProgressData,
            BaseReferences<_$AppDatabase, LessonProgress, LessonProgressData>,
          ),
          LessonProgressData,
          PrefetchHooks Function()
        > {
  $LessonProgressTableManager(_$AppDatabase db, LessonProgress table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LessonProgressFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LessonProgressOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LessonProgressAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> lessonId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> firstOpenedAt = const Value.absent(),
                Value<String?> readAt = const Value.absent(),
                Value<String?> passedAt = const Value.absent(),
                Value<double?> bestScore = const Value.absent(),
                Value<double> scrollRatio = const Value.absent(),
                Value<int> prereqWarned = const Value.absent(),
                Value<int?> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion(
                lessonId: lessonId,
                status: status,
                firstOpenedAt: firstOpenedAt,
                readAt: readAt,
                passedAt: passedAt,
                bestScore: bestScore,
                scrollRatio: scrollRatio,
                prereqWarned: prereqWarned,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> lessonId = const Value.absent(),
                required String status,
                Value<String?> firstOpenedAt = const Value.absent(),
                Value<String?> readAt = const Value.absent(),
                Value<String?> passedAt = const Value.absent(),
                Value<double?> bestScore = const Value.absent(),
                Value<double> scrollRatio = const Value.absent(),
                Value<int> prereqWarned = const Value.absent(),
                Value<int?> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                lessonId: lessonId,
                status: status,
                firstOpenedAt: firstOpenedAt,
                readAt: readAt,
                passedAt: passedAt,
                bestScore: bestScore,
                scrollRatio: scrollRatio,
                prereqWarned: prereqWarned,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<LessonProgress, LessonProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    LessonProgress,
                    LessonProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $LessonProgressProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      LessonProgress,
      LessonProgressData,
      $LessonProgressFilterComposer,
      $LessonProgressOrderingComposer,
      $LessonProgressAnnotationComposer,
      $LessonProgressCreateCompanionBuilder,
      $LessonProgressUpdateCompanionBuilder,
      (
        LessonProgressData,
        BaseReferences<_$AppDatabase, LessonProgress, LessonProgressData>,
      ),
      LessonProgressData,
      PrefetchHooks Function()
    >;
typedef $QuizAttemptCreateCompanionBuilder = QuizAttemptCompanion Function({
  Value<int> id,
  required String kind,
  required String refId,
  required String startedAt,
  Value<String?> finishedAt,
  Value<int?> score,
  Value<int?> total,
  required String questionIds,
});
typedef $QuizAttemptUpdateCompanionBuilder = QuizAttemptCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> refId,
  Value<String> startedAt,
  Value<String?> finishedAt,
  Value<int?> score,
  Value<int?> total,
  Value<String> questionIds,
});

final class $QuizAttemptReferences
    extends BaseReferences<_$AppDatabase, QuizAttempt, QuizAttemptData> {
  $QuizAttemptReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<QuizAnswer, List<QuizAnswerData>>
  _quizAnswerRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quizAnswer,
    aliasName: 'quiz_attempt__id__quiz_answer__attempt_id',
  );

  $QuizAnswerProcessedTableManager get quizAnswerRefs {
    final manager = $QuizAnswerTableManager(
      $_db,
      $_db.quizAnswer,
    ).filter((f) => f.attemptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizAnswerRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $QuizAttemptFilterComposer extends Composer<_$AppDatabase, QuizAttempt> {
  $QuizAttemptFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> quizAnswerRefs(
    Expression<bool> Function($QuizAnswerFilterComposer f) f,
  ) {
    final $QuizAnswerFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizAnswer,
      getReferencedColumn: (t) => t.attemptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $QuizAnswerFilterComposer(
            $db: $db,
            $table: $db.quizAnswer,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $QuizAttemptOrderingComposer
    extends Composer<_$AppDatabase, QuizAttempt> {
  $QuizAttemptOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $QuizAttemptAnnotationComposer
    extends Composer<_$AppDatabase, QuizAttempt> {
  $QuizAttemptAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get questionIds => $composableBuilder(
    column: $table.questionIds,
    builder: (column) => column,
  );

  Expression<T> quizAnswerRefs<T extends Object>(
    Expression<T> Function($QuizAnswerAnnotationComposer a) f,
  ) {
    final $QuizAnswerAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizAnswer,
      getReferencedColumn: (t) => t.attemptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $QuizAnswerAnnotationComposer(
            $db: $db,
            $table: $db.quizAnswer,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $QuizAttemptTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          QuizAttempt,
          QuizAttemptData,
          $QuizAttemptFilterComposer,
          $QuizAttemptOrderingComposer,
          $QuizAttemptAnnotationComposer,
          $QuizAttemptCreateCompanionBuilder,
          $QuizAttemptUpdateCompanionBuilder,
          (QuizAttemptData, $QuizAttemptReferences),
          QuizAttemptData,
          PrefetchHooks Function({bool quizAnswerRefs})
        > {
  $QuizAttemptTableManager(_$AppDatabase db, QuizAttempt table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $QuizAttemptFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $QuizAttemptOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $QuizAttemptAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> total = const Value.absent(),
                Value<String> questionIds = const Value.absent(),
              }) => QuizAttemptCompanion(
                id: id,
                kind: kind,
                refId: refId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                score: score,
                total: total,
                questionIds: questionIds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String refId,
                required String startedAt,
                Value<String?> finishedAt = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> total = const Value.absent(),
                required String questionIds,
              }) => QuizAttemptCompanion.insert(
                id: id,
                kind: kind,
                refId: refId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                score: score,
                total: total,
                questionIds: questionIds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<QuizAttempt, QuizAttemptData>(table),
                  $QuizAttemptReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({quizAnswerRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (quizAnswerRefs) db.quizAnswer],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizAnswerRefs)
                    await $_getPrefetchedDataByColumns<
                      QuizAttemptData,
                      QuizAttempt,
                      QuizAnswerData,
                      QuizAnswer
                    >(
                      currentTable: table,
                      referencedTable: $QuizAttemptReferences
                          ._quizAnswerRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $QuizAttemptReferences(db, table, p0).quizAnswerRefs,
                      currentColumn: 'id',
                      referencedColumn: 'attempt_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $QuizAttemptProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      QuizAttempt,
      QuizAttemptData,
      $QuizAttemptFilterComposer,
      $QuizAttemptOrderingComposer,
      $QuizAttemptAnnotationComposer,
      $QuizAttemptCreateCompanionBuilder,
      $QuizAttemptUpdateCompanionBuilder,
      (QuizAttemptData, $QuizAttemptReferences),
      QuizAttemptData,
      PrefetchHooks Function({bool quizAnswerRefs})
    >;
typedef $QuizAnswerCreateCompanionBuilder = QuizAnswerCompanion Function({
  required int attemptId,
  required String questionId,
  required String answer,
  required int correct,
  required String answeredAt,
  Value<int> flagged,
  Value<int> rowid,
});
typedef $QuizAnswerUpdateCompanionBuilder = QuizAnswerCompanion Function({
  Value<int> attemptId,
  Value<String> questionId,
  Value<String> answer,
  Value<int> correct,
  Value<String> answeredAt,
  Value<int> flagged,
  Value<int> rowid,
});

final class $QuizAnswerReferences
    extends BaseReferences<_$AppDatabase, QuizAnswer, QuizAnswerData> {
  $QuizAnswerReferences(super.$_db, super.$_table, super.$_typedResult);

  static QuizAttempt _attemptIdTable(_$AppDatabase db) =>
      db.quizAttempt.createAlias('quiz_answer__attempt_id__quiz_attempt__id');

  $QuizAttemptProcessedTableManager get attemptId {
    final $_column = $_itemColumn<int>('attempt_id')!;

    final manager = $QuizAttemptTableManager(
      $_db,
      $_db.quizAttempt,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attemptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $QuizAnswerFilterComposer extends Composer<_$AppDatabase, QuizAnswer> {
  $QuizAnswerFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnFilters(column),
  );

  $QuizAttemptFilterComposer get attemptId {
    final $QuizAttemptFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.quizAttempt,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $QuizAttemptFilterComposer(
            $db: $db,
            $table: $db.quizAttempt,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $QuizAnswerOrderingComposer extends Composer<_$AppDatabase, QuizAnswer> {
  $QuizAnswerOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flagged => $composableBuilder(
    column: $table.flagged,
    builder: (column) => ColumnOrderings(column),
  );

  $QuizAttemptOrderingComposer get attemptId {
    final $QuizAttemptOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.quizAttempt,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $QuizAttemptOrderingComposer(
            $db: $db,
            $table: $db.quizAttempt,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $QuizAnswerAnnotationComposer
    extends Composer<_$AppDatabase, QuizAnswer> {
  $QuizAnswerAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<String> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get flagged =>
      $composableBuilder(column: $table.flagged, builder: (column) => column);

  $QuizAttemptAnnotationComposer get attemptId {
    final $QuizAttemptAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.attemptId,
      referencedTable: $db.quizAttempt,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $QuizAttemptAnnotationComposer(
            $db: $db,
            $table: $db.quizAttempt,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $QuizAnswerTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          QuizAnswer,
          QuizAnswerData,
          $QuizAnswerFilterComposer,
          $QuizAnswerOrderingComposer,
          $QuizAnswerAnnotationComposer,
          $QuizAnswerCreateCompanionBuilder,
          $QuizAnswerUpdateCompanionBuilder,
          (QuizAnswerData, $QuizAnswerReferences),
          QuizAnswerData,
          PrefetchHooks Function({bool attemptId})
        > {
  $QuizAnswerTableManager(_$AppDatabase db, QuizAnswer table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $QuizAnswerFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $QuizAnswerOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $QuizAnswerAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> attemptId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<String> answeredAt = const Value.absent(),
                Value<int> flagged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizAnswerCompanion(
                attemptId: attemptId,
                questionId: questionId,
                answer: answer,
                correct: correct,
                answeredAt: answeredAt,
                flagged: flagged,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int attemptId,
                required String questionId,
                required String answer,
                required int correct,
                required String answeredAt,
                Value<int> flagged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizAnswerCompanion.insert(
                attemptId: attemptId,
                questionId: questionId,
                answer: answer,
                correct: correct,
                answeredAt: answeredAt,
                flagged: flagged,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<QuizAnswer, QuizAnswerData>(table),
                  $QuizAnswerReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({attemptId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (attemptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.attemptId,
                        referencedTable: $QuizAnswerReferences._attemptIdTable(
                          db,
                        ),
                        referencedColumn: $QuizAnswerReferences
                            ._attemptIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $QuizAnswerProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      QuizAnswer,
      QuizAnswerData,
      $QuizAnswerFilterComposer,
      $QuizAnswerOrderingComposer,
      $QuizAnswerAnnotationComposer,
      $QuizAnswerCreateCompanionBuilder,
      $QuizAnswerUpdateCompanionBuilder,
      (QuizAnswerData, $QuizAnswerReferences),
      QuizAnswerData,
      PrefetchHooks Function({bool attemptId})
    >;
typedef $ReviewItemCreateCompanionBuilder = ReviewItemCompanion Function({
  Value<String?> itemId,
  required String kind,
  Value<String?> sourceLesson,
  Value<int> tier,
  required String dueAt,
  Value<int?> lastResult,
  Value<int> timesSeen,
  Value<int> retired,
  Value<int> rowid,
});
typedef $ReviewItemUpdateCompanionBuilder = ReviewItemCompanion Function({
  Value<String?> itemId,
  Value<String> kind,
  Value<String?> sourceLesson,
  Value<int> tier,
  Value<String> dueAt,
  Value<int?> lastResult,
  Value<int> timesSeen,
  Value<int> retired,
  Value<int> rowid,
});

class $ReviewItemFilterComposer extends Composer<_$AppDatabase, ReviewItem> {
  $ReviewItemFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLesson => $composableBuilder(
    column: $table.sourceLesson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesSeen => $composableBuilder(
    column: $table.timesSeen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnFilters(column),
  );
}

class $ReviewItemOrderingComposer extends Composer<_$AppDatabase, ReviewItem> {
  $ReviewItemOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLesson => $composableBuilder(
    column: $table.sourceLesson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesSeen => $composableBuilder(
    column: $table.timesSeen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ReviewItemAnnotationComposer
    extends Composer<_$AppDatabase, ReviewItem> {
  $ReviewItemAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sourceLesson => $composableBuilder(
    column: $table.sourceLesson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<String> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get lastResult => $composableBuilder(
    column: $table.lastResult,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesSeen =>
      $composableBuilder(column: $table.timesSeen, builder: (column) => column);

  GeneratedColumn<int> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => column);
}

class $ReviewItemTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ReviewItem,
          ReviewItemData,
          $ReviewItemFilterComposer,
          $ReviewItemOrderingComposer,
          $ReviewItemAnnotationComposer,
          $ReviewItemCreateCompanionBuilder,
          $ReviewItemUpdateCompanionBuilder,
          (
            ReviewItemData,
            BaseReferences<_$AppDatabase, ReviewItem, ReviewItemData>,
          ),
          ReviewItemData,
          PrefetchHooks Function()
        > {
  $ReviewItemTableManager(_$AppDatabase db, ReviewItem table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ReviewItemFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ReviewItemOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ReviewItemAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> itemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> sourceLesson = const Value.absent(),
                Value<int> tier = const Value.absent(),
                Value<String> dueAt = const Value.absent(),
                Value<int?> lastResult = const Value.absent(),
                Value<int> timesSeen = const Value.absent(),
                Value<int> retired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewItemCompanion(
                itemId: itemId,
                kind: kind,
                sourceLesson: sourceLesson,
                tier: tier,
                dueAt: dueAt,
                lastResult: lastResult,
                timesSeen: timesSeen,
                retired: retired,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> itemId = const Value.absent(),
                required String kind,
                Value<String?> sourceLesson = const Value.absent(),
                Value<int> tier = const Value.absent(),
                required String dueAt,
                Value<int?> lastResult = const Value.absent(),
                Value<int> timesSeen = const Value.absent(),
                Value<int> retired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewItemCompanion.insert(
                itemId: itemId,
                kind: kind,
                sourceLesson: sourceLesson,
                tier: tier,
                dueAt: dueAt,
                lastResult: lastResult,
                timesSeen: timesSeen,
                retired: retired,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ReviewItem, ReviewItemData>(table),
                  BaseReferences<_$AppDatabase, ReviewItem, ReviewItemData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ReviewItemProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ReviewItem,
      ReviewItemData,
      $ReviewItemFilterComposer,
      $ReviewItemOrderingComposer,
      $ReviewItemAnnotationComposer,
      $ReviewItemCreateCompanionBuilder,
      $ReviewItemUpdateCompanionBuilder,
      (
        ReviewItemData,
        BaseReferences<_$AppDatabase, ReviewItem, ReviewItemData>,
      ),
      ReviewItemData,
      PrefetchHooks Function()
    >;
typedef $VocabSeenCreateCompanionBuilder = VocabSeenCompanion Function({
  Value<String?> term,
  required String firstLessonId,
  required String seenAt,
  Value<int> rowid,
});
typedef $VocabSeenUpdateCompanionBuilder = VocabSeenCompanion Function({
  Value<String?> term,
  Value<String> firstLessonId,
  Value<String> seenAt,
  Value<int> rowid,
});

class $VocabSeenFilterComposer extends Composer<_$AppDatabase, VocabSeen> {
  $VocabSeenFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstLessonId => $composableBuilder(
    column: $table.firstLessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $VocabSeenOrderingComposer extends Composer<_$AppDatabase, VocabSeen> {
  $VocabSeenOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstLessonId => $composableBuilder(
    column: $table.firstLessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seenAt => $composableBuilder(
    column: $table.seenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $VocabSeenAnnotationComposer extends Composer<_$AppDatabase, VocabSeen> {
  $VocabSeenAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get firstLessonId => $composableBuilder(
    column: $table.firstLessonId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seenAt =>
      $composableBuilder(column: $table.seenAt, builder: (column) => column);
}

class $VocabSeenTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          VocabSeen,
          VocabSeenData,
          $VocabSeenFilterComposer,
          $VocabSeenOrderingComposer,
          $VocabSeenAnnotationComposer,
          $VocabSeenCreateCompanionBuilder,
          $VocabSeenUpdateCompanionBuilder,
          (
            VocabSeenData,
            BaseReferences<_$AppDatabase, VocabSeen, VocabSeenData>,
          ),
          VocabSeenData,
          PrefetchHooks Function()
        > {
  $VocabSeenTableManager(_$AppDatabase db, VocabSeen table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $VocabSeenFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $VocabSeenOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $VocabSeenAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> term = const Value.absent(),
                Value<String> firstLessonId = const Value.absent(),
                Value<String> seenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabSeenCompanion(
                term: term,
                firstLessonId: firstLessonId,
                seenAt: seenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> term = const Value.absent(),
                required String firstLessonId,
                required String seenAt,
                Value<int> rowid = const Value.absent(),
              }) => VocabSeenCompanion.insert(
                term: term,
                firstLessonId: firstLessonId,
                seenAt: seenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<VocabSeen, VocabSeenData>(table),
                  BaseReferences<_$AppDatabase, VocabSeen, VocabSeenData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $VocabSeenProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      VocabSeen,
      VocabSeenData,
      $VocabSeenFilterComposer,
      $VocabSeenOrderingComposer,
      $VocabSeenAnnotationComposer,
      $VocabSeenCreateCompanionBuilder,
      $VocabSeenUpdateCompanionBuilder,
      (VocabSeenData, BaseReferences<_$AppDatabase, VocabSeen, VocabSeenData>),
      VocabSeenData,
      PrefetchHooks Function()
    >;
typedef $StageProgressCreateCompanionBuilder = StageProgressCompanion Function({
  Value<int> stage,
  Value<String?> gatePassedAt,
  Value<double?> bestGateScore,
  Value<int> attempts,
});
typedef $StageProgressUpdateCompanionBuilder = StageProgressCompanion Function({
  Value<int> stage,
  Value<String?> gatePassedAt,
  Value<double?> bestGateScore,
  Value<int> attempts,
});

class $StageProgressFilterComposer
    extends Composer<_$AppDatabase, StageProgress> {
  $StageProgressFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gatePassedAt => $composableBuilder(
    column: $table.gatePassedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestGateScore => $composableBuilder(
    column: $table.bestGateScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $StageProgressOrderingComposer
    extends Composer<_$AppDatabase, StageProgress> {
  $StageProgressOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gatePassedAt => $composableBuilder(
    column: $table.gatePassedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestGateScore => $composableBuilder(
    column: $table.bestGateScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $StageProgressAnnotationComposer
    extends Composer<_$AppDatabase, StageProgress> {
  $StageProgressAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get gatePassedAt => $composableBuilder(
    column: $table.gatePassedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bestGateScore => $composableBuilder(
    column: $table.bestGateScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $StageProgressTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StageProgress,
          StageProgressData,
          $StageProgressFilterComposer,
          $StageProgressOrderingComposer,
          $StageProgressAnnotationComposer,
          $StageProgressCreateCompanionBuilder,
          $StageProgressUpdateCompanionBuilder,
          (
            StageProgressData,
            BaseReferences<_$AppDatabase, StageProgress, StageProgressData>,
          ),
          StageProgressData,
          PrefetchHooks Function()
        > {
  $StageProgressTableManager(_$AppDatabase db, StageProgress table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StageProgressFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StageProgressOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StageProgressAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> stage = const Value.absent(),
                Value<String?> gatePassedAt = const Value.absent(),
                Value<double?> bestGateScore = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => StageProgressCompanion(
                stage: stage,
                gatePassedAt: gatePassedAt,
                bestGateScore: bestGateScore,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> stage = const Value.absent(),
                Value<String?> gatePassedAt = const Value.absent(),
                Value<double?> bestGateScore = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => StageProgressCompanion.insert(
                stage: stage,
                gatePassedAt: gatePassedAt,
                bestGateScore: bestGateScore,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<StageProgress, StageProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    StageProgress,
                    StageProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $StageProgressProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StageProgress,
      StageProgressData,
      $StageProgressFilterComposer,
      $StageProgressOrderingComposer,
      $StageProgressAnnotationComposer,
      $StageProgressCreateCompanionBuilder,
      $StageProgressUpdateCompanionBuilder,
      (
        StageProgressData,
        BaseReferences<_$AppDatabase, StageProgress, StageProgressData>,
      ),
      StageProgressData,
      PrefetchHooks Function()
    >;
typedef $SettingsCreateCompanionBuilder = SettingsCompanion Function({
  Value<String?> key,
  required String value,
  Value<int> rowid,
});
typedef $SettingsUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String?> key,
  Value<String> value,
  Value<int> rowid,
});

class $SettingsFilterComposer extends Composer<_$AppDatabase, Settings> {
  $SettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $SettingsOrderingComposer extends Composer<_$AppDatabase, Settings> {
  $SettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SettingsAnnotationComposer extends Composer<_$AppDatabase, Settings> {
  $SettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $SettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Settings,
          Setting,
          $SettingsFilterComposer,
          $SettingsOrderingComposer,
          $SettingsAnnotationComposer,
          $SettingsCreateCompanionBuilder,
          $SettingsUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, Settings, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $SettingsTableManager(_$AppDatabase db, Settings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            Value<String?> key = const Value.absent(),
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Settings, Setting>(table),
                  BaseReferences<_$AppDatabase, Settings, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Settings,
      Setting,
      $SettingsFilterComposer,
      $SettingsOrderingComposer,
      $SettingsAnnotationComposer,
      $SettingsCreateCompanionBuilder,
      $SettingsUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, Settings, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $EventCreateCompanionBuilder = EventCompanion Function({
  Value<int> id,
  required String ts,
  required String kind,
  Value<String?> ref,
  Value<double?> value,
});
typedef $EventUpdateCompanionBuilder = EventCompanion Function({
  Value<int> id,
  Value<String> ts,
  Value<String> kind,
  Value<String?> ref,
  Value<double?> value,
});

class $EventFilterComposer extends Composer<_$AppDatabase, Event> {
  $EventFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $EventOrderingComposer extends Composer<_$AppDatabase, Event> {
  $EventOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $EventAnnotationComposer extends Composer<_$AppDatabase, Event> {
  $EventAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $EventTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Event,
          EventData,
          $EventFilterComposer,
          $EventOrderingComposer,
          $EventAnnotationComposer,
          $EventCreateCompanionBuilder,
          $EventUpdateCompanionBuilder,
          (EventData, BaseReferences<_$AppDatabase, Event, EventData>),
          EventData,
          PrefetchHooks Function()
        > {
  $EventTableManager(_$AppDatabase db, Event table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EventFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EventOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EventAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> ts = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> ref = const Value.absent(),
                Value<double?> value = const Value.absent(),
              }) => EventCompanion(
                id: id,
                ts: ts,
                kind: kind,
                ref: ref,
                value: value,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String ts,
                required String kind,
                Value<String?> ref = const Value.absent(),
                Value<double?> value = const Value.absent(),
              }) => EventCompanion.insert(
                id: id,
                ts: ts,
                kind: kind,
                ref: ref,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Event, EventData>(table),
                  BaseReferences<_$AppDatabase, Event, EventData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EventProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Event,
      EventData,
      $EventFilterComposer,
      $EventOrderingComposer,
      $EventAnnotationComposer,
      $EventCreateCompanionBuilder,
      $EventUpdateCompanionBuilder,
      (EventData, BaseReferences<_$AppDatabase, Event, EventData>),
      EventData,
      PrefetchHooks Function()
    >;
typedef $SearchIndexCreateCompanionBuilder = SearchIndexCompanion Function({
  required String lessonId,
  required String lang,
  required String title,
  required String body,
  Value<int> rowid,
});
typedef $SearchIndexUpdateCompanionBuilder = SearchIndexCompanion Function({
  Value<String> lessonId,
  Value<String> lang,
  Value<String> title,
  Value<String> body,
  Value<int> rowid,
});

class $SearchIndexFilterComposer extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $SearchIndexOrderingComposer
    extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SearchIndexAnnotationComposer
    extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $SearchIndexTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SearchIndex,
          SearchIndexData,
          $SearchIndexFilterComposer,
          $SearchIndexOrderingComposer,
          $SearchIndexAnnotationComposer,
          $SearchIndexCreateCompanionBuilder,
          $SearchIndexUpdateCompanionBuilder,
          (
            SearchIndexData,
            BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>,
          ),
          SearchIndexData,
          PrefetchHooks Function()
        > {
  $SearchIndexTableManager(_$AppDatabase db, SearchIndex table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SearchIndexFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SearchIndexOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SearchIndexAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchIndexCompanion(
                lessonId: lessonId,
                lang: lang,
                title: title,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required String lang,
                required String title,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => SearchIndexCompanion.insert(
                lessonId: lessonId,
                lang: lang,
                title: title,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SearchIndex, SearchIndexData>(table),
                  BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SearchIndexProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SearchIndex,
      SearchIndexData,
      $SearchIndexFilterComposer,
      $SearchIndexOrderingComposer,
      $SearchIndexAnnotationComposer,
      $SearchIndexCreateCompanionBuilder,
      $SearchIndexUpdateCompanionBuilder,
      (
        SearchIndexData,
        BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>,
      ),
      SearchIndexData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $LessonProgressTableManager get lessonProgress =>
      $LessonProgressTableManager(_db, _db.lessonProgress);
  $QuizAttemptTableManager get quizAttempt =>
      $QuizAttemptTableManager(_db, _db.quizAttempt);
  $QuizAnswerTableManager get quizAnswer =>
      $QuizAnswerTableManager(_db, _db.quizAnswer);
  $ReviewItemTableManager get reviewItem =>
      $ReviewItemTableManager(_db, _db.reviewItem);
  $VocabSeenTableManager get vocabSeen =>
      $VocabSeenTableManager(_db, _db.vocabSeen);
  $StageProgressTableManager get stageProgress =>
      $StageProgressTableManager(_db, _db.stageProgress);
  $SettingsTableManager get settings =>
      $SettingsTableManager(_db, _db.settings);
  $EventTableManager get event => $EventTableManager(_db, _db.event);
  $SearchIndexTableManager get searchIndex =>
      $SearchIndexTableManager(_db, _db.searchIndex);
}
