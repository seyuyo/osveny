// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, TrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrackStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrackStatus>($TracksTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<TrackProfile, String> profile =
      GeneratedColumn<String>(
        'profile',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TrackProfile>($TracksTable.$converterprofile);
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  @override
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plannedRouteIdMeta = const VerificationMeta(
    'plannedRouteId',
  );
  @override
  late final GeneratedColumn<int> plannedRouteId = GeneratedColumn<int>(
    'planned_route_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statsJsonMeta = const VerificationMeta(
    'statsJson',
  );
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
    'stats_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    status,
    profile,
    startedAtMs,
    endedAtMs,
    plannedRouteId,
    statsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    if (data.containsKey('planned_route_id')) {
      context.handle(
        _plannedRouteIdMeta,
        plannedRouteId.isAcceptableOrUnknown(
          data['planned_route_id']!,
          _plannedRouteIdMeta,
        ),
      );
    }
    if (data.containsKey('stats_json')) {
      context.handle(
        _statsJsonMeta,
        statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: $TracksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      profile: $TracksTable.$converterprofile.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}profile'],
        )!,
      ),
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
      plannedRouteId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_route_id'],
      ),
      statsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stats_json'],
      ),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrackStatus, String, String> $converterstatus =
      const EnumNameConverter<TrackStatus>(TrackStatus.values);
  static JsonTypeConverter2<TrackProfile, String, String> $converterprofile =
      const EnumNameConverter<TrackProfile>(TrackProfile.values);
}

class TrackRow extends DataClass implements Insertable<TrackRow> {
  final int id;
  final String name;
  final TrackStatus status;
  final TrackProfile profile;
  final int startedAtMs;
  final int? endedAtMs;
  final int? plannedRouteId;

  /// Csak gyorsítótár: lezáráskor számolva, a nyers fixekből bármikor
  /// újraszámolható.
  final String? statsJson;
  const TrackRow({
    required this.id,
    required this.name,
    required this.status,
    required this.profile,
    required this.startedAtMs,
    this.endedAtMs,
    this.plannedRouteId,
    this.statsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['status'] = Variable<String>(
        $TracksTable.$converterstatus.toSql(status),
      );
    }
    {
      map['profile'] = Variable<String>(
        $TracksTable.$converterprofile.toSql(profile),
      );
    }
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    if (!nullToAbsent || plannedRouteId != null) {
      map['planned_route_id'] = Variable<int>(plannedRouteId);
    }
    if (!nullToAbsent || statsJson != null) {
      map['stats_json'] = Variable<String>(statsJson);
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      name: Value(name),
      status: Value(status),
      profile: Value(profile),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
      plannedRouteId: plannedRouteId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedRouteId),
      statsJson: statsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statsJson),
    );
  }

  factory TrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      status: $TracksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      profile: $TracksTable.$converterprofile.fromJson(
        serializer.fromJson<String>(json['profile']),
      ),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      endedAtMs: serializer.fromJson<int?>(json['endedAtMs']),
      plannedRouteId: serializer.fromJson<int?>(json['plannedRouteId']),
      statsJson: serializer.fromJson<String?>(json['statsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(
        $TracksTable.$converterstatus.toJson(status),
      ),
      'profile': serializer.toJson<String>(
        $TracksTable.$converterprofile.toJson(profile),
      ),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'endedAtMs': serializer.toJson<int?>(endedAtMs),
      'plannedRouteId': serializer.toJson<int?>(plannedRouteId),
      'statsJson': serializer.toJson<String?>(statsJson),
    };
  }

  TrackRow copyWith({
    int? id,
    String? name,
    TrackStatus? status,
    TrackProfile? profile,
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
    Value<int?> plannedRouteId = const Value.absent(),
    Value<String?> statsJson = const Value.absent(),
  }) => TrackRow(
    id: id ?? this.id,
    name: name ?? this.name,
    status: status ?? this.status,
    profile: profile ?? this.profile,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
    plannedRouteId: plannedRouteId.present
        ? plannedRouteId.value
        : this.plannedRouteId,
    statsJson: statsJson.present ? statsJson.value : this.statsJson,
  );
  TrackRow copyWithCompanion(TracksCompanion data) {
    return TrackRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      profile: data.profile.present ? data.profile.value : this.profile,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
      plannedRouteId: data.plannedRouteId.present
          ? data.plannedRouteId.value
          : this.plannedRouteId,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('profile: $profile, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('plannedRouteId: $plannedRouteId, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    status,
    profile,
    startedAtMs,
    endedAtMs,
    plannedRouteId,
    statsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.status == this.status &&
          other.profile == this.profile &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs &&
          other.plannedRouteId == this.plannedRouteId &&
          other.statsJson == this.statsJson);
}

class TracksCompanion extends UpdateCompanion<TrackRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<TrackStatus> status;
  final Value<TrackProfile> profile;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<int?> plannedRouteId;
  final Value<String?> statsJson;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.profile = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.plannedRouteId = const Value.absent(),
    this.statsJson = const Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required TrackStatus status,
    required TrackProfile profile,
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
    this.plannedRouteId = const Value.absent(),
    this.statsJson = const Value.absent(),
  }) : name = Value(name),
       status = Value(status),
       profile = Value(profile),
       startedAtMs = Value(startedAtMs);
  static Insertable<TrackRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? status,
    Expression<String>? profile,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<int>? plannedRouteId,
    Expression<String>? statsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (profile != null) 'profile': profile,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (plannedRouteId != null) 'planned_route_id': plannedRouteId,
      if (statsJson != null) 'stats_json': statsJson,
    });
  }

  TracksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<TrackStatus>? status,
    Value<TrackProfile>? profile,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<int?>? plannedRouteId,
    Value<String?>? statsJson,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      profile: profile ?? this.profile,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      plannedRouteId: plannedRouteId ?? this.plannedRouteId,
      statsJson: statsJson ?? this.statsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TracksTable.$converterstatus.toSql(status.value),
      );
    }
    if (profile.present) {
      map['profile'] = Variable<String>(
        $TracksTable.$converterprofile.toSql(profile.value),
      );
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (plannedRouteId.present) {
      map['planned_route_id'] = Variable<int>(plannedRouteId.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('profile: $profile, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('plannedRouteId: $plannedRouteId, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }
}

class $FixesTable extends Fixes with TableInfo<$FixesTable, FixRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FixesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id)',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altMeta = const VerificationMeta('alt');
  @override
  late final GeneratedColumn<double> alt = GeneratedColumn<double>(
    'alt',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hAccMeta = const VerificationMeta('hAcc');
  @override
  late final GeneratedColumn<double> hAcc = GeneratedColumn<double>(
    'h_acc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vAccMeta = const VerificationMeta('vAcc');
  @override
  late final GeneratedColumn<double> vAcc = GeneratedColumn<double>(
    'v_acc',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bearingMeta = const VerificationMeta(
    'bearing',
  );
  @override
  late final GeneratedColumn<double> bearing = GeneratedColumn<double>(
    'bearing',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    tMs,
    lat,
    lon,
    alt,
    hAcc,
    vAcc,
    speed,
    bearing,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fixes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FixRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('alt')) {
      context.handle(
        _altMeta,
        alt.isAcceptableOrUnknown(data['alt']!, _altMeta),
      );
    }
    if (data.containsKey('h_acc')) {
      context.handle(
        _hAccMeta,
        hAcc.isAcceptableOrUnknown(data['h_acc']!, _hAccMeta),
      );
    } else if (isInserting) {
      context.missing(_hAccMeta);
    }
    if (data.containsKey('v_acc')) {
      context.handle(
        _vAccMeta,
        vAcc.isAcceptableOrUnknown(data['v_acc']!, _vAccMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('bearing')) {
      context.handle(
        _bearingMeta,
        bearing.isAcceptableOrUnknown(data['bearing']!, _bearingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FixRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FixRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      alt: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alt'],
      ),
      hAcc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}h_acc'],
      )!,
      vAcc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}v_acc'],
      ),
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      bearing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bearing'],
      ),
    );
  }

  @override
  $FixesTable createAlias(String alias) {
    return $FixesTable(attachedDatabase, alias);
  }
}

class FixRow extends DataClass implements Insertable<FixRow> {
  final int id;
  final int trackId;
  final int tMs;
  final double lat;
  final double lon;
  final double? alt;
  final double hAcc;
  final double? vAcc;
  final double? speed;
  final double? bearing;
  const FixRow({
    required this.id,
    required this.trackId,
    required this.tMs,
    required this.lat,
    required this.lon,
    this.alt,
    required this.hAcc,
    this.vAcc,
    this.speed,
    this.bearing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['t_ms'] = Variable<int>(tMs);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || alt != null) {
      map['alt'] = Variable<double>(alt);
    }
    map['h_acc'] = Variable<double>(hAcc);
    if (!nullToAbsent || vAcc != null) {
      map['v_acc'] = Variable<double>(vAcc);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || bearing != null) {
      map['bearing'] = Variable<double>(bearing);
    }
    return map;
  }

  FixesCompanion toCompanion(bool nullToAbsent) {
    return FixesCompanion(
      id: Value(id),
      trackId: Value(trackId),
      tMs: Value(tMs),
      lat: Value(lat),
      lon: Value(lon),
      alt: alt == null && nullToAbsent ? const Value.absent() : Value(alt),
      hAcc: Value(hAcc),
      vAcc: vAcc == null && nullToAbsent ? const Value.absent() : Value(vAcc),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      bearing: bearing == null && nullToAbsent
          ? const Value.absent()
          : Value(bearing),
    );
  }

  factory FixRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FixRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      alt: serializer.fromJson<double?>(json['alt']),
      hAcc: serializer.fromJson<double>(json['hAcc']),
      vAcc: serializer.fromJson<double?>(json['vAcc']),
      speed: serializer.fromJson<double?>(json['speed']),
      bearing: serializer.fromJson<double?>(json['bearing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'tMs': serializer.toJson<int>(tMs),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'alt': serializer.toJson<double?>(alt),
      'hAcc': serializer.toJson<double>(hAcc),
      'vAcc': serializer.toJson<double?>(vAcc),
      'speed': serializer.toJson<double?>(speed),
      'bearing': serializer.toJson<double?>(bearing),
    };
  }

  FixRow copyWith({
    int? id,
    int? trackId,
    int? tMs,
    double? lat,
    double? lon,
    Value<double?> alt = const Value.absent(),
    double? hAcc,
    Value<double?> vAcc = const Value.absent(),
    Value<double?> speed = const Value.absent(),
    Value<double?> bearing = const Value.absent(),
  }) => FixRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    tMs: tMs ?? this.tMs,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    alt: alt.present ? alt.value : this.alt,
    hAcc: hAcc ?? this.hAcc,
    vAcc: vAcc.present ? vAcc.value : this.vAcc,
    speed: speed.present ? speed.value : this.speed,
    bearing: bearing.present ? bearing.value : this.bearing,
  );
  FixRow copyWithCompanion(FixesCompanion data) {
    return FixRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      alt: data.alt.present ? data.alt.value : this.alt,
      hAcc: data.hAcc.present ? data.hAcc.value : this.hAcc,
      vAcc: data.vAcc.present ? data.vAcc.value : this.vAcc,
      speed: data.speed.present ? data.speed.value : this.speed,
      bearing: data.bearing.present ? data.bearing.value : this.bearing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FixRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('tMs: $tMs, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('alt: $alt, ')
          ..write('hAcc: $hAcc, ')
          ..write('vAcc: $vAcc, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, trackId, tMs, lat, lon, alt, hAcc, vAcc, speed, bearing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.tMs == this.tMs &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.alt == this.alt &&
          other.hAcc == this.hAcc &&
          other.vAcc == this.vAcc &&
          other.speed == this.speed &&
          other.bearing == this.bearing);
}

class FixesCompanion extends UpdateCompanion<FixRow> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<int> tMs;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> alt;
  final Value<double> hAcc;
  final Value<double?> vAcc;
  final Value<double?> speed;
  final Value<double?> bearing;
  const FixesCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.alt = const Value.absent(),
    this.hAcc = const Value.absent(),
    this.vAcc = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
  });
  FixesCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required int tMs,
    required double lat,
    required double lon,
    this.alt = const Value.absent(),
    required double hAcc,
    this.vAcc = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
  }) : trackId = Value(trackId),
       tMs = Value(tMs),
       lat = Value(lat),
       lon = Value(lon),
       hAcc = Value(hAcc);
  static Insertable<FixRow> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? tMs,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? alt,
    Expression<double>? hAcc,
    Expression<double>? vAcc,
    Expression<double>? speed,
    Expression<double>? bearing,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (tMs != null) 't_ms': tMs,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (alt != null) 'alt': alt,
      if (hAcc != null) 'h_acc': hAcc,
      if (vAcc != null) 'v_acc': vAcc,
      if (speed != null) 'speed': speed,
      if (bearing != null) 'bearing': bearing,
    });
  }

  FixesCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<int>? tMs,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? alt,
    Value<double>? hAcc,
    Value<double?>? vAcc,
    Value<double?>? speed,
    Value<double?>? bearing,
  }) {
    return FixesCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      tMs: tMs ?? this.tMs,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      alt: alt ?? this.alt,
      hAcc: hAcc ?? this.hAcc,
      vAcc: vAcc ?? this.vAcc,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (alt.present) {
      map['alt'] = Variable<double>(alt.value);
    }
    if (hAcc.present) {
      map['h_acc'] = Variable<double>(hAcc.value);
    }
    if (vAcc.present) {
      map['v_acc'] = Variable<double>(vAcc.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (bearing.present) {
      map['bearing'] = Variable<double>(bearing.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FixesCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('tMs: $tMs, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('alt: $alt, ')
          ..write('hAcc: $hAcc, ')
          ..write('vAcc: $vAcc, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments
    with TableInfo<$SegmentsTable, SegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<int> trackId = GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id)',
    ),
  );
  static const VerificationMeta _startTMsMeta = const VerificationMeta(
    'startTMs',
  );
  @override
  late final GeneratedColumn<int> startTMs = GeneratedColumn<int>(
    'start_t_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTMsMeta = const VerificationMeta('endTMs');
  @override
  late final GeneratedColumn<int> endTMs = GeneratedColumn<int>(
    'end_t_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trackId, startTMs, endTMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('start_t_ms')) {
      context.handle(
        _startTMsMeta,
        startTMs.isAcceptableOrUnknown(data['start_t_ms']!, _startTMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startTMsMeta);
    }
    if (data.containsKey('end_t_ms')) {
      context.handle(
        _endTMsMeta,
        endTMs.isAcceptableOrUnknown(data['end_t_ms']!, _endTMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SegmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      startTMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_t_ms'],
      )!,
      endTMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_t_ms'],
      ),
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class SegmentRow extends DataClass implements Insertable<SegmentRow> {
  final int id;
  final int trackId;
  final int startTMs;
  final int? endTMs;
  const SegmentRow({
    required this.id,
    required this.trackId,
    required this.startTMs,
    this.endTMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['track_id'] = Variable<int>(trackId);
    map['start_t_ms'] = Variable<int>(startTMs);
    if (!nullToAbsent || endTMs != null) {
      map['end_t_ms'] = Variable<int>(endTMs);
    }
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      startTMs: Value(startTMs),
      endTMs: endTMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endTMs),
    );
  }

  factory SegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SegmentRow(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      startTMs: serializer.fromJson<int>(json['startTMs']),
      endTMs: serializer.fromJson<int?>(json['endTMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'startTMs': serializer.toJson<int>(startTMs),
      'endTMs': serializer.toJson<int?>(endTMs),
    };
  }

  SegmentRow copyWith({
    int? id,
    int? trackId,
    int? startTMs,
    Value<int?> endTMs = const Value.absent(),
  }) => SegmentRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    startTMs: startTMs ?? this.startTMs,
    endTMs: endTMs.present ? endTMs.value : this.endTMs,
  );
  SegmentRow copyWithCompanion(SegmentsCompanion data) {
    return SegmentRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      startTMs: data.startTMs.present ? data.startTMs.value : this.startTMs,
      endTMs: data.endTMs.present ? data.endTMs.value : this.endTMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SegmentRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('startTMs: $startTMs, ')
          ..write('endTMs: $endTMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, startTMs, endTMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SegmentRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.startTMs == this.startTMs &&
          other.endTMs == this.endTMs);
}

class SegmentsCompanion extends UpdateCompanion<SegmentRow> {
  final Value<int> id;
  final Value<int> trackId;
  final Value<int> startTMs;
  final Value<int?> endTMs;
  const SegmentsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.startTMs = const Value.absent(),
    this.endTMs = const Value.absent(),
  });
  SegmentsCompanion.insert({
    this.id = const Value.absent(),
    required int trackId,
    required int startTMs,
    this.endTMs = const Value.absent(),
  }) : trackId = Value(trackId),
       startTMs = Value(startTMs);
  static Insertable<SegmentRow> custom({
    Expression<int>? id,
    Expression<int>? trackId,
    Expression<int>? startTMs,
    Expression<int>? endTMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (startTMs != null) 'start_t_ms': startTMs,
      if (endTMs != null) 'end_t_ms': endTMs,
    });
  }

  SegmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? trackId,
    Value<int>? startTMs,
    Value<int?>? endTMs,
  }) {
    return SegmentsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      startTMs: startTMs ?? this.startTMs,
      endTMs: endTMs ?? this.endTMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<int>(trackId.value);
    }
    if (startTMs.present) {
      map['start_t_ms'] = Variable<int>(startTMs.value);
    }
    if (endTMs.present) {
      map['end_t_ms'] = Variable<int>(endTMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('startTMs: $startTMs, ')
          ..write('endTMs: $endTMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $FixesTable fixes = $FixesTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final Index fixesTrackT = Index(
    'fixes_track_t',
    'CREATE INDEX fixes_track_t ON fixes (track_id, t_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    fixes,
    segments,
    fixesTrackT,
  ];
}

typedef $$TracksTableCreateCompanionBuilder =
    TracksCompanion Function({
      Value<int> id,
      required String name,
      required TrackStatus status,
      required TrackProfile profile,
      required int startedAtMs,
      Value<int?> endedAtMs,
      Value<int?> plannedRouteId,
      Value<String?> statsJson,
    });
typedef $$TracksTableUpdateCompanionBuilder =
    TracksCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<TrackStatus> status,
      Value<TrackProfile> profile,
      Value<int> startedAtMs,
      Value<int?> endedAtMs,
      Value<int?> plannedRouteId,
      Value<String?> statsJson,
    });

final class $$TracksTableReferences
    extends BaseReferences<_$AppDatabase, $TracksTable, TrackRow> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FixesTable, List<FixRow>> _fixesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.fixes,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.fixes.trackId),
  );

  $$FixesTableProcessedTableManager get fixesRefs {
    final manager = $$FixesTableTableManager(
      $_db,
      $_db.fixes,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fixesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SegmentsTable, List<SegmentRow>>
  _segmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.segments,
    aliasName: $_aliasNameGenerator(db.tracks.id, db.segments.trackId),
  );

  $$SegmentsTableProcessedTableManager get segmentsRefs {
    final manager = $$SegmentsTableTableManager(
      $_db,
      $_db.segments,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_segmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TrackStatus, TrackStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<TrackProfile, TrackProfile, String>
  get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedRouteId => $composableBuilder(
    column: $table.plannedRouteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> fixesRefs(
    Expression<bool> Function($$FixesTableFilterComposer f) f,
  ) {
    final $$FixesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fixes,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FixesTableFilterComposer(
            $db: $db,
            $table: $db.fixes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> segmentsRefs(
    Expression<bool> Function($$SegmentsTableFilterComposer f) f,
  ) {
    final $$SegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableFilterComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profile => $composableBuilder(
    column: $table.profile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedRouteId => $composableBuilder(
    column: $table.plannedRouteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statsJson => $composableBuilder(
    column: $table.statsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackProfile, String> get profile =>
      $composableBuilder(column: $table.profile, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);

  GeneratedColumn<int> get plannedRouteId => $composableBuilder(
    column: $table.plannedRouteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  Expression<T> fixesRefs<T extends Object>(
    Expression<T> Function($$FixesTableAnnotationComposer a) f,
  ) {
    final $$FixesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fixes,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FixesTableAnnotationComposer(
            $db: $db,
            $table: $db.fixes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> segmentsRefs<T extends Object>(
    Expression<T> Function($$SegmentsTableAnnotationComposer a) f,
  ) {
    final $$SegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.segments,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.segments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TracksTable,
          TrackRow,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (TrackRow, $$TracksTableReferences),
          TrackRow,
          PrefetchHooks Function({bool fixesRefs, bool segmentsRefs})
        > {
  $$TracksTableTableManager(_$AppDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<TrackStatus> status = const Value.absent(),
                Value<TrackProfile> profile = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<int?> plannedRouteId = const Value.absent(),
                Value<String?> statsJson = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                name: name,
                status: status,
                profile: profile,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                plannedRouteId: plannedRouteId,
                statsJson: statsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required TrackStatus status,
                required TrackProfile profile,
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
                Value<int?> plannedRouteId = const Value.absent(),
                Value<String?> statsJson = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                name: name,
                status: status,
                profile: profile,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                plannedRouteId: plannedRouteId,
                statsJson: statsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TracksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({fixesRefs = false, segmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (fixesRefs) db.fixes,
                if (segmentsRefs) db.segments,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (fixesRefs)
                    await $_getPrefetchedData<TrackRow, $TracksTable, FixRow>(
                      currentTable: table,
                      referencedTable: $$TracksTableReferences._fixesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TracksTableReferences(db, table, p0).fixesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.trackId == item.id),
                      typedResults: items,
                    ),
                  if (segmentsRefs)
                    await $_getPrefetchedData<
                      TrackRow,
                      $TracksTable,
                      SegmentRow
                    >(
                      currentTable: table,
                      referencedTable: $$TracksTableReferences
                          ._segmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TracksTableReferences(db, table, p0).segmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.trackId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TracksTable,
      TrackRow,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (TrackRow, $$TracksTableReferences),
      TrackRow,
      PrefetchHooks Function({bool fixesRefs, bool segmentsRefs})
    >;
typedef $$FixesTableCreateCompanionBuilder =
    FixesCompanion Function({
      Value<int> id,
      required int trackId,
      required int tMs,
      required double lat,
      required double lon,
      Value<double?> alt,
      required double hAcc,
      Value<double?> vAcc,
      Value<double?> speed,
      Value<double?> bearing,
    });
typedef $$FixesTableUpdateCompanionBuilder =
    FixesCompanion Function({
      Value<int> id,
      Value<int> trackId,
      Value<int> tMs,
      Value<double> lat,
      Value<double> lon,
      Value<double?> alt,
      Value<double> hAcc,
      Value<double?> vAcc,
      Value<double?> speed,
      Value<double?> bearing,
    });

final class $$FixesTableReferences
    extends BaseReferences<_$AppDatabase, $FixesTable, FixRow> {
  $$FixesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.fixes.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FixesTableFilterComposer extends Composer<_$AppDatabase, $FixesTable> {
  $$FixesTableFilterComposer({
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

  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hAcc => $composableBuilder(
    column: $table.hAcc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vAcc => $composableBuilder(
    column: $table.vAcc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bearing => $composableBuilder(
    column: $table.bearing,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixesTableOrderingComposer
    extends Composer<_$AppDatabase, $FixesTable> {
  $$FixesTableOrderingComposer({
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

  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hAcc => $composableBuilder(
    column: $table.hAcc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vAcc => $composableBuilder(
    column: $table.vAcc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bearing => $composableBuilder(
    column: $table.bearing,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FixesTable> {
  $$FixesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get alt =>
      $composableBuilder(column: $table.alt, builder: (column) => column);

  GeneratedColumn<double> get hAcc =>
      $composableBuilder(column: $table.hAcc, builder: (column) => column);

  GeneratedColumn<double> get vAcc =>
      $composableBuilder(column: $table.vAcc, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get bearing =>
      $composableBuilder(column: $table.bearing, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FixesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FixesTable,
          FixRow,
          $$FixesTableFilterComposer,
          $$FixesTableOrderingComposer,
          $$FixesTableAnnotationComposer,
          $$FixesTableCreateCompanionBuilder,
          $$FixesTableUpdateCompanionBuilder,
          (FixRow, $$FixesTableReferences),
          FixRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$FixesTableTableManager(_$AppDatabase db, $FixesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FixesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FixesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FixesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> alt = const Value.absent(),
                Value<double> hAcc = const Value.absent(),
                Value<double?> vAcc = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> bearing = const Value.absent(),
              }) => FixesCompanion(
                id: id,
                trackId: trackId,
                tMs: tMs,
                lat: lat,
                lon: lon,
                alt: alt,
                hAcc: hAcc,
                vAcc: vAcc,
                speed: speed,
                bearing: bearing,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required int tMs,
                required double lat,
                required double lon,
                Value<double?> alt = const Value.absent(),
                required double hAcc,
                Value<double?> vAcc = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> bearing = const Value.absent(),
              }) => FixesCompanion.insert(
                id: id,
                trackId: trackId,
                tMs: tMs,
                lat: lat,
                lon: lon,
                alt: alt,
                hAcc: hAcc,
                vAcc: vAcc,
                speed: speed,
                bearing: bearing,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$FixesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$FixesTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$FixesTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$FixesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FixesTable,
      FixRow,
      $$FixesTableFilterComposer,
      $$FixesTableOrderingComposer,
      $$FixesTableAnnotationComposer,
      $$FixesTableCreateCompanionBuilder,
      $$FixesTableUpdateCompanionBuilder,
      (FixRow, $$FixesTableReferences),
      FixRow,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$SegmentsTableCreateCompanionBuilder =
    SegmentsCompanion Function({
      Value<int> id,
      required int trackId,
      required int startTMs,
      Value<int?> endTMs,
    });
typedef $$SegmentsTableUpdateCompanionBuilder =
    SegmentsCompanion Function({
      Value<int> id,
      Value<int> trackId,
      Value<int> startTMs,
      Value<int?> endTMs,
    });

final class $$SegmentsTableReferences
    extends BaseReferences<_$AppDatabase, $SegmentsTable, SegmentRow> {
  $$SegmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$AppDatabase db) => db.tracks.createAlias(
    $_aliasNameGenerator(db.segments.trackId, db.tracks.id),
  );

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
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

  ColumnFilters<int> get startTMs => $composableBuilder(
    column: $table.startTMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTMs => $composableBuilder(
    column: $table.endTMs,
    builder: (column) => ColumnFilters(column),
  );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
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

  ColumnOrderings<int> get startTMs => $composableBuilder(
    column: $table.startTMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTMs => $composableBuilder(
    column: $table.endTMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startTMs =>
      $composableBuilder(column: $table.startTMs, builder: (column) => column);

  GeneratedColumn<int> get endTMs =>
      $composableBuilder(column: $table.endTMs, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentsTable,
          SegmentRow,
          $$SegmentsTableFilterComposer,
          $$SegmentsTableOrderingComposer,
          $$SegmentsTableAnnotationComposer,
          $$SegmentsTableCreateCompanionBuilder,
          $$SegmentsTableUpdateCompanionBuilder,
          (SegmentRow, $$SegmentsTableReferences),
          SegmentRow,
          PrefetchHooks Function({bool trackId})
        > {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> trackId = const Value.absent(),
                Value<int> startTMs = const Value.absent(),
                Value<int?> endTMs = const Value.absent(),
              }) => SegmentsCompanion(
                id: id,
                trackId: trackId,
                startTMs: startTMs,
                endTMs: endTMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int trackId,
                required int startTMs,
                Value<int?> endTMs = const Value.absent(),
              }) => SegmentsCompanion.insert(
                id: id,
                trackId: trackId,
                startTMs: startTMs,
                endTMs: endTMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.trackId,
                                referencedTable: $$SegmentsTableReferences
                                    ._trackIdTable(db),
                                referencedColumn: $$SegmentsTableReferences
                                    ._trackIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentsTable,
      SegmentRow,
      $$SegmentsTableFilterComposer,
      $$SegmentsTableOrderingComposer,
      $$SegmentsTableAnnotationComposer,
      $$SegmentsTableCreateCompanionBuilder,
      $$SegmentsTableUpdateCompanionBuilder,
      (SegmentRow, $$SegmentsTableReferences),
      SegmentRow,
      PrefetchHooks Function({bool trackId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$FixesTableTableManager get fixes =>
      $$FixesTableTableManager(_db, _db.fixes);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
}
