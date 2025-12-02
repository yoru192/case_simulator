import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String nickname;

  @HiveField(4)
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.nickname,
    required this.createdAt,
  });
}
