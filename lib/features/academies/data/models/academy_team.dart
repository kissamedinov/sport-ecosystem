class AcademyTeam {
  final String id;
  final String academyId;
  final String name;
  final String ageGroup;
  final String coachId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AcademyTeam({
    required this.id,
    required this.academyId,
    required this.name,
    required this.ageGroup,
    required this.coachId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AcademyTeam.fromJson(Map<String, dynamic> json) {
    return AcademyTeam(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      name: json['name'] as String,
      ageGroup: json['age_group'] as String,
      coachId: json['coach_id'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'academy_id': academyId,
    'name': name,
    'age_group': ageGroup,
    'coach_id': coachId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class AcademyPlayer {
  final String id;
  final String academyId;
  final String playerProfileId;
  final String status;
  final DateTime joinedAt;

  AcademyPlayer({
    required this.id,
    required this.academyId,
    required this.playerProfileId,
    required this.status,
    required this.joinedAt,
  });

  factory AcademyPlayer.fromJson(Map<String, dynamic> json) {
    return AcademyPlayer(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      playerProfileId: json['player_profile_id'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'academy_id': academyId,
    'player_profile_id': playerProfileId,
    'status': status,
    'joined_at': joinedAt.toIso8601String(),
  };
}

class TrainingSession {
  final String id;
  final String academyId;
  final List<String> teamIds;
  final String coachId;
  final String date;
  final String startTime;
  final String endTime;
  final String? description;
  final String? branchId;

  TrainingSession({
    required this.id,
    required this.academyId,
    required this.teamIds,
    required this.coachId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.description,
    this.branchId,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      teamIds: (json['team_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      coachId: json['coach_id'] as String,
      date: json['date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      description: json['description'] as String?,
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'academy_id': academyId,
    'team_ids': teamIds,
    'coach_id': coachId,
    'date': date,
    'start_time': startTime,
    'end_time': endTime,
    'description': description,
    'branch_id': branchId,
  };
}

class AcademyBranch {
  final String id;
  final String academyId;
  final String name;
  final String address;
  final String? description;

  AcademyBranch({
    required this.id,
    required this.academyId,
    required this.name,
    required this.address,
    this.description,
  });

  factory AcademyBranch.fromJson(Map<String, dynamic> json) {
    return AcademyBranch(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'academy_id': academyId,
    'name': name,
    'address': address,
    'description': description,
  };
}

class AcademyTeamPlayer {
  final String id;
  final String playerProfileId;
  final String? fullName;
  final String teamId;
  final String? position;
  final int? jerseyNumber;
  final DateTime joinedAt;

  AcademyTeamPlayer({
    required this.id,
    required this.playerProfileId,
    this.fullName,
    required this.teamId,
    this.position,
    this.jerseyNumber,
    required this.joinedAt,
  });

  factory AcademyTeamPlayer.fromJson(Map<String, dynamic> json) {
    return AcademyTeamPlayer(
      id: json['id'] as String,
      playerProfileId: json['player_profile_id'] as String,
      fullName: json['full_name'] as String?,
      teamId: json['team_id'] as String,
      position: json['position'] as String?,
      jerseyNumber: json['jersey_number'] as int?,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'player_profile_id': playerProfileId,
    'full_name': fullName,
    'team_id': teamId,
    'position': position,
    'jersey_number': jerseyNumber,
    'joined_at': joinedAt.toIso8601String(),
  };
}
