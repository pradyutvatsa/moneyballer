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


/** This is an auto generated class representing the Team type in your schema. */
class Team extends amplify_core.Model {
  static const classType = const _TeamModelType();
  final String id;
  final String? _name;
  final List<TeamMember>? _members;
  final List<Game>? _games;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  TeamModelIdentifier get modelIdentifier {
      return TeamModelIdentifier(
        id: id
      );
  }
  
  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<TeamMember>? get members {
    return _members;
  }
  
  List<Game>? get games {
    return _games;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Team._internal({required this.id, required name, members, games, createdAt, updatedAt}): _name = name, _members = members, _games = games, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Team({String? id, required String name, List<TeamMember>? members, List<Game>? games}) {
    return Team._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      members: members != null ? List<TeamMember>.unmodifiable(members) : members,
      games: games != null ? List<Game>.unmodifiable(games) : games);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Team &&
      id == other.id &&
      _name == other._name &&
      DeepCollectionEquality().equals(_members, other._members) &&
      DeepCollectionEquality().equals(_games, other._games);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Team {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Team copyWith({String? name, List<TeamMember>? members, List<Game>? games}) {
    return Team._internal(
      id: id,
      name: name ?? this.name,
      members: members ?? this.members,
      games: games ?? this.games);
  }
  
  Team copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<List<TeamMember>?>? members,
    ModelFieldValue<List<Game>?>? games
  }) {
    return Team._internal(
      id: id,
      name: name == null ? this.name : name.value,
      members: members == null ? this.members : members.value,
      games: games == null ? this.games : games.value
    );
  }
  
  Team.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _name = json['name'],
      _members = json['members']  is Map
        ? (json['members']['items'] is List
          ? (json['members']['items'] as List)
              .where((e) => e != null)
              .map((e) => TeamMember.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['members'] is List
          ? (json['members'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => TeamMember.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _games = json['games']  is Map
        ? (json['games']['items'] is List
          ? (json['games']['items'] as List)
              .where((e) => e != null)
              .map((e) => Game.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['games'] is List
          ? (json['games'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Game.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'name': _name, 'members': _members?.map((TeamMember? e) => e?.toJson()).toList(), 'games': _games?.map((Game? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'members': _members,
    'games': _games,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<TeamModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<TeamModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final MEMBERS = amplify_core.QueryField(
    fieldName: "members",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'TeamMember'));
  static final GAMES = amplify_core.QueryField(
    fieldName: "games",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Game'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Team";
    modelSchemaDefinition.pluralName = "Teams";
    
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
      key: Team.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Team.MEMBERS,
      isRequired: false,
      ofModelName: 'TeamMember',
      associatedKey: TeamMember.TEAM
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: Team.GAMES,
      isRequired: false,
      ofModelName: 'Game',
      associatedKey: Game.TEAM
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

class _TeamModelType extends amplify_core.ModelType<Team> {
  const _TeamModelType();
  
  @override
  Team fromJson(Map<String, dynamic> jsonData) {
    return Team.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Team';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Team] in your schema.
 */
class TeamModelIdentifier implements amplify_core.ModelIdentifier<Team> {
  final String id;

  /** Create an instance of TeamModelIdentifier using [id] the primary key. */
  const TeamModelIdentifier({
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
  String toString() => 'TeamModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is TeamModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}