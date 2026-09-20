class User {
  final String id;
  final String name;
  final String email;
  final String username;
  final String passwordHash;
  final String age;
  final String gender;
  final String createdAt;
  final int? initialAssessmentScore;
  final String? initialAssessmentCategory;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.passwordHash,
    this.age = '',
    this.gender = 'Prefer not to say',
    required this.createdAt,
    this.initialAssessmentScore,
    this.initialAssessmentCategory,
  });

  User copyWith({
    String? name,
    String? email,
    String? age,
    String? gender,
    int? initialAssessmentScore,
    String? initialAssessmentCategory,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        username: username,
        passwordHash: passwordHash,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        createdAt: createdAt,
        initialAssessmentScore:
            initialAssessmentScore ?? this.initialAssessmentScore,
        initialAssessmentCategory:
            initialAssessmentCategory ?? this.initialAssessmentCategory,
      );

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as String,
        name: j['name'] as String,
        email: j['email'] as String,
        username: j['username'] as String,
        passwordHash: j['passwordHash'] as String,
        age: j['age'] as String? ?? '',
        gender: j['gender'] as String? ?? 'Prefer not to say',
        createdAt: j['createdAt'] as String,
        initialAssessmentScore: j['initialAssessmentScore'] as int?,
        initialAssessmentCategory: j['initialAssessmentCategory'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'passwordHash': passwordHash,
        'age': age,
        'gender': gender,
        'createdAt': createdAt,
        'initialAssessmentScore': initialAssessmentScore,
        'initialAssessmentCategory': initialAssessmentCategory,
      };
}
