/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;
import 'package:collection/collection.dart';


/** This is an auto generated class representing the Game type in your schema. */
class Game extends amplify_core.Model {
  static const classType = const _GameModelType();
  final String id;
  final amplify_core.TemporalDate? _date;
  final amplify_core.TemporalTime? _time;
  final String? _location;
  final String? _organizerId;
  final int? _maxPlayers;
  final double? _appFee;
  final double? _minimumBalanceRequired;
  final Team? _team;
  final List<RSVP>? _rsvps;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  GameModelIdentifier get modelIdentifier {
      return GameModelIdentifier(
        id: id
      );
  }
  
  amplify_core.TemporalDate get date {
    try {
      return _date!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalTime get time {
    try {
      return _time!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get location {
    try {
      return _location!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get organizerId {
    try {
      return _organizerId!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get maxPlayers {
    try {
      return _maxPlayers!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get appFee {
    try {
      return _appFee!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  double get minimumBalanceRequired {
    try {
      return _minimumBalanceRequired!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  Team? get team {
    return _team;
  }
  
  List<RSVP>? get rsvps {
    return _rsvps;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Game._internal({required this.id, required date, required time, required location, required organizerId, required maxPlayers, required appFee, required minimumBalanceRequired, team, rsvps, createdAt, updatedAt}): _date = date, _time = time, _location = location, _organizerId = organizerId, _maxPlayers = maxPlayers, _appFee = appFee, _minimumBalanceRequired = minimumBalanceRequired, _team = team, _rsvps = rsvps, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Game({String? id, required amplify_core.TemporalDate date, required amplify_core.TemporalTime time, required String location, required String organizerId, required int maxPlayers, required double appFee, required double minimumBalanceRequired, Team? team, List<RSVP>? rsvps}) {
    return Game._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      date: date,
      time: time,
      location: location,
      organizerId: organizerId,
      maxPlayers: maxPlayers,
      appFee: appFee,
      minimumBalanceRequired: minimumBalanceRequired,
      team: team,
      rsvps: rsvps != null ? List<RSVP>.unmodifiable(rsvps) : rsvps);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Game &&
      id == other.id &&
      _date == other._date &&
      _time == other._time &&
      _location == other._location &&
      _organizerId == other._organizerId &&
      _maxPlayers == other._maxPlayers &&
      _appFee == other._appFee &&
      _minimumBalanceRequired == other._minimumBalanceRequired &&
      _team == other._team &&
      DeepCollectionEquality().equals(_rsvps, other._rsvps);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Game {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("date=" + (_date != null ? _date!.format() : "null") + ", ");
    buffer.write("time=" + (_time != null ? _time!.format() : "null") + ", ");
    buffer.write("location=" + "$_location" + ", ");
    buffer.write("organizerId=" + "$_organizerId" + ", ");
    buffer.write("maxPlayers=" + (_maxPlayers != null ? _maxPlayers!.toString() : "null") + ", ");
    buffer.write("appFee=" + (_appFee != null ? _appFee!.toString() : "null") + ", ");
    buffer.write("minimumBalanceRequired=" + (_minimumBalanceRequired != null ? _minimumBalanceRequired!.toString() : "null") + ", ");
    buffer.write("team=" + (_team != null ? _team!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Game copyWith({amplify_core.TemporalDate? date, amplify_core.TemporalTime? time, String? location, String? organizerId, int? maxPlayers, double? appFee, double? minimumBalanceRequired, Team? team, List<RSVP>? rsvps}) {
    return Game._internal(
      id: id,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      appFee: appFee ?? this.appFee,
      minimumBalanceRequired: minimumBalanceRequired ?? this.minimumBalanceRequired,
      team: team ?? this.team,
      rsvps: rsvps ?? this.rsvps);
  }
  
  Game copyWithModelFieldValues({
    ModelFieldValue<amplify_core.TemporalDate>? date,
    ModelFieldValue<amplify_core.TemporalTime>? time,
    ModelFieldValue<String>? location,
    ModelFieldValue<String>? organizerId,
    ModelFieldValue<int>? maxPlayers,
    ModelFieldValue<double>? appFee,
    ModelFieldValue<double>? minimumBalanceRequired,
    ModelFieldValue<Team?>? team,
    ModelFieldValue<List<RSVP>?>? rsvps
  }) {
    return Game._internal(
      id: id,
      date: date == null ? this.date : date.value,
      time: time == null ? this.time : time.value,
      location: location == null ? this.location : location.value,
      organizerId: organizerId == null ? this.organizerId : organizerId.value,
      maxPlayers: maxPlayers == null ? this.maxPlayers : maxPlayers.value,
      appFee: appFee == null ? this.appFee : appFee.value,
      minimumBalanceRequired: minimumBalanceRequired == null ? this.minimumBalanceRequired : minimumBalanceRequired.value,
      team: team == null ? this.team : team.value,
      rsvps: rsvps == null ? this.rsvps : rsvps.value
    );
  }
  
  Game.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _date = json['date'] != null ? amplify_core.TemporalDate.fromString(json['date']) : null,
      _time = json['time'] != null ? amplify_core.TemporalTime.fromString(json['time']) : null,
      _location = json['location'],
      _organizerId = json['organizerId'],
      _maxPlayers = (json['maxPlayers'] as num?)?.toInt(),
      _appFee = (json['appFee'] as num?)?.toDouble(),
      _minimumBalanceRequired = (json['minimumBalanceRequired'] as num?)?.toDouble(),
      _team = json['team'] != null
        ? json['team']['serializedData'] != null
          ? Team.fromJson(new Map<String, dynamic>.from(json['team']['serializedData']))
          : Team.fromJson(new Map<String, dynamic>.from(json['team']))
        : null,
      _rsvps = json['rsvps']  is Map
        ? (json['rsvps']['items'] is List
          ? (json['rsvps']['items'] as List)
              .where((e) => e != null)
              .map((e) => RSVP.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['rsvps'] is List
          ? (json['rsvps'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => RSVP.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'date': _date?.format(), 'time': _time?.format(), 'location': _location, 'organizerId': _organizerId, 'maxPlayers': _maxPlayers, 'appFee': _appFee, 'minimumBalanceRequired': _minimumBalanceRequired, 'team': _team?.toJson(), 'rsvps': _rsvps?.map((RSVP? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'date': _date,
    'time': _time,
    'location': _location,
    'organizerId': _organizerId,
    'maxPlayers': _maxPlayers,
    'appFee': _appFee,
    'minimumBalanceRequired': _minimumBalanceRequired,
    'team': _team,
    'rsvps': _rsvps,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<GameModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<GameModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final DATE = amplify_core.QueryField(fieldName: "date");
  static final TIME = amplify_core.QueryField(fieldName: "time");
  static final LOCATION = amplify_core.QueryField(fieldName: "location");
  static final ORGANIZERID = amplify_core.QueryField(fieldName: "organizerId");
  static final MAXPLAYERS = amplify_core.QueryField(fieldName: "maxPlayers");
  static final APPFEE = amplify_core.QueryField(fieldName: "appFee");
  static final MINIMUMBALANCEREQUIRED = amplify_core.QueryField(fieldName: "minimumBalanceRequired");
  static final TEAM = amplify_core.QueryField(
    fieldName: "team",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Team'));
  static final RSVPS = amplify_core.QueryField(
    fieldName: "rsvps",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'RSVP'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Game";
    modelSchemaDefinition.pluralName = "Games";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PUBLIC,
        provider: amplify_core.AuthRuleProvider.APIKEY,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.DATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.date)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.TIME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.time)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.LOCATION,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.ORGANIZERID,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.MAXPLAYERS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.APPFEE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Game.MINIMUMBALANCEREQUIRED,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.belongsTo(
      key: Game.TEAM,
      isRequired: false,
      targetNames: ['teamId'],
      ofModelName: 'Team'
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Game.RSVPS,
      isRequired: false,
      ofModelName: 'RSVP',
      associatedKey: RSVP.GAME
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _GameModelType extends amplify_core.ModelType<Game> {
  const _GameModelType();
  
  @override
  Game fromJson(Map<String, dynamic> jsonData) {
    return Game.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Game';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Game] in your schema.
 */
class GameModelIdentifier implements amplify_core.ModelIdentifier<Game> {
  final String id;

  /** Create an instance of GameModelIdentifier using [id] the primary key. */
  const GameModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'GameModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is GameModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}