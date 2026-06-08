class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String dob;
  final String sex;
  final String height;
  final String weight;
  final String profileImage;
  final String authProvider;
  final bool onboardingCompleted;
  final bool emailVerified;
  final String createdAt;
  final String lastLogin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.dob,
    required this.sex,
    required this.height,
    required this.weight,
    required this.profileImage,
    required this.authProvider,
    required this.onboardingCompleted,
    required this.emailVerified,
    required this.createdAt,
    required this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dob: json['dob'] ?? '',
      sex: json['sex'] ?? '',
      height: json['height'] ?? '',
      weight: json['weight'] ?? '',
      profileImage: json['profileImage'] ?? '',
      authProvider: json['authProvider'] ?? '',
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      createdAt: json['createdAt'] ?? '',
      lastLogin: json['lastLogin'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dob': dob,
      'sex': sex,
      'height': height,
      'weight': weight,
      'profileImage': profileImage,
      'authProvider': authProvider,
      'onboardingCompleted': onboardingCompleted,
      'emailVerified': emailVerified,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? dob,
    String? sex,
    String? height,
    String? weight,
    String? profileImage,
    String? authProvider,
    bool? onboardingCompleted,
    bool? emailVerified,
    String? createdAt,
    String? lastLogin,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      sex: sex ?? this.sex,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      profileImage: profileImage ?? this.profileImage,
      authProvider: authProvider ?? this.authProvider,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
