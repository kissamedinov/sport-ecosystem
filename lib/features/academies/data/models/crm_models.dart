import 'package:flutter/material.dart';

enum DayOfWeek {
  MONDAY,
  TUESDAY,
  WEDNESDAY,
  THURSDAY,
  FRIDAY,
  SATURDAY,
  SUNDAY;

  String toShortString() => toString().split('.').last;
  
  static DayOfWeek fromString(String value) {
    return DayOfWeek.values.firstWhere((e) => e.toString().split('.').last == value);
  }
}

class TrainingSchedule {
  final String id;
  final String academyId;
  final List<String> teamIds;
  final DayOfWeek dayOfWeek;
  final String startTime;
  final String endTime;
  final String? location;
  final String? branchId;

  TrainingSchedule({
    required this.id,
    required this.academyId,
    required this.teamIds,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.branchId,
  });

  factory TrainingSchedule.fromJson(Map<String, dynamic> json) {
    return TrainingSchedule(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      teamIds: (json['team_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      dayOfWeek: DayOfWeek.fromString(json['day_of_week'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      location: json['location'] as String?,
      branchId: json['branch_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'academy_id': academyId,
    'team_ids': teamIds,
    'day_of_week': dayOfWeek.toShortString(),
    'start_time': startTime,
    'end_time': endTime,
    'location': location,
    'branch_id': branchId,
  };
}

class AcademyCompositePlayer {
  final String id;
  final String fullName;
  final int? birthYear;
  final String teamName;

  AcademyCompositePlayer({
    required this.id,
    required this.fullName,
    this.birthYear,
    required this.teamName,
  });

  factory AcademyCompositePlayer.fromJson(Map<String, dynamic> json) {
    return AcademyCompositePlayer(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      birthYear: json['birth_year'] as int?,
      teamName: json['team_name'] as String? ?? 'N/A',
    );
  }
}

class AcademyBillingConfig {
  final String id;
  final String academyId;
  final double? monthlySubscriptionFee;
  final double? perSessionFee;
  final String currency;

  AcademyBillingConfig({
    required this.id,
    required this.academyId,
    this.monthlySubscriptionFee,
    this.perSessionFee,
    this.currency = 'KZT',
  });

  factory AcademyBillingConfig.fromJson(Map<String, dynamic> json) {
    return AcademyBillingConfig(
      id: json['id'] as String,
      academyId: json['academy_id'] as String,
      monthlySubscriptionFee: (json['monthly_subscription_fee'] as num?)?.toDouble(),
      perSessionFee: (json['per_session_fee'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'KZT',
    );
  }

  Map<String, dynamic> toJson() => {
    'monthly_subscription_fee': monthlySubscriptionFee,
    'per_session_fee': perSessionFee,
    'currency': currency,
  };
}

class AttendanceSummary {
  final int totalSessions;
  final int present;
  final int absent;
  final int late;
  final int injured;

  AttendanceSummary({
    required this.totalSessions,
    required this.present,
    required this.absent,
    required this.late,
    required this.injured,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalSessions: json['total_sessions'] as int,
      present: json['present'] as int,
      absent: json['absent'] as int,
      late: json['late'] as int,
      injured: json['injured'] as int,
    );
  }
}

class BillingSummary {
  final String playerId;
  final String playerName;
  final AttendanceSummary attendance;
  final double baseFee;
  final double additionalFees;
  final double totalOwed;
  final String currency;

  BillingSummary({
    required this.playerId,
    required this.playerName,
    required this.attendance,
    required this.baseFee,
    required this.additionalFees,
    required this.totalOwed,
    required this.currency,
  });

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      playerId: json['player_id'] as String,
      playerName: json['player_name'] as String,
      attendance: AttendanceSummary.fromJson(json['attendance'] as Map<String, dynamic>),
      baseFee: (json['base_fee'] as num).toDouble(),
      additionalFees: (json['additional_fees'] as num).toDouble(),
      totalOwed: (json['total_owed'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}
