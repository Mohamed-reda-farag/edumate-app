import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final Map<String, dynamic>? preferences;
  final String? deviceToken;
  final List<String>? subscribedTopics;
  final bool isEmailVerified;
  final String? phoneNumber;
  final Map<String, dynamic>? profile;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.lastLoginAt,
    this.photoUrl,
    this.preferences,
    this.deviceToken,
    this.subscribedTopics,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.profile,
  }) : assert(uid.isNotEmpty, 'UID cannot be empty'),
       assert(name.trim().isNotEmpty, 'Name cannot be empty'),
       assert(email.contains('@'), 'Email must be valid'),
       assert(name.length <= 100, 'Name cannot exceed 100 characters'),
       assert(email.length <= 100, 'Email cannot exceed 100 characters');

  // Computed properties
  String get displayName {
    final trimmedName = name.trim();
    return trimmedName.isNotEmpty ? trimmedName : 'مستخدم';
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'م';
  }

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  Duration get accountAge => DateTime.now().difference(createdAt);

  Duration get timeSinceLastLogin => DateTime.now().difference(lastLoginAt);

  bool get isActive => timeSinceLastLogin.inDays < 30;

  bool get isNewUser => accountAge.inDays < 7;

  // Preference getters with defaults
  String get preferredLanguage => preferences?['language'] ?? 'ar';
  
  bool get notificationsEnabled => preferences?['notificationsEnabled'] ?? true;
  
  bool get studyRemindersEnabled => preferences?['studyRemindersEnabled'] ?? true;
  
  bool get skillRemindersEnabled => preferences?['skillRemindersEnabled'] ?? true;
  
  String get themeMode => preferences?['themeMode'] ?? 'system';
  
  int get dailyStudyGoal => (preferences?['dailyStudyGoal'] as num?)?.toInt() ?? 2;
  
  List<String> get preferredStudyTimes => 
      (preferences?['preferredStudyTimes'] as List?)?.cast<String>() ?? ['morning'];

  // Profile getters
  String? get university => profile?['university']?.toString();
  String? get major => profile?['major']?.toString();
  String? get studyLevel => profile?['studyLevel']?.toString();
  int? get graduationYear => (profile?['graduationYear'] as num?)?.toInt();
  List<String>? get interests => (profile?['interests'] as List?)?.cast<String>();
  String? get bio => profile?['bio']?.toString();

  // Factory constructors
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse DateTime
    DateTime safeParseDateTime(dynamic value, DateTime defaultValue) {
      if (value == null) return defaultValue;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return defaultValue;
        }
      }
      return defaultValue;
    }

    // Helper function to safely parse string list
    List<String>? safeParseStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
      }
      return null;
    }

    final now = DateTime.now();

    return UserModel(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString(),
      createdAt: safeParseDateTime(map['createdAt'], now),
      lastLoginAt: safeParseDateTime(map['lastLoginAt'], now),
      preferences: map['preferences'] as Map<String, dynamic>?,
      deviceToken: map['deviceToken']?.toString(),
      subscribedTopics: safeParseStringList(map['subscribedTopics']),
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
      phoneNumber: map['phoneNumber']?.toString(),
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) {
      throw ArgumentError('Document does not exist or has no data');
    }

    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({
      'uid': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isEmailVerified': isEmailVerified,
    };

    // Add optional fields only if they're not null
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (preferences != null) map['preferences'] = preferences;
    if (deviceToken != null) map['deviceToken'] = deviceToken;
    if (subscribedTopics != null) map['subscribedTopics'] = subscribedTopics;
    if (phoneNumber != null) map['phoneNumber'] = phoneNumber;
    if (profile != null) map['profile'] = profile;

    return map;
  }

  // Validation methods
  bool isValid() {
    try {
      if (uid.isEmpty) return false;
      if (name.trim().isEmpty) return false;
      if (!email.contains('@') || email.length < 5) return false;
      if (name.length > 100) return false;
      if (email.length > 100) return false;
      if (phoneNumber != null && phoneNumber!.isNotEmpty) {
        // Basic phone number validation
        if (!RegExp(r'^\+?[\d\s\-\(\)]{7,15}$').hasMatch(phoneNumber!)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  List<String> getValidationErrors() {
    final errors = <String>[];

    if (uid.isEmpty) {
      errors.add('معرف المستخدم مطلوب');
    }

    if (name.trim().isEmpty) {
      errors.add('الاسم مطلوب');
    } else if (name.length > 100) {
      errors.add('الاسم طويل جداً (أقصى حد 100 حرف)');
    }

    if (!email.contains('@') || email.length < 5) {
      errors.add('البريد الإلكتروني غير صالح');
    } else if (email.length > 100) {
      errors.add('البريد الإلكتروني طويل جداً (أقصى حد 100 حرف)');
    }

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      if (!RegExp(r'^\+?[\d\s\-\(\)]{7,15}$').hasMatch(phoneNumber!)) {
        errors.add('رقم الهاتف غير صالح');
      }
    }

    if (bio != null && bio!.length > 500) {
      errors.add('النبذة الشخصية طويلة جداً (أقصى حد 500 حرف)');
    }

    if (graduationYear != null) {
      final currentYear = DateTime.now().year;
      if (graduationYear! < 2000 || graduationYear! > currentYear + 10) {
        errors.add('سنة التخرج غير صالحة');
      }
    }

    return errors;
  }

  // Update methods
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? preferences,
    String? deviceToken,
    List<String>? subscribedTopics,
    bool? isEmailVerified,
    String? phoneNumber,
    Map<String, dynamic>? profile,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      deviceToken: deviceToken ?? this.deviceToken,
      subscribedTopics: subscribedTopics ?? this.subscribedTopics,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profile: profile ?? this.profile,
    );
  }

  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }

  UserModel updateDeviceToken(String token) {
    return copyWith(deviceToken: token);
  }

  UserModel updatePreferences(Map<String, dynamic> newPreferences) {
    final updatedPreferences = Map<String, dynamic>.from(preferences ?? {});
    updatedPreferences.addAll(newPreferences);
    return copyWith(preferences: updatedPreferences);
  }

  UserModel updatePreference(String key, dynamic value) {
    final updatedPreferences = Map<String, dynamic>.from(preferences ?? {});
    updatedPreferences[key] = value;
    return copyWith(preferences: updatedPreferences);
  }

  UserModel updateProfile(Map<String, dynamic> newProfile) {
    final updatedProfile = Map<String, dynamic>.from(profile ?? {});
    updatedProfile.addAll(newProfile);
    return copyWith(profile: updatedProfile);
  }

  UserModel addSubscribedTopic(String topic) {
    final currentTopics = List<String>.from(subscribedTopics ?? []);
    if (!currentTopics.contains(topic)) {
      currentTopics.add(topic);
      return copyWith(subscribedTopics: currentTopics);
    }
    return this;
  }

  UserModel removeSubscribedTopic(String topic) {
    final currentTopics = List<String>.from(subscribedTopics ?? []);
    if (currentTopics.contains(topic)) {
      currentTopics.remove(topic);
      return copyWith(subscribedTopics: currentTopics);
    }
    return this;
  }

  UserModel addInterest(String interest) {
    final currentProfile = Map<String, dynamic>.from(profile ?? {});
    final currentInterests = List<String>.from(currentProfile['interests'] ?? []);
    
    if (!currentInterests.contains(interest)) {
      currentInterests.add(interest);
      currentProfile['interests'] = currentInterests;
      return copyWith(profile: currentProfile);
    }
    return this;
  }

  UserModel removeInterest(String interest) {
    final currentProfile = Map<String, dynamic>.from(profile ?? {});
    final currentInterests = List<String>.from(currentProfile['interests'] ?? []);
    
    if (currentInterests.contains(interest)) {
      currentInterests.remove(interest);
      currentProfile['interests'] = currentInterests;
      return copyWith(profile: currentProfile);
    }
    return this;
  }

  // Utility methods
  bool hasPreference(String key) {
    return preferences?.containsKey(key) ?? false;
  }

  T? getPreference<T>(String key, [T? defaultValue]) {
    final value = preferences?[key];
    if (value is T) return value;
    return defaultValue;
  }

  bool isSubscribedToTopic(String topic) {
    return subscribedTopics?.contains(topic) ?? false;
  }

  bool hasInterest(String interest) {
    return interests?.contains(interest) ?? false;
  }

  bool hasCompleteProfile() {
    return hasPhoto && 
           university != null && 
           major != null && 
           studyLevel != null;
  }

  Map<String, dynamic> getProfileCompletionStatus() {
    return {
      'hasPhoto': hasPhoto,
      'hasUniversity': university != null,
      'hasMajor': major != null,
      'hasStudyLevel': studyLevel != null,
      'hasGraduationYear': graduationYear != null,
      'hasInterests': interests != null && interests!.isNotEmpty,
      'hasBio': bio != null && bio!.isNotEmpty,
      'hasPhoneNumber': phoneNumber != null,
      'isEmailVerified': isEmailVerified,
    };
  }

  double get profileCompletionPercentage {
    final status = getProfileCompletionStatus();
    final trueCount = status.values.where((value) => value == true).length;
    return (trueCount / status.length) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
           other.uid == uid &&
           other.email == email;
  }

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'UserModel(\n'
           '  uid: $uid\n'
           '  name: $name\n'
           '  email: $email\n'
           '  hasPhoto: $hasPhoto\n'
           '  isActive: $isActive\n'
           '  isNewUser: $isNewUser\n'
           '  profileCompletion: ${profileCompletionPercentage.toStringAsFixed(1)}%\n'
           '  accountAge: ${accountAge.inDays} days\n'
           ')';
  }

  // JSON serialization
  Map<String, dynamic> toJson() => toMap();
  
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
}

// API Response wrapper class
class ApiResponse<T> {
  final bool success;
  final String? error;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    required this.success,
    this.error,
    this.data,
    this.message,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  factory ApiResponse.error({
    required String error,
    String? message,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode ?? 400,
      metadata: metadata,
    );
  }

  factory ApiResponse.fromMap(Map<String, dynamic> map, T? data) {
    return ApiResponse<T>(
      success: map['success'] as bool? ?? false,
      error: map['error']?.toString(),
      data: data,
      message: map['message']?.toString(),
      statusCode: (map['statusCode'] as num?)?.toInt(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'success': success,
    };

    if (error != null) map['error'] = error;
    if (message != null) map['message'] = message;
    if (statusCode != null) map['statusCode'] = statusCode;
    if (metadata != null) map['metadata'] = metadata;
    
    // Note: data is not included in toMap as it's type-specific
    
    return map;
  }

  bool get hasError => !success || error != null;
  
  bool get isSuccessful => success && error == null;

  @override
  String toString() {
    return 'ApiResponse(\n'
           '  success: $success\n'
           '  error: $error\n'
           '  message: $message\n'
           '  statusCode: $statusCode\n'
           '  hasData: ${data != null}\n'
           ')';
  }
}

// User statistics class
class UserStatistics {
  final int totalTasks;
  final int completedTasks;
  final int totalSubjects;
  final int totalSkillPaths;
  final double overallProgress;
  final int streakDays;
  final DateTime lastActive;
  final Map<String, int> tasksByType;
  final Map<String, double> subjectProgress;
  
  const UserStatistics({
    required this.totalTasks,
    required this.completedTasks,
    required this.totalSubjects,
    required this.totalSkillPaths,
    required this.overallProgress,
    required this.streakDays,
    required this.lastActive,
    required this.tasksByType,
    required this.subjectProgress,
  });

  double get completionRate {
    if (totalTasks == 0) return 0.0;
    return (completedTasks / totalTasks) * 100;
  }

  int get pendingTasks => totalTasks - completedTasks;

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      totalTasks: (map['totalTasks'] as num?)?.toInt() ?? 0,
      completedTasks: (map['completedTasks'] as num?)?.toInt() ?? 0,
      totalSubjects: (map['totalSubjects'] as num?)?.toInt() ?? 0,
      totalSkillPaths: (map['totalSkillPaths'] as num?)?.toInt() ?? 0,
      overallProgress: (map['overallProgress'] as num?)?.toDouble() ?? 0.0,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      lastActive: map['lastActive'] is Timestamp 
          ? (map['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
      tasksByType: Map<String, int>.from(map['tasksByType'] ?? {}),
      subjectProgress: Map<String, double>.from(map['subjectProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'totalSubjects': totalSubjects,
      'totalSkillPaths': totalSkillPaths,
      'overallProgress': overallProgress,
      'streakDays': streakDays,
      'lastActive': Timestamp.fromDate(lastActive),
      'tasksByType': tasksByType,
      'subjectProgress': subjectProgress,
    };
  }
}