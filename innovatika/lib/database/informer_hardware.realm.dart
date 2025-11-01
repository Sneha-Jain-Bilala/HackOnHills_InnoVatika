// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'informer_hardware.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// ignore_for_file: type=lint
class HardwareInformerr extends _HardwareInformerr
    with RealmEntity, RealmObjectBase, RealmObject {
  HardwareInformerr(
    String name,
    String passwd,
    String devName,
    String devImage,
    int plantAssociated,
    int id,
  ) {
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'passwd', passwd);
    RealmObjectBase.set(this, 'devName', devName);
    RealmObjectBase.set(this, 'devImage', devImage);
    RealmObjectBase.set(this, 'plantAssociated', plantAssociated);
    RealmObjectBase.set(this, 'id', id);
  }

  HardwareInformerr._();

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get passwd => RealmObjectBase.get<String>(this, 'passwd') as String;
  @override
  set passwd(String value) => RealmObjectBase.set(this, 'passwd', value);

  @override
  String get devName => RealmObjectBase.get<String>(this, 'devName') as String;
  @override
  set devName(String value) => RealmObjectBase.set(this, 'devName', value);

  @override
  String get devImage =>
      RealmObjectBase.get<String>(this, 'devImage') as String;
  @override
  set devImage(String value) => RealmObjectBase.set(this, 'devImage', value);

  @override
  int get plantAssociated =>
      RealmObjectBase.get<int>(this, 'plantAssociated') as int;
  @override
  set plantAssociated(int value) =>
      RealmObjectBase.set(this, 'plantAssociated', value);

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  Stream<RealmObjectChanges<HardwareInformerr>> get changes =>
      RealmObjectBase.getChanges<HardwareInformerr>(this);

  @override
  Stream<RealmObjectChanges<HardwareInformerr>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<HardwareInformerr>(this, keyPaths);

  @override
  HardwareInformerr freeze() =>
      RealmObjectBase.freezeObject<HardwareInformerr>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'name': name.toEJson(),
      'passwd': passwd.toEJson(),
      'devName': devName.toEJson(),
      'devImage': devImage.toEJson(),
      'plantAssociated': plantAssociated.toEJson(),
      'id': id.toEJson(),
    };
  }

  static EJsonValue _toEJson(HardwareInformerr value) => value.toEJson();
  static HardwareInformerr _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'name': EJsonValue name,
        'passwd': EJsonValue passwd,
        'devName': EJsonValue devName,
        'devImage': EJsonValue devImage,
        'plantAssociated': EJsonValue plantAssociated,
        'id': EJsonValue id,
      } =>
        HardwareInformerr(
          fromEJson(name),
          fromEJson(passwd),
          fromEJson(devName),
          fromEJson(devImage),
          fromEJson(plantAssociated),
          fromEJson(id),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(HardwareInformerr._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, HardwareInformerr, 'HardwareInformerr', [
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('passwd', RealmPropertyType.string),
      SchemaProperty('devName', RealmPropertyType.string),
      SchemaProperty('devImage', RealmPropertyType.string),
      SchemaProperty('plantAssociated', RealmPropertyType.int),
      SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
