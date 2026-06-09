import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachTacticsScreen extends StatefulWidget {
  const CoachTacticsScreen({super.key});

  @override
  State<CoachTacticsScreen> createState() => _CoachTacticsScreenState();
}

class _CoachTacticsScreenState extends State<CoachTacticsScreen> {
  String _format = '11v11';
  String _selected = '4-3-3';

  static const _formationsByFormat = <String, List<_Formation>>{
    '11v11': [
      _Formation('4-3-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('CM', 0.2, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.8, 0.52)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ]),
      _Formation('4-4-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('LM', 0.1, 0.52), _Pos('CM', 0.35, 0.52), _Pos('CM', 0.65, 0.52), _Pos('RM', 0.9, 0.52)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ]),
      _Formation('4-2-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('DM', 0.35, 0.60), _Pos('DM', 0.65, 0.60)],
        [_Pos('LW', 0.15, 0.42), _Pos('CAM', 0.5, 0.40), _Pos('RW', 0.85, 0.42)],
        [_Pos('ST', 0.5, 0.20)],
      ]),
      _Formation('3-5-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.8, 0.74)],
        [_Pos('LWB', 0.05, 0.54), _Pos('CM', 0.28, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.72, 0.52), _Pos('RWB', 0.95, 0.54)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ]),
      _Formation('4-1-4-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('DM', 0.5, 0.62)],
        [_Pos('LM', 0.1, 0.48), _Pos('CM', 0.35, 0.48), _Pos('CM', 0.65, 0.48), _Pos('RM', 0.9, 0.48)],
        [_Pos('ST', 0.5, 0.20)],
      ]),
      _Formation('3-4-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.8, 0.74)],
        [_Pos('LM', 0.1, 0.52), _Pos('CM', 0.35, 0.52), _Pos('CM', 0.65, 0.52), _Pos('RM', 0.9, 0.52)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ]),
      _Formation('4-3-2-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('CM', 0.2, 0.56), _Pos('CM', 0.5, 0.56), _Pos('CM', 0.8, 0.56)],
        [_Pos('AM', 0.32, 0.36), _Pos('AM', 0.68, 0.36)],
        [_Pos('ST', 0.5, 0.20)],
      ]),
      _Formation('4-5-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.35, 0.74), _Pos('CB', 0.65, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('LM', 0.05, 0.50), _Pos('CM', 0.27, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.73, 0.50), _Pos('RM', 0.95, 0.50)],
        [_Pos('ST', 0.5, 0.22)],
      ]),
      _Formation('5-3-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LWB', 0.05, 0.72), _Pos('CB', 0.25, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.75, 0.74), _Pos('RWB', 0.95, 0.72)],
        [_Pos('CM', 0.25, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.75, 0.52)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ]),
    ],
    '9v9': [
      _Formation('3-3-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.8, 0.74)],
        [_Pos('CM', 0.2, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.8, 0.52)],
        [_Pos('ST', 0.35, 0.26), _Pos('ST', 0.65, 0.26)],
      ]),
      _Formation('3-2-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.8, 0.74)],
        [_Pos('CM', 0.35, 0.52), _Pos('CM', 0.65, 0.52)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ]),
      _Formation('4-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.37, 0.74), _Pos('CB', 0.63, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('CM', 0.2, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.8, 0.52)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('2-4-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.74), _Pos('CB', 0.7, 0.74)],
        [_Pos('LM', 0.1, 0.52), _Pos('CM', 0.37, 0.52), _Pos('CM', 0.63, 0.52), _Pos('RM', 0.9, 0.52)],
        [_Pos('ST', 0.35, 0.26), _Pos('ST', 0.65, 0.26)],
      ]),
      _Formation('3-4-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.8, 0.74)],
        [_Pos('LM', 0.1, 0.52), _Pos('CM', 0.37, 0.52), _Pos('CM', 0.63, 0.52), _Pos('RM', 0.9, 0.52)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('4-2-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.74), _Pos('CB', 0.37, 0.74), _Pos('CB', 0.63, 0.74), _Pos('RB', 0.9, 0.74)],
        [_Pos('CM', 0.35, 0.52), _Pos('CM', 0.65, 0.52)],
        [_Pos('ST', 0.35, 0.26), _Pos('ST', 0.65, 0.26)],
      ]),
      _Formation('2-3-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.74), _Pos('CB', 0.7, 0.74)],
        [_Pos('CM', 0.2, 0.52), _Pos('CM', 0.5, 0.52), _Pos('CM', 0.8, 0.52)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ]),
    ],
    '6v6': [
      _Formation('2-2-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.72), _Pos('CB', 0.7, 0.72)],
        [_Pos('CM', 0.3, 0.48), _Pos('CM', 0.7, 0.48)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('1-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.5, 0.74)],
        [_Pos('LM', 0.2, 0.50), _Pos('CM', 0.5, 0.50), _Pos('RM', 0.8, 0.50)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('2-1-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.72), _Pos('CB', 0.7, 0.72)],
        [_Pos('CM', 0.5, 0.50)],
        [_Pos('LW', 0.25, 0.26), _Pos('RW', 0.75, 0.26)],
      ]),
    ],
    '5v5': [
      _Formation('2-1-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.72), _Pos('CB', 0.7, 0.72)],
        [_Pos('CM', 0.5, 0.50)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('1-2-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.5, 0.74)],
        [_Pos('CM', 0.3, 0.50), _Pos('CM', 0.7, 0.50)],
        [_Pos('ST', 0.5, 0.24)],
      ]),
      _Formation('3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.72), _Pos('CB', 0.5, 0.72), _Pos('CB', 0.8, 0.72)],
        [_Pos('ST', 0.5, 0.28)],
      ]),
    ],
  };

  // All text values are localization keys — resolved via .tr() in widgets
  static const _info = <String, _FormationInfo>{
    // ── 11v11 ──────────────────────────────────────────────────────────────
    '4-3-3': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.4_3_3.desc',
      strengths: ['tactics.f.4_3_3.str0','tactics.f.4_3_3.str1','tactics.f.4_3_3.str2','tactics.f.4_3_3.str3'],
      weaknesses: ['tactics.f.4_3_3.weak0','tactics.f.4_3_3.weak1','tactics.f.4_3_3.weak2'],
      coachTips: ['tactics.f.4_3_3.tip0','tactics.f.4_3_3.tip1','tactics.f.4_3_3.tip2','tactics.f.4_3_3.tip3'],
      keyRoles: 'tactics.f.4_3_3.roles',
    ),
    '4-4-2': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.4_4_2.desc',
      strengths: ['tactics.f.4_4_2.str0','tactics.f.4_4_2.str1','tactics.f.4_4_2.str2','tactics.f.4_4_2.str3'],
      weaknesses: ['tactics.f.4_4_2.weak0','tactics.f.4_4_2.weak1','tactics.f.4_4_2.weak2'],
      coachTips: ['tactics.f.4_4_2.tip0','tactics.f.4_4_2.tip1','tactics.f.4_4_2.tip2','tactics.f.4_4_2.tip3'],
      keyRoles: 'tactics.f.4_4_2.roles',
    ),
    '4-2-3-1': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.4_2_3_1.desc',
      strengths: ['tactics.f.4_2_3_1.str0','tactics.f.4_2_3_1.str1','tactics.f.4_2_3_1.str2','tactics.f.4_2_3_1.str3'],
      weaknesses: ['tactics.f.4_2_3_1.weak0','tactics.f.4_2_3_1.weak1','tactics.f.4_2_3_1.weak2'],
      coachTips: ['tactics.f.4_2_3_1.tip0','tactics.f.4_2_3_1.tip1','tactics.f.4_2_3_1.tip2','tactics.f.4_2_3_1.tip3'],
      keyRoles: 'tactics.f.4_2_3_1.roles',
    ),
    '3-5-2': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.3_5_2.desc',
      strengths: ['tactics.f.3_5_2.str0','tactics.f.3_5_2.str1','tactics.f.3_5_2.str2','tactics.f.3_5_2.str3'],
      weaknesses: ['tactics.f.3_5_2.weak0','tactics.f.3_5_2.weak1','tactics.f.3_5_2.weak2'],
      coachTips: ['tactics.f.3_5_2.tip0','tactics.f.3_5_2.tip1','tactics.f.3_5_2.tip2','tactics.f.3_5_2.tip3'],
      keyRoles: 'tactics.f.3_5_2.roles',
    ),
    '4-1-4-1': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.4_1_4_1.desc',
      strengths: ['tactics.f.4_1_4_1.str0','tactics.f.4_1_4_1.str1','tactics.f.4_1_4_1.str2','tactics.f.4_1_4_1.str3'],
      weaknesses: ['tactics.f.4_1_4_1.weak0','tactics.f.4_1_4_1.weak1','tactics.f.4_1_4_1.weak2'],
      coachTips: ['tactics.f.4_1_4_1.tip0','tactics.f.4_1_4_1.tip1','tactics.f.4_1_4_1.tip2','tactics.f.4_1_4_1.tip3'],
      keyRoles: 'tactics.f.4_1_4_1.roles',
    ),
    '3-4-3': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.3_4_3.desc',
      strengths: ['tactics.f.3_4_3.str0','tactics.f.3_4_3.str1','tactics.f.3_4_3.str2','tactics.f.3_4_3.str3'],
      weaknesses: ['tactics.f.3_4_3.weak0','tactics.f.3_4_3.weak1','tactics.f.3_4_3.weak2'],
      coachTips: ['tactics.f.3_4_3.tip0','tactics.f.3_4_3.tip1','tactics.f.3_4_3.tip2','tactics.f.3_4_3.tip3'],
      keyRoles: 'tactics.f.3_4_3.roles',
    ),
    '4-3-2-1': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.4_3_2_1.desc',
      strengths: ['tactics.f.4_3_2_1.str0','tactics.f.4_3_2_1.str1','tactics.f.4_3_2_1.str2','tactics.f.4_3_2_1.str3'],
      weaknesses: ['tactics.f.4_3_2_1.weak0','tactics.f.4_3_2_1.weak1','tactics.f.4_3_2_1.weak2'],
      coachTips: ['tactics.f.4_3_2_1.tip0','tactics.f.4_3_2_1.tip1','tactics.f.4_3_2_1.tip2','tactics.f.4_3_2_1.tip3'],
      keyRoles: 'tactics.f.4_3_2_1.roles',
    ),
    '4-5-1': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.4_5_1.desc',
      strengths: ['tactics.f.4_5_1.str0','tactics.f.4_5_1.str1','tactics.f.4_5_1.str2','tactics.f.4_5_1.str3'],
      weaknesses: ['tactics.f.4_5_1.weak0','tactics.f.4_5_1.weak1','tactics.f.4_5_1.weak2'],
      coachTips: ['tactics.f.4_5_1.tip0','tactics.f.4_5_1.tip1','tactics.f.4_5_1.tip2','tactics.f.4_5_1.tip3'],
      keyRoles: 'tactics.f.4_5_1.roles',
    ),
    '5-3-2': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.5_3_2.desc',
      strengths: ['tactics.f.5_3_2.str0','tactics.f.5_3_2.str1','tactics.f.5_3_2.str2','tactics.f.5_3_2.str3'],
      weaknesses: ['tactics.f.5_3_2.weak0','tactics.f.5_3_2.weak1','tactics.f.5_3_2.weak2'],
      coachTips: ['tactics.f.5_3_2.tip0','tactics.f.5_3_2.tip1','tactics.f.5_3_2.tip2','tactics.f.5_3_2.tip3'],
      keyRoles: 'tactics.f.5_3_2.roles',
    ),
    // ── 9v9 ───────────────────────────────────────────────────────────────
    '3-3-2': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.3_3_2.desc',
      strengths: ['tactics.f.3_3_2.str0','tactics.f.3_3_2.str1','tactics.f.3_3_2.str2'],
      weaknesses: ['tactics.f.3_3_2.weak0','tactics.f.3_3_2.weak1'],
      coachTips: ['tactics.f.3_3_2.tip0','tactics.f.3_3_2.tip1','tactics.f.3_3_2.tip2'],
      keyRoles: 'tactics.f.3_3_2.roles',
    ),
    '3-2-3': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.3_2_3.desc',
      strengths: ['tactics.f.3_2_3.str0','tactics.f.3_2_3.str1','tactics.f.3_2_3.str2'],
      weaknesses: ['tactics.f.3_2_3.weak0','tactics.f.3_2_3.weak1'],
      coachTips: ['tactics.f.3_2_3.tip0','tactics.f.3_2_3.tip1','tactics.f.3_2_3.tip2'],
      keyRoles: 'tactics.f.3_2_3.roles',
    ),
    '4-3-1': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.4_3_1.desc',
      strengths: ['tactics.f.4_3_1.str0','tactics.f.4_3_1.str1','tactics.f.4_3_1.str2'],
      weaknesses: ['tactics.f.4_3_1.weak0','tactics.f.4_3_1.weak1'],
      coachTips: ['tactics.f.4_3_1.tip0','tactics.f.4_3_1.tip1','tactics.f.4_3_1.tip2'],
      keyRoles: 'tactics.f.4_3_1.roles',
    ),
    '2-4-2': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.2_4_2.desc',
      strengths: ['tactics.f.2_4_2.str0','tactics.f.2_4_2.str1','tactics.f.2_4_2.str2'],
      weaknesses: ['tactics.f.2_4_2.weak0','tactics.f.2_4_2.weak1','tactics.f.2_4_2.weak2'],
      coachTips: ['tactics.f.2_4_2.tip0','tactics.f.2_4_2.tip1','tactics.f.2_4_2.tip2','tactics.f.2_4_2.tip3'],
      keyRoles: 'tactics.f.2_4_2.roles',
    ),
    '3-4-1': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.3_4_1.desc',
      strengths: ['tactics.f.3_4_1.str0','tactics.f.3_4_1.str1','tactics.f.3_4_1.str2'],
      weaknesses: ['tactics.f.3_4_1.weak0','tactics.f.3_4_1.weak1'],
      coachTips: ['tactics.f.3_4_1.tip0','tactics.f.3_4_1.tip1','tactics.f.3_4_1.tip2','tactics.f.3_4_1.tip3'],
      keyRoles: 'tactics.f.3_4_1.roles',
    ),
    '4-2-2': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.4_2_2.desc',
      strengths: ['tactics.f.4_2_2.str0','tactics.f.4_2_2.str1','tactics.f.4_2_2.str2'],
      weaknesses: ['tactics.f.4_2_2.weak0','tactics.f.4_2_2.weak1','tactics.f.4_2_2.weak2'],
      coachTips: ['tactics.f.4_2_2.tip0','tactics.f.4_2_2.tip1','tactics.f.4_2_2.tip2','tactics.f.4_2_2.tip3'],
      keyRoles: 'tactics.f.4_2_2.roles',
    ),
    '2-3-3': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.2_3_3.desc',
      strengths: ['tactics.f.2_3_3.str0','tactics.f.2_3_3.str1','tactics.f.2_3_3.str2'],
      weaknesses: ['tactics.f.2_3_3.weak0','tactics.f.2_3_3.weak1','tactics.f.2_3_3.weak2'],
      coachTips: ['tactics.f.2_3_3.tip0','tactics.f.2_3_3.tip1','tactics.f.2_3_3.tip2','tactics.f.2_3_3.tip3'],
      keyRoles: 'tactics.f.2_3_3.roles',
    ),
    // ── 6v6 ───────────────────────────────────────────────────────────────
    '2-2-1': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.2_2_1.desc',
      strengths: ['tactics.f.2_2_1.str0','tactics.f.2_2_1.str1','tactics.f.2_2_1.str2'],
      weaknesses: ['tactics.f.2_2_1.weak0','tactics.f.2_2_1.weak1'],
      coachTips: ['tactics.f.2_2_1.tip0','tactics.f.2_2_1.tip1','tactics.f.2_2_1.tip2'],
      keyRoles: 'tactics.f.2_2_1.roles',
    ),
    '1-3-1': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.1_3_1.desc',
      strengths: ['tactics.f.1_3_1.str0','tactics.f.1_3_1.str1','tactics.f.1_3_1.str2'],
      weaknesses: ['tactics.f.1_3_1.weak0','tactics.f.1_3_1.weak1'],
      coachTips: ['tactics.f.1_3_1.tip0','tactics.f.1_3_1.tip1','tactics.f.1_3_1.tip2'],
      keyRoles: 'tactics.f.1_3_1.roles',
    ),
    '2-1-2': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.2_1_2.desc',
      strengths: ['tactics.f.2_1_2.str0','tactics.f.2_1_2.str1','tactics.f.2_1_2.str2'],
      weaknesses: ['tactics.f.2_1_2.weak0','tactics.f.2_1_2.weak1'],
      coachTips: ['tactics.f.2_1_2.tip0','tactics.f.2_1_2.tip1','tactics.f.2_1_2.tip2'],
      keyRoles: 'tactics.f.2_1_2.roles',
    ),
    // ── 5v5 ───────────────────────────────────────────────────────────────
    '2-1-1': _FormationInfo(
      style: 'tactics.style_balanced', styleColor: 0xFF00E676,
      description: 'tactics.f.2_1_1.desc',
      strengths: ['tactics.f.2_1_1.str0','tactics.f.2_1_1.str1','tactics.f.2_1_1.str2'],
      weaknesses: ['tactics.f.2_1_1.weak0','tactics.f.2_1_1.weak1'],
      coachTips: ['tactics.f.2_1_1.tip0','tactics.f.2_1_1.tip1','tactics.f.2_1_1.tip2'],
      keyRoles: 'tactics.f.2_1_1.roles',
    ),
    '1-2-1': _FormationInfo(
      style: 'tactics.style_attacking', styleColor: 0xFFFF5252,
      description: 'tactics.f.1_2_1.desc',
      strengths: ['tactics.f.1_2_1.str0','tactics.f.1_2_1.str1','tactics.f.1_2_1.str2'],
      weaknesses: ['tactics.f.1_2_1.weak0','tactics.f.1_2_1.weak1'],
      coachTips: ['tactics.f.1_2_1.tip0','tactics.f.1_2_1.tip1','tactics.f.1_2_1.tip2'],
      keyRoles: 'tactics.f.1_2_1.roles',
    ),
    '3-1': _FormationInfo(
      style: 'tactics.style_defensive', styleColor: 0xFF2979FF,
      description: 'tactics.f.3_1.desc',
      strengths: ['tactics.f.3_1.str0','tactics.f.3_1.str1','tactics.f.3_1.str2'],
      weaknesses: ['tactics.f.3_1.weak0','tactics.f.3_1.weak1'],
      coachTips: ['tactics.f.3_1.tip0','tactics.f.3_1.tip1','tactics.f.3_1.tip2'],
      keyRoles: 'tactics.f.3_1.roles',
    ),
  };

  List<_Formation> get _currentFormations => _formationsByFormat[_format]!;

  _FormationInfo get _currentInfo =>
      _info[_selected] ??
      const _FormationInfo(
        style: 'tactics.style_balanced',
        styleColor: 0xFF00E676,
        description: '',
        strengths: [],
        weaknesses: [],
        coachTips: [],
        keyRoles: '',
      );

  @override
  Widget build(BuildContext context) {
    final formation = _currentFormations.firstWhere((f) => f.name == _selected);
    final info = _currentInfo;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFormatSelector()),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _buildFormationSelector()),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildStyleBadge(info)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildPitchCard(formation)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildDescription(info)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildInfoCard(title: 'tactics.strengths', icon: Icons.trending_up_rounded, color: PremiumTheme.neonGreen, items: info.strengths)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildInfoCard(title: 'tactics.weaknesses', icon: Icons.trending_down_rounded, color: PremiumTheme.danger, items: info.weaknesses)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildInfoCard(title: 'tactics.coach_tips', icon: Icons.lightbulb_rounded, color: Colors.amber, items: info.coachTips)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildKeyRoles(info)),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [const Color(0xFF0D2A1A), const Color(0xFF0A1510), PremiumTheme.surfaceBase(context)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF5F5F5), PremiumTheme.surfaceBase(context)],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { HapticFeedback.mediumImpact(); Navigator.pop(context); },
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.chevron_left_rounded, color: onSurface.withValues(alpha: 0.7), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('tactics.header'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.5), letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: ['11v11', '9v9', '6v6', '5v5'].map((fmt) {
          final active = fmt == _format;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() { _format = fmt; _selected = _formationsByFormat[fmt]!.first.name; });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? PremiumTheme.neonGreen : PremiumTheme.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? PremiumTheme.neonGreen : PremiumTheme.neonGreen.withValues(alpha: 0.3)),
              ),
              child: Text(fmt, style: TextStyle(color: active ? Colors.black : PremiumTheme.neonGreen, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormationSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _currentFormations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _currentFormations[i];
          final active = f.name == _selected;
          return GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selected = f.name); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? PremiumTheme.neonGreen : PremiumTheme.neonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? PremiumTheme.neonGreen : PremiumTheme.neonGreen.withValues(alpha: 0.25)),
              ),
              child: Text(f.name, style: TextStyle(color: active ? Colors.black : PremiumTheme.neonGreen, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStyleBadge(_FormationInfo info) {
    final color = Color(info.styleColor);
    final icon = info.style == 'tactics.style_attacking'
        ? Icons.arrow_upward_rounded
        : info.style == 'tactics.style_defensive'
            ? Icons.shield_rounded
            : Icons.balance_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 6),
                Text(info.style.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: PremiumTheme.borderSubtle(context))),
          const SizedBox(width: 8),
          Wrap(
            spacing: 10,
            children: [
              _legendDot('GK', Colors.amber.shade700),
              _legendDot('DEF', PremiumTheme.electricBlue),
              _legendDot('MID', PremiumTheme.neonGreen),
              _legendDot('ATT', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPitchCard(_Formation formation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 280,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                children: [
                  CustomPaint(size: Size(w, h), painter: _PitchPainter()),
                  for (final line in formation.lines)
                    for (final pos in line)
                      Positioned(
                        left: pos.x * w - 22,
                        top: pos.y * h - 25,
                        child: _buildPlayer(pos.label),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer(String label) {
    final color = _posColor(label);
    return SizedBox(
      width: 44, height: 50,
      child: Column(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(child: Text(label.length > 2 ? label.substring(0, 2) : label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
        ],
      ),
    );
  }

  Color _posColor(String pos) {
    if (pos == 'GK') return Colors.amber.shade700;
    if (pos.contains('B') || pos == 'SW') return PremiumTheme.electricBlue;
    if (pos == 'ST' || pos.contains('W') || pos == 'CF' || pos == 'CAM' || pos == 'AM') return Colors.redAccent;
    return PremiumTheme.neonGreen;
  }

  Widget _buildDescription(_FormationInfo info) {
    if (info.description.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: PremiumTheme.neonGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.description_rounded, color: PremiumTheme.neonGreen, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(info.description.tr(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Color color, required List<String> items}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 10),
                Text(title.tr(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  Expanded(child: Text(item.tr(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRoles(_FormationInfo info) {
    if (info.keyRoles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 16).copyWith(
          border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: PremiumTheme.electricBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person_pin_rounded, color: PremiumTheme.electricBlue, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('tactics.key_roles'.tr(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: PremiumTheme.electricBlue, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(info.keyRoles.tr(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pos {
  final String label;
  final double x;
  final double y;
  const _Pos(this.label, this.x, this.y);
}

class _Formation {
  final String name;
  final List<List<_Pos>> lines;
  const _Formation(this.name, this.lines);
}

class _FormationInfo {
  final String style;
  final int styleColor;
  final String description;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> coachTips;
  final String keyRoles;

  const _FormationInfo({
    required this.style,
    required this.styleColor,
    required this.description,
    required this.strengths,
    required this.weaknesses,
    required this.coachTips,
    required this.keyRoles,
  });
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()..color = const Color(0xFF2E7D32);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grass);

    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final stripeH = size.height / 8;
    for (int i = 0; i < 8; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, size.width, stripeH), stripe);
    }

    canvas.drawRect(Rect.fromLTRB(8, 8, size.width - 8, size.height - 8), line);
    canvas.drawLine(Offset(8, size.height / 2), Offset(size.width - 8, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.14, line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, Paint()..color = Colors.white.withValues(alpha: 0.5));

    final bw = size.width * 0.55;
    final bh = size.height * 0.14;
    final bx = (size.width - bw) / 2;
    canvas.drawRect(Rect.fromLTWH(bx, 8, bw, bh), line);
    canvas.drawRect(Rect.fromLTWH(bx, size.height - 8 - bh, bw, bh), line);

    final gw = size.width * 0.2;
    final gh = size.height * 0.03;
    final gx = (size.width - gw) / 2;
    canvas.drawRect(Rect.fromLTWH(gx, 5, gw, gh), line);
    canvas.drawRect(Rect.fromLTWH(gx, size.height - 5 - gh, gw, gh), line);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => false;
}
