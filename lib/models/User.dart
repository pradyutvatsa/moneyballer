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


/** This is an auto generated class representing the User type in your schema. */
class User extends amplify_core.Model {
  static const classType = const _UserModelType();
  final String id;
  final String? _name;
  final String? _email;
  final String? _role;
  final double? _walletBalance;
  final List<TeamMember>? _teams;
  final List<Payment>? _payments;
  final List<RSVP>? _rsvps;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserModelIdentifier get modelIdentifier {
      return UserModelIdentifier(
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
  
  String get email {
    try {
      return _email!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get role {
    return _role;
  }
  
  double get walletBalance {
    try {
      return _walletBalance!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  List<TeamMember>? get teams {
    return _teams;
  }
  
  List<Payment>? get payments {
    return _payments;
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
  
  const User._internal({required this.id, required name, required email, role, required walletBalance, teams, payments, rsvps, createdAt, updatedAt}): _name = name, _email = email, _role = role, _walletBalance = walletBalance, _teams = teams, _payments = payments, _rsvps = rsvps, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory User({String? id, required String name, required String email, String? role, required double walletBalance, List<TeamMember>? teams, List<Payment>? payments, List<RSVP>? rsvps}) {
    return User._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      email: email,
      role: role,
      walletBalance: walletBalance,
      teams: teams != null ? List<TeamMember>.unmodifiable(teams) : teams,
      payments: payments != null ? List<Payment>.unmodifiable(payments) : payments,
      rsvps: rsvps != null ? List<RSVP>.unmodifiable(rsvps) : rsvps);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is User &&
      id == other.id &&
      _name == other._name &&
      _email == other._email &&
      _role == other._role &&
      _walletBalance == other._walletBalance &&
      DeepCollectionEquality().equals(_teams, other._teams) &&
      DeepCollectionEquality().equals(_payments, other._payments) &&
      DeepCollectionEquality().equals(_rsvps, other._rsvps);
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("User {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("role=" + "$_role" + ", ");
    buffer.write("walletBalance=" + (_walletBalance != null ? _walletBalance!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  User copyWith({String? name, String? email, String? role, double? walletBalance, List<TeamMember>? teams, List<Payment>? payments, List<RSVP>? rsvps}) {
    return User._internal(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      teams: teams ?? this.teams,
      payments: payments ?? this.payments,
      rsvps: rsvps ?? this.rsvps);
  }
  
  User copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<String>? email,
    ModelFieldValue<String?>? role,
    ModelFieldValue<double>? walletBalance,
    ModelFieldValue<List<TeamMember>?>? teams,
    ModelFieldValue<List<Payment>?>? payments,
    ModelFieldValue<List<RSVP>?>? rsvps
  }) {
    return User._internal(
      id: id,
      name: name == null ? this.name : name.value,
      email: email == null ? this.email : email.value,
      role: role == null ? this.role : role.value,
      walletBalance: walletBalance == null ? this.walletBalance : walletBalance.value,
      teams: teams == null ? this.teams : teams.value,
      payments: payments == null ? this.payments : payments.value,
      rsvps: rsvps == null ? this.rsvps : rsvps.value
    );
  }
  
  User.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _name = json['name'],
      _email = json['email'],
      _role = json['role'],
      _walletBalance = (json['walletBalance'] as num?)?.toDouble(),
      _teams = json['teams']  is Map
        ? (json['teams']['items'] is List
          ? (json['teams']['items'] as List)
              .where((e) => e != null)
              .map((e) => TeamMember.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['teams'] is List
          ? (json['teams'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => TeamMember.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
      _payments = json['payments']  is Map
        ? (json['payments']['items'] is List
          ? (json['payments']['items'] as List)
              .where((e) => e != null)
              .map((e) => Payment.fromJson(new Map<String, dynamic>.from(e)))
              .toList()
          : null)
        : (json['payments'] is List
          ? (json['payments'] as List)
              .where((e) => e?['serializedData'] != null)
              .map((e) => Payment.fromJson(new Map<String, dynamic>.from(e?['serializedData'])))
              .toList()
          : null),
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
    'id': id, 'name': _name, 'email': _email, 'role': _role, 'walletBalance': _walletBalance, 'teams': _teams?.map((TeamMember? e) => e?.toJson()).toList(), 'payments': _payments?.map((Payment? e) => e?.toJson()).toList(), 'rsvps': _rsvps?.map((RSVP? e) => e?.toJson()).toList(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'email': _email,
    'role': _role,
    'walletBalance': _walletBalance,
    'teams': _teams,
    'payments': _payments,
    'rsvps': _rsvps,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final ROLE = amplify_core.QueryField(fieldName: "role");
  static final WALLETBALANCE = amplify_core.QueryField(fieldName: "walletBalance");
  static final TEAMS = amplify_core.QueryField(
    fieldName: "teams",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'TeamMember'));
  static final PAYMENTS = amplify_core.QueryField(
    fieldName: "payments",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'Payment'));
  static final RSVPS = amplify_core.QueryField(
    fieldName: "rsvps",
    fieldType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.model, ofModelName: 'RSVP'));
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "User";
    modelSchemaDefinition.pluralName = "Users";
    
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
      key: User.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.ROLE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: User.WALLETBALANCE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.double)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: User.TEAMS,
      isRequired: false,
      ofModelName: 'TeamMember',
      associatedKey: TeamMember.USER
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: User.PAYMENTS,
      isRequired: false,
      ofModelName: 'Payment',
      associatedKey: Payment.USER
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.hasMany(
      key: User.RSVPS,
      isRequired: false,
      ofModelName: 'RSVP',
      associatedKey: RSVP.USER
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

class _UserModelType extends amplify_core.ModelType<User> {
  const _UserModelType();
  
  @override
  User fromJson(Map<String, dynamic> jsonData) {
    return User.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'User';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [User] in your schema.
 */
class UserModelIdentifier implements amplify_core.ModelIdentifier<User> {
  final String id;

  /** Create an instance of UserModelIdentifier using [id] the primary key. */
  const UserModelIdentifier({
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
  String toString() => 'UserModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}