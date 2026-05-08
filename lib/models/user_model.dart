import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';

class UserModel {
  final String userId;
  final String name;
  final String username;
  final String phone;
  final String email;
  final String avatar;
  final String? avatarUrl;
  final int credits;
  final int dailyGameCredits;
  final String dailyGameDate;
  final String creditStatus;
  final String fcmToken;
  final bool isOnline;
  final DeviceModel device;
  final Map<String, dynamic> permissions;
  final Map<String, dynamic> location;
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime? lastSpinDate;

  bool get isLocked => credits < -10;

  const UserModel({
    required this.userId,
    required this.name,
    required this.username,
    required this.phone,
    required this.email,
    required this.avatar,
    this.avatarUrl,
    required this.credits,
    this.dailyGameCredits = 0,
    this.dailyGameDate = '',
    this.creditStatus = 'normal',
    required this.fcmToken,
    required this.isOnline,
    required this.device,
    required this.permissions,
    required this.location,
    required this.createdAt,
    required this.lastLogin,
    this.lastSpinDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatar: map['avatar'] as String? ?? 'panda',
      avatarUrl: map['avatar_url'] as String?,
      credits: (map['credits'] as num?)?.toInt() ?? 0,
      dailyGameCredits: (map['daily_game_credits'] as num?)?.toInt() ?? 0,
      dailyGameDate: map['daily_game_date'] as String? ?? '',
      creditStatus: map['credit_status'] as String? ?? 'normal',
      fcmToken: map['fcm_token'] as String? ?? '',
      isOnline: map['is_online'] as bool? ?? false,
      device: map['device'] != null
          ? DeviceModel.fromMap(Map<String, dynamic>.from(map['device']))
          : const DeviceModel(
              model: 'Unknown',
              os: 'Android',
              osVersion: 'Unknown',
              batteryPercentage: 0,
              batteryCapacity: null,
              wirelessCharging: false,
              reverseWirelessCharging: false,
              chargingStandard: 'USB-C',
              bluetoothSupported: true,
              wifiDirectSupported: false),
      permissions: map['permissions'] != null
          ? Map<String, dynamic>.from(map['permissions'])
          : {},
      location: map['location'] != null
          ? Map<String, dynamic>.from(map['location'])
          : {},
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLogin: map['last_login'] != null
          ? DateTime.tryParse(map['last_login'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastSpinDate: map['last_spin_date'] != null
          ? (map['last_spin_date'] is Timestamp
              ? (map['last_spin_date'] as Timestamp).toDate()
              : DateTime.tryParse(map['last_spin_date'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'username': username,
        'phone': phone,
        'email': email,
        'avatar': avatar,
        'avatar_url': avatarUrl,
        'credits': credits,
        'daily_game_credits': dailyGameCredits,
        'daily_game_date': dailyGameDate,
        'credit_status': creditStatus,
        'fcm_token': fcmToken,
        'is_online': isOnline,
        'device': device.toMap(),
        'permissions': permissions,
        'location': location,
        'created_at': createdAt.toIso8601String(),
        'last_login': lastLogin.toIso8601String(),
        'last_spin_date': lastSpinDate?.toIso8601String(),
      };

  UserModel copyWith({
    String? userId,
    String? name,
    String? username,
    String? phone,
    String? email,
    String? avatar,
    String? avatarUrl,
    int? credits,
    int? dailyGameCredits,
    String? dailyGameDate,
    String? creditStatus,
    String? fcmToken,
    bool? isOnline,
    DeviceModel? device,
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? location,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? lastSpinDate,
  }) =>
      UserModel(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        username: username ?? this.username,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        credits: credits ?? this.credits,
        dailyGameCredits: dailyGameCredits ?? this.dailyGameCredits,
        dailyGameDate: dailyGameDate ?? this.dailyGameDate,
        creditStatus: creditStatus ?? this.creditStatus,
        fcmToken: fcmToken ?? this.fcmToken,
        isOnline: isOnline ?? this.isOnline,
        device: device ?? this.device,
        permissions: permissions ?? this.permissions,
        location: location ?? this.location,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
        lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      );
}
