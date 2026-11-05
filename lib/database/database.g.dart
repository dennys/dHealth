// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DailyStepsTable extends DailySteps
    with TableInfo<$DailyStepsTable, DailyStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepCountMeta = const VerificationMeta(
    'stepCount',
  );
  @override
  late final GeneratedColumn<int> stepCount = GeneratedColumn<int>(
    'step_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompleteMeta = const VerificationMeta(
    'isComplete',
  );
  @override
  late final GeneratedColumn<bool> isComplete = GeneratedColumn<bool>(
    'is_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    stepCount,
    lastUpdated,
    isComplete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('step_count')) {
      context.handle(
        _stepCountMeta,
        stepCount.isAcceptableOrUnknown(data['step_count']!, _stepCountMeta),
      );
    } else if (isInserting) {
      context.missing(_stepCountMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    if (data.containsKey('is_complete')) {
      context.handle(
        _isCompleteMeta,
        isComplete.isAcceptableOrUnknown(data['is_complete']!, _isCompleteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStep(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      stepCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_count'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
      isComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_complete'],
      )!,
    );
  }

  @override
  $DailyStepsTable createAlias(String alias) {
    return $DailyStepsTable(attachedDatabase, alias);
  }
}

class DailyStep extends DataClass implements Insertable<DailyStep> {
  final String date;
  final int stepCount;
  final DateTime lastUpdated;
  final bool isComplete;
  const DailyStep({
    required this.date,
    required this.stepCount,
    required this.lastUpdated,
    required this.isComplete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['step_count'] = Variable<int>(stepCount);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    map['is_complete'] = Variable<bool>(isComplete);
    return map;
  }

  DailyStepsCompanion toCompanion(bool nullToAbsent) {
    return DailyStepsCompanion(
      date: Value(date),
      stepCount: Value(stepCount),
      lastUpdated: Value(lastUpdated),
      isComplete: Value(isComplete),
    );
  }

  factory DailyStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStep(
      date: serializer.fromJson<String>(json['date']),
      stepCount: serializer.fromJson<int>(json['stepCount']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
      isComplete: serializer.fromJson<bool>(json['isComplete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'stepCount': serializer.toJson<int>(stepCount),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
      'isComplete': serializer.toJson<bool>(isComplete),
    };
  }

  DailyStep copyWith({
    String? date,
    int? stepCount,
    DateTime? lastUpdated,
    bool? isComplete,
  }) => DailyStep(
    date: date ?? this.date,
    stepCount: stepCount ?? this.stepCount,
    lastUpdated: lastUpdated ?? this.lastUpdated,
    isComplete: isComplete ?? this.isComplete,
  );
  DailyStep copyWithCompanion(DailyStepsCompanion data) {
    return DailyStep(
      date: data.date.present ? data.date.value : this.date,
      stepCount: data.stepCount.present ? data.stepCount.value : this.stepCount,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
      isComplete: data.isComplete.present
          ? data.isComplete.value
          : this.isComplete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStep(')
          ..write('date: $date, ')
          ..write('stepCount: $stepCount, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isComplete: $isComplete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, stepCount, lastUpdated, isComplete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStep &&
          other.date == this.date &&
          other.stepCount == this.stepCount &&
          other.lastUpdated == this.lastUpdated &&
          other.isComplete == this.isComplete);
}

class DailyStepsCompanion extends UpdateCompanion<DailyStep> {
  final Value<String> date;
  final Value<int> stepCount;
  final Value<DateTime> lastUpdated;
  final Value<bool> isComplete;
  final Value<int> rowid;
  const DailyStepsCompanion({
    this.date = const Value.absent(),
    this.stepCount = const Value.absent(),
    this.lastUpdated = const Value.absent(),
    this.isComplete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStepsCompanion.insert({
    required String date,
    required int stepCount,
    required DateTime lastUpdated,
    this.isComplete = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       stepCount = Value(stepCount),
       lastUpdated = Value(lastUpdated);
  static Insertable<DailyStep> custom({
    Expression<String>? date,
    Expression<int>? stepCount,
    Expression<DateTime>? lastUpdated,
    Expression<bool>? isComplete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (stepCount != null) 'step_count': stepCount,
      if (lastUpdated != null) 'last_updated': lastUpdated,
      if (isComplete != null) 'is_complete': isComplete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStepsCompanion copyWith({
    Value<String>? date,
    Value<int>? stepCount,
    Value<DateTime>? lastUpdated,
    Value<bool>? isComplete,
    Value<int>? rowid,
  }) {
    return DailyStepsCompanion(
      date: date ?? this.date,
      stepCount: stepCount ?? this.stepCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isComplete: isComplete ?? this.isComplete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (stepCount.present) {
      map['step_count'] = Variable<int>(stepCount.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    if (isComplete.present) {
      map['is_complete'] = Variable<bool>(isComplete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStepsCompanion(')
          ..write('date: $date, ')
          ..write('stepCount: $stepCount, ')
          ..write('lastUpdated: $lastUpdated, ')
          ..write('isComplete: $isComplete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StepDatabase extends GeneratedDatabase {
  _$StepDatabase(QueryExecutor e) : super(e);
  $StepDatabaseManager get managers => $StepDatabaseManager(this);
  late final $DailyStepsTable dailySteps = $DailyStepsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [dailySteps];
}

typedef $$DailyStepsTableCreateCompanionBuilder = DailyStepsCompanion Function({
  required String date,
  required int stepCount,
  required DateTime lastUpdated,
  Value<bool> isComplete,
  Value<int> rowid,
});
typedef $$DailyStepsTableUpdateCompanionBuilder = DailyStepsCompanion Function({
  Value<String> date,
  Value<int> stepCount,
  Value<DateTime> lastUpdated,
  Value<bool> isComplete,
  Value<int> rowid,
});

class $$DailyStepsTableFilterComposer
    extends Composer<_$StepDatabase, $DailyStepsTable> {
  $$DailyStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepCount => $composableBuilder(
    column: $table.stepCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStepsTableOrderingComposer
    extends Composer<_$StepDatabase, $DailyStepsTable> {
  $$DailyStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepCount => $composableBuilder(
    column: $table.stepCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStepsTableAnnotationComposer
    extends Composer<_$StepDatabase, $DailyStepsTable> {
  $$DailyStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get stepCount =>
      $composableBuilder(column: $table.stepCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isComplete => $composableBuilder(
    column: $table.isComplete,
    builder: (column) => column,
  );
}

class $$DailyStepsTableTableManager
    extends
        RootTableManager<
          _$StepDatabase,
          $DailyStepsTable,
          DailyStep,
          $$DailyStepsTableFilterComposer,
          $$DailyStepsTableOrderingComposer,
          $$DailyStepsTableAnnotationComposer,
          $$DailyStepsTableCreateCompanionBuilder,
          $$DailyStepsTableUpdateCompanionBuilder,
          (
            DailyStep,
            BaseReferences<_$StepDatabase, $DailyStepsTable, DailyStep>,
          ),
          DailyStep,
          PrefetchHooks Function()
        > {
  $$DailyStepsTableTableManager(_$StepDatabase db, $DailyStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<int> stepCount = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
                Value<bool> isComplete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStepsCompanion(
                date: date,
                stepCount: stepCount,
                lastUpdated: lastUpdated,
                isComplete: isComplete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required int stepCount,
                required DateTime lastUpdated,
                Value<bool> isComplete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStepsCompanion.insert(
                date: date,
                stepCount: stepCount,
                lastUpdated: lastUpdated,
                isComplete: isComplete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyStepsTable, DailyStep>(table),
                  BaseReferences<_$StepDatabase, $DailyStepsTable, DailyStep>(
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

typedef $$DailyStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$StepDatabase,
      $DailyStepsTable,
      DailyStep,
      $$DailyStepsTableFilterComposer,
      $$DailyStepsTableOrderingComposer,
      $$DailyStepsTableAnnotationComposer,
      $$DailyStepsTableCreateCompanionBuilder,
      $$DailyStepsTableUpdateCompanionBuilder,
      (DailyStep, BaseReferences<_$StepDatabase, $DailyStepsTable, DailyStep>),
      DailyStep,
      PrefetchHooks Function()
    >;

class $StepDatabaseManager {
  final _$StepDatabase _db;
  $StepDatabaseManager(this._db);
  $$DailyStepsTableTableManager get dailySteps =>
      $$DailyStepsTableTableManager(_db, _db.dailySteps);
}
