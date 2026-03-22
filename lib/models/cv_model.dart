// ============================================================
// cv_model.dart
// نموذج بيانات السيرة الذاتية الكاملة
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum CVLanguage { arabic, english }

// ─── Personal Info ───────────────────────────────────────────
class CVPersonalInfo {
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String city;
  String country;
  String? linkedIn;
  String? github;
  String? portfolio;
  String? summary;

  CVPersonalInfo({
    this.fullName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.country = '',
    this.linkedIn,
    this.github,
    this.portfolio,
    this.summary,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'jobTitle': jobTitle,
        'email': email,
        'phone': phone,
        'city': city,
        'country': country,
        'linkedIn': linkedIn,
        'github': github,
        'portfolio': portfolio,
        'summary': summary,
      };

  factory CVPersonalInfo.fromMap(Map<String, dynamic> map) => CVPersonalInfo(
        fullName: map['fullName'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        city: map['city'] ?? '',
        country: map['country'] ?? '',
        linkedIn: map['linkedIn'],
        github: map['github'],
        portfolio: map['portfolio'],
        summary: map['summary'],
      );
}

// ─── Experience ───────────────────────────────────────────────
class CVExperience {
  String id;
  String jobTitle;
  String company;
  String city;
  String country;
  String startDate;   // "MM/YYYY"
  String? endDate;    // null = Present / حتى الآن
  bool isCurrent;
  List<String> responsibilities; // bullet points

  CVExperience({
    required this.id,
    this.jobTitle = '',
    this.company = '',
    this.city = '',
    this.country = '',
    this.startDate = '',
    this.endDate,
    this.isCurrent = false,
    this.responsibilities = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobTitle': jobTitle,
        'company': company,
        'city': city,
        'country': country,
        'startDate': startDate,
        'endDate': endDate,
        'isCurrent': isCurrent,
        'responsibilities': responsibilities,
      };

  factory CVExperience.fromMap(Map<String, dynamic> map) => CVExperience(
        id: map['id'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        company: map['company'] ?? '',
        city: map['city'] ?? '',
        country: map['country'] ?? '',
        startDate: map['startDate'] ?? '',
        endDate: map['endDate'],
        isCurrent: map['isCurrent'] ?? false,
        responsibilities: List<String>.from(map['responsibilities'] ?? []),
      );
}

// ─── Education ────────────────────────────────────────────────
class CVEducation {
  String id;
  String degree;
  String major;
  String institution;
  String city;
  String country;
  String startDate;
  String endDate;
  String? gpa;
  List<String> achievements;

  CVEducation({
    required this.id,
    this.degree = '',
    this.major = '',
    this.institution = '',
    this.city = '',
    this.country = '',
    this.startDate = '',
    this.endDate = '',
    this.gpa,
    this.achievements = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'degree': degree,
        'major': major,
        'institution': institution,
        'city': city,
        'country': country,
        'startDate': startDate,
        'endDate': endDate,
        'gpa': gpa,
        'achievements': achievements,
      };

  factory CVEducation.fromMap(Map<String, dynamic> map) => CVEducation(
        id: map['id'] ?? '',
        degree: map['degree'] ?? '',
        major: map['major'] ?? '',
        institution: map['institution'] ?? '',
        city: map['city'] ?? '',
        country: map['country'] ?? '',
        startDate: map['startDate'] ?? '',
        endDate: map['endDate'] ?? '',
        gpa: map['gpa'],
        achievements: List<String>.from(map['achievements'] ?? []),
      );
}

// ─── Skill ────────────────────────────────────────────────────
enum SkillLevel { beginner, intermediate, advanced, expert }

extension SkillLevelLabel on SkillLevel {
  String label(CVLanguage lang) {
    if (lang == CVLanguage.arabic) {
      switch (this) {
        case SkillLevel.beginner: return 'مبتدئ';
        case SkillLevel.intermediate: return 'متوسط';
        case SkillLevel.advanced: return 'متقدم';
        case SkillLevel.expert: return 'خبير';
      }
    } else {
      switch (this) {
        case SkillLevel.beginner: return 'Beginner';
        case SkillLevel.intermediate: return 'Intermediate';
        case SkillLevel.advanced: return 'Advanced';
        case SkillLevel.expert: return 'Expert';
      }
    }
  }
}

class CVSkill {
  String id;
  String name;
  SkillLevel level;
  String category; // e.g. "Programming", "Design", "Soft Skills"

  CVSkill({
    required this.id,
    this.name = '',
    this.level = SkillLevel.intermediate,
    this.category = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'level': level.index,
        'category': category,
      };

  factory CVSkill.fromMap(Map<String, dynamic> map) => CVSkill(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        level: SkillLevel.values[map['level'] ?? 1],
        category: map['category'] ?? '',
      );
}

// ─── Project ──────────────────────────────────────────────────
class CVProject {
  String id;
  String name;
  String description;
  List<String> technologies;
  String? link;
  String? startDate;
  String? endDate;

  CVProject({
    required this.id,
    this.name = '',
    this.description = '',
    this.technologies = const [],
    this.link,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'technologies': technologies,
        'link': link,
        'startDate': startDate,
        'endDate': endDate,
      };

  factory CVProject.fromMap(Map<String, dynamic> map) => CVProject(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        technologies: List<String>.from(map['technologies'] ?? []),
        link: map['link'],
        startDate: map['startDate'],
        endDate: map['endDate'],
      );
}

// ─── Certificate ──────────────────────────────────────────────
class CVCertificate {
  String id;
  String name;
  String issuer;
  String issueDate;
  String? expiryDate;
  String? credentialId;
  String? credentialUrl;

  CVCertificate({
    required this.id,
    this.name = '',
    this.issuer = '',
    this.issueDate = '',
    this.expiryDate,
    this.credentialId,
    this.credentialUrl,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'issuer': issuer,
        'issueDate': issueDate,
        'expiryDate': expiryDate,
        'credentialId': credentialId,
        'credentialUrl': credentialUrl,
      };

  factory CVCertificate.fromMap(Map<String, dynamic> map) => CVCertificate(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        issuer: map['issuer'] ?? '',
        issueDate: map['issueDate'] ?? '',
        expiryDate: map['expiryDate'],
        credentialId: map['credentialId'],
        credentialUrl: map['credentialUrl'],
      );
}

// ─── Language Proficiency ─────────────────────────────────────
enum LanguageProficiency { elementary, limited, professional, fullProfessional, native }

extension LanguageProficiencyLabel on LanguageProficiency {
  String label(CVLanguage lang) {
    if (lang == CVLanguage.arabic) {
      switch (this) {
        case LanguageProficiency.elementary: return 'أساسية';
        case LanguageProficiency.limited: return 'محدودة';
        case LanguageProficiency.professional: return 'احترافية';
        case LanguageProficiency.fullProfessional: return 'احترافية كاملة';
        case LanguageProficiency.native: return 'اللغة الأم';
      }
    } else {
      switch (this) {
        case LanguageProficiency.elementary: return 'Elementary';
        case LanguageProficiency.limited: return 'Limited Working';
        case LanguageProficiency.professional: return 'Professional';
        case LanguageProficiency.fullProfessional: return 'Full Professional';
        case LanguageProficiency.native: return 'Native / Bilingual';
      }
    }
  }
}

class CVLanguageEntry {
  String id;
  String language;
  LanguageProficiency proficiency;

  CVLanguageEntry({
    required this.id,
    this.language = '',
    this.proficiency = LanguageProficiency.professional,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'language': language,
        'proficiency': proficiency.index,
      };

  factory CVLanguageEntry.fromMap(Map<String, dynamic> map) => CVLanguageEntry(
        id: map['id'] ?? '',
        language: map['language'] ?? '',
        proficiency: LanguageProficiency.values[map['proficiency'] ?? 2],
      );
}

// ─── Main CV Model ────────────────────────────────────────────
class CVModel {
  String userId;
  CVLanguage language;
  CVPersonalInfo personalInfo;
  List<CVExperience> experiences;
  List<CVEducation> educations;
  List<CVSkill> skills;
  List<CVProject> projects;
  List<CVCertificate> certificates;
  List<CVLanguageEntry> languages;
  DateTime? lastUpdated;

  CVModel({
    required this.userId,
    this.language = CVLanguage.english,
    CVPersonalInfo? personalInfo,
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
    this.projects = const [],
    this.certificates = const [],
    this.languages = const [],
    this.lastUpdated,
  }) : personalInfo = personalInfo ?? CVPersonalInfo();

  bool get isEmpty =>
      personalInfo.fullName.isEmpty &&
      experiences.isEmpty &&
      educations.isEmpty &&
      skills.isEmpty;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'language': language.index,
        'personalInfo': personalInfo.toMap(),
        'experiences': experiences.map((e) => e.toMap()).toList(),
        'educations': educations.map((e) => e.toMap()).toList(),
        'skills': skills.map((s) => s.toMap()).toList(),
        'projects': projects.map((p) => p.toMap()).toList(),
        'certificates': certificates.map((c) => c.toMap()).toList(),
        'languages': languages.map((l) => l.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  factory CVModel.fromMap(Map<String, dynamic> map) => CVModel(
        userId: map['userId'] ?? '',
        language: CVLanguage.values[map['language'] ?? 1],
        personalInfo: CVPersonalInfo.fromMap(map['personalInfo'] ?? {}),
        experiences: (map['experiences'] as List? ?? [])
            .map((e) => CVExperience.fromMap(e))
            .toList(),
        educations: (map['educations'] as List? ?? [])
            .map((e) => CVEducation.fromMap(e))
            .toList(),
        skills: (map['skills'] as List? ?? [])
            .map((s) => CVSkill.fromMap(s))
            .toList(),
        projects: (map['projects'] as List? ?? [])
            .map((p) => CVProject.fromMap(p))
            .toList(),
        certificates: (map['certificates'] as List? ?? [])
            .map((c) => CVCertificate.fromMap(c))
            .toList(),
        languages: (map['languages'] as List? ?? [])
            .map((l) => CVLanguageEntry.fromMap(l))
            .toList(),
        lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
      );

  CVModel copyWith({
    CVLanguage? language,
    CVPersonalInfo? personalInfo,
    List<CVExperience>? experiences,
    List<CVEducation>? educations,
    List<CVSkill>? skills,
    List<CVProject>? projects,
    List<CVCertificate>? certificates,
    List<CVLanguageEntry>? languages,
  }) =>
      CVModel(
        userId: userId,
        language: language ?? this.language,
        personalInfo: personalInfo ?? this.personalInfo,
        experiences: experiences ?? this.experiences,
        educations: educations ?? this.educations,
        skills: skills ?? this.skills,
        projects: projects ?? this.projects,
        certificates: certificates ?? this.certificates,
        languages: languages ?? this.languages,
      );
}
