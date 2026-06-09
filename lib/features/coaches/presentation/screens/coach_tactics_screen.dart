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

  // ─── Formation positions ───────────────────────────────────────────────────

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

  // ─── Coach knowledge base (English) ───────────────────────────────────────

  static const _info = <String, _FormationInfo>{
    // ── 11v11 ──────────────────────────────────────────────────────────────
    '4-3-3': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'One of the most popular formations in world football. Best suited for teams with quick, direct wingers and a technically strong centre-forward who can lead the line.',
      strengths: [
        'High press through three forwards pins defenders back',
        'Wide play stretches the opposition defence',
        'Midfield trio controls tempo and transitions',
        'Fast counter-attacks through the wide channels',
      ],
      weaknesses: [
        'Vulnerable centrally if the ball is lost in midfield',
        'Full-backs must cover large distances for attacking wingers',
        'Demands high-intensity pressing from all three forwards',
      ],
      coachTips: [
        'The central CM plays as a box-to-box "eight" — attack and recover constantly',
        'Wingers cut inside to free space for overlapping full-backs',
        'Pressing trigger: lead striker pressures the CB, wingers close full-backs simultaneously',
        'Without the ball, transition to 4-5-1 — wingers drop into midfield line',
      ],
      keyRoles: 'Wingers are the attacking engine. Central CM is the team\'s brain and must cover the most ground.',
    ),
    '4-4-2': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'The classic flat formation with two banks of four. Reliable and well-understood by players at every level. Works best with a disciplined team and a strong striking partnership.',
      strengths: [
        'Compact defensive shape — two solid banks of four',
        'Wide midfielders provide width in attack and track back',
        'Two strikers create constant threat and combine effectively',
        'Simple structure that is easy to organise and communicate',
      ],
      weaknesses: [
        'Vulnerable in central midfield against a 4-3 shape',
        'Wide midfielders cover enormous ground and fatigue quickly',
        'Limited creativity in central areas with only two CMs',
      ],
      coachTips: [
        'Wide midfielders must be two-way players — contribute to attack and track back',
        'Strikers work as a unit: one holds up play, the other makes runs',
        'CMs must aggressively cover the central channel — no free passes through the middle',
        'From set pieces, both strikers and at least one CM attack the box',
      ],
      keyRoles: 'The striking pair — chemistry and understanding is critical. CMs — high work rate and interceptions.',
    ),
    '4-2-3-1': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'One of the most tactically flexible formations. The double pivot protects the defence while the attacking trio and CAM create around the lone striker. Used by elite clubs worldwide.',
      strengths: [
        'Double pivot provides a solid defensive shield',
        'CAM links midfield and attack with creative freedom',
        'Attacking trio has multiple combinations',
        'Excellent at controlling possession and tempo',
      ],
      weaknesses: [
        'Lone striker can become isolated without quick support',
        'Wide areas can open up when wingers commit forward',
        'Requires a CAM of high technical and tactical quality',
      ],
      coachTips: [
        'CAM must constantly move between the lines to receive and turn',
        'One DM acts as the anchor, the second can advance when safe',
        'Wingers attack — full-backs hold their positions to avoid exposure',
        'Striker holds up play with their back to goal, CAM makes late runs to join',
      ],
      keyRoles: 'CAM is the creative hub. The double pivot DM partnership is the defensive backbone.',
    ),
    '3-5-2': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'Three centre-backs with wing-backs who act as both defenders and attackers. The five-man midfield creates numerical superiority in the centre. Popular in European elite football.',
      strengths: [
        'Five-man midfield dominates central zones',
        'Wing-backs provide attacking width without sacrificing defensive structure',
        'Three CBs deal with crosses and overloads confidently',
        'Flexible: transitions smoothly to 5-3-2 on losing the ball',
      ],
      weaknesses: [
        'The space behind wing-backs is a key vulnerability',
        'Wing-backs require exceptional fitness and technical quality',
        'Three CBs must be comfortable playing out from the back',
      ],
      coachTips: [
        'Wing-backs are the most important players — they must be world-class in both phases',
        'On losing possession, wing-backs sprint back immediately to form 5-3-2',
        'The central CB leads and organises the back three at all times',
        'Press high through two strikers when the opposition GK is in possession',
      ],
      keyRoles: 'Wing-backs are the key players. Central CB organises. Midfield trio must be tireless.',
    ),
    '4-1-4-1': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'A structured formation with a single defensive midfielder as a shield between the back four and the attacking four. The lone striker leads a counter-attacking game.',
      strengths: [
        'Single pivot sits deep and protects the back four effectively',
        'Four midfielders dominate central and wide zones',
        'Wingers can attack with the DM covering behind them',
        'Compact block is difficult to break down',
      ],
      weaknesses: [
        'DM can be overloaded if the opposition plays two strikers',
        'Lone striker needs to hold up play and press simultaneously',
        'Can become too passive if wide midfielders don\'t contribute going forward',
      ],
      coachTips: [
        'The DM must have elite positional awareness and reading of the game',
        'Wide midfielders provide width and attacking crosses — key attacking outlets',
        'Lone striker must press the CB with the ball and hold play up when received',
        'In possession the DM recycles — wide players make runs in behind',
      ],
      keyRoles: 'DM is the cornerstone of the entire defensive structure. Wide midfielders are the main attacking threat.',
    ),
    '3-4-3': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'An aggressive formation with three centre-backs and four midfielders supporting three forwards. Popularised by Conte at Juventus and Chelsea. Requires athletic, disciplined players.',
      strengths: [
        'Three forwards create relentless pressure on the opposition defence',
        'Four midfielders control the central areas in possession',
        'Three CBs handle crosses and duels with numerical superiority',
        'Midfield box wins second balls and transitions quickly',
      ],
      weaknesses: [
        'Space behind the wide midfielders can be exploited',
        'Three CBs must be comfortable in a back three with the ball',
        'Wide midfielders have enormous ground to cover in both directions',
      ],
      coachTips: [
        'Wide midfielders must be the widest attacking players when in possession',
        'The three CBs hold a flat line — middle CB organises and communicates constantly',
        'Three forwards press as a coordinated unit — no individual chasing',
        'Without the ball, wide midfielders drop quickly to form a solid 3-4-3 / 5-4-1 defensive block',
      ],
      keyRoles: 'Wide midfielders are crucial — must attack and defend. Central CB organises the back three.',
    ),
    '4-3-2-1': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'Known as the "Christmas Tree" due to its shape. Three central midfielders feed two attacking mids who support a lone striker. Creates overloads in central zones and between the lines.',
      strengths: [
        'Overloads central zones at every level of the pitch',
        'Two AMs find pockets between opposition midfield and defence',
        'High creativity around the striker from multiple angles',
        'Solid defensive shape with four disciplined defenders',
      ],
      weaknesses: [
        'No natural width — full-backs must provide all the attacking width',
        'Both AMs need high technical quality and positional intelligence',
        'Susceptible to being overloaded on the flanks by wide formations',
      ],
      coachTips: [
        'Full-backs must overlap constantly to provide width going forward',
        'AMs position themselves between opposition lines to receive on the half-turn',
        'Striker holds up play, links with AMs, and makes runs in behind',
        'When shifted wide by opponents, the block must move laterally as a unit quickly',
      ],
      keyRoles: 'The two AMs are the creative engine. Full-backs provide all the width — their attacking contribution is critical.',
    ),
    '4-5-1': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'A highly defensive formation that packs the midfield. Designed to absorb pressure and break quickly on the counter. The lone striker must be fast, clinical, and work relentlessly.',
      strengths: [
        'Five midfielders make the centre nearly impenetrable',
        'Compact 4-5 block is very hard to break down',
        'Lone striker can be lethal on quick counter-attacks',
        'Ideal when defending a lead or facing a superior opponent',
      ],
      weaknesses: [
        'Very limited offensive play by design — ball winning is the priority',
        'Lone striker is isolated and receives little support',
        'Wide midfielders carry enormous defensive and physical workload',
      ],
      coachTips: [
        'Lone striker must be the fastest player — built for explosive counter-attacks',
        'Midfield five press in a coordinated wave — never chase individually',
        'Wide midfielders must track back immediately every time possession is lost',
        'Win the ball quickly, find the striker in behind with one direct pass',
      ],
      keyRoles: 'Lone striker must be a clinical counter-attacking finisher. Wide midfielders — tireless workaholics.',
    ),
    '5-3-2': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'A defensive formation built around a back five. Wing-backs provide width in attack while five defenders shut down the opposition. Two strikers are dangerous on the counter-attack.',
      strengths: [
        'Maximum defensive density with five back-line players',
        'Covers all central and wide defensive zones effectively',
        'Wing-backs provide safe attacking width without high risk',
        'Two strikers combine well on fast counter-attacks',
      ],
      weaknesses: [
        'Limited attacking options — relies on counter-attacks',
        'Concedes initiative to the opposition',
        'Requires extremely high tactical discipline from all players',
      ],
      coachTips: [
        'Deploy when holding a lead or needing a point against stronger opposition',
        'Strikers must be fast — the key weapon is the direct counter-attack 2v2',
        'The back five holds a strict line — no chasing the ball out of shape',
        'CMs block the space between the lines — no deep runs allowed forward',
      ],
      keyRoles: 'Central CB organises the back five. Strikers must be fast counter-attacking finishers.',
    ),

    // ── 9v9 ───────────────────────────────────────────────────────────────
    '3-3-2': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'The most common 9v9 formation. A familiar and balanced structure that gives players clear roles and responsibilities across the pitch.',
      strengths: [
        'Compact and easy to understand for young players',
        'Midfield trio dominates the central zones in 9v9',
        'Two strikers create constant threat and combine naturally',
      ],
      weaknesses: [
        'Limited width — the flanks can be difficult to use effectively',
        'Central CM is overloaded as the link between all lines',
      ],
      coachTips: [
        'Wide CMs must take wide positions to provide attacking width',
        'Strikers stay connected — work in a pair, not independently',
        'On losing the ball, build a compact 3-3 defensive block quickly',
      ],
      keyRoles: 'Central CM — organiser and link player. Two strikers must have chemistry and understanding.',
    ),
    '3-2-3': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'An attack-minded 9v9 formation with three forwards and only two midfielders. Best for technically superior teams who want to dominate possession and create many chances.',
      strengths: [
        'Three forwards provide constant pressure on the defence',
        'Wide attackers stretch the opposition and create space',
        'Quick combinations between forwards and midfielders',
      ],
      weaknesses: [
        'Only two CMs — central midfield is exposed when pressing fails',
        'Demands very high fitness from both midfielders',
      ],
      coachTips: [
        'CMs work as a pair — one attacks, the other covers and stays back',
        'Wingers must track back when the team loses possession',
        'Three CBs hold a strict compact line — no chasing forward',
      ],
      keyRoles: 'Winger pair are the main attacking weapons. Two CMs share all the defensive and creative work.',
    ),
    '4-3-1': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'A structured defensive 9v9 formation with maximum coverage in midfield and defence. The lone striker leads a counter-attacking approach.',
      strengths: [
        'Four defenders form a secure and compact back line',
        'Midfield trio closes down central spaces effectively',
        'Lone striker is dangerous on counter-attacks with space',
      ],
      weaknesses: [
        'Single striker receives very little support in attacking phases',
        'Concedes possession and territory to the opposition',
      ],
      coachTips: [
        'Striker must be fast and able to hold up play in isolation',
        'CMs can push forward to support the striker alternately',
        'Use this formation when you need to protect a lead',
      ],
      keyRoles: 'Striker must be a complete player — pressing, holding, and finishing. CMs — work rate is everything.',
    ),
    '2-4-2': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'An attacking 9v9 formation with four midfielders and two strikers supported by only two defenders. Best used by technically superior and confident teams.',
      strengths: [
        'Four midfielders dominate possession and create overloads',
        'Two strikers maintain constant pressure on defenders',
        'Wide midfielders provide both width and goal threat',
      ],
      weaknesses: [
        'Two defenders are exposed and highly pressured',
        'Midfielders must track back immediately when the ball is lost',
        'High risk formation — any loss of structure can lead to goals',
      ],
      coachTips: [
        'Both CBs must be commanding in 1v1 and dominant aerially',
        'Wide midfielders cover the flanks defensively when CBs are exposed',
        'One CM always stays closer to the defensive line to provide cover',
        'Best used when your team is technically dominant and confident',
      ],
      keyRoles: 'Both CBs must be the best defenders. One CM must discipline themselves to stay back.',
    ),
    '3-4-1': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'A structured 9v9 formation with three defenders, four midfielders, and a lone striker. Midfield dominance is the main characteristic of this shape.',
      strengths: [
        'Four midfielders control the central areas comprehensively',
        'Three CBs provide reliable defensive coverage',
        'Wide midfielders offer width in both attacking and defensive phases',
      ],
      weaknesses: [
        'Single striker must work extremely hard to create chances alone',
        'Wide midfielders must cover an enormous amount of ground',
      ],
      coachTips: [
        'Central midfielders set the tempo and control possession',
        'Wide midfielders provide crosses and track back to their defensive positions',
        'Striker must press CBs high and hold play up when received',
        'Three CBs stay compact — no individual stepping out to chase the ball',
      ],
      keyRoles: 'Central midfielders are the engine room. Striker must be a complete forward who can work alone.',
    ),
    '4-2-2': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'A solid defensive 9v9 structure with a secure back four and two central midfielders. Two strikers provide a direct counter-attacking threat when possession is won.',
      strengths: [
        'Back four provides a secure and organised defensive line',
        'Two strikers are a constant counter-attacking threat',
        'Compact shape absorbs pressure effectively',
      ],
      weaknesses: [
        'Two CMs are heavily overloaded in central midfield',
        'Midfield can be bypassed easily by opposition',
        'Limited ability to build play from deep',
      ],
      coachTips: [
        'Two CMs must have elite work rate — they do everything defensively and creatively',
        'Strikers work as a pair: one holds, one makes runs in behind',
        'Full-backs can push forward cautiously when the team has the ball deep',
        'Win the ball and attack immediately — delay kills the counter',
      ],
      keyRoles: 'Two CMs carry the entire midfield burden — fitness and work rate are essential. Striker pair must combine well.',
    ),
    '2-3-3': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'A high-risk, high-reward attacking 9v9 formation. Three forwards and three midfielders create numerical superiority in advanced areas, supported by only two defenders.',
      strengths: [
        'Three forwards create relentless pressure on the opposition',
        'Midfield trio supports attack while covering centrally',
        'Numerical overload in the final third creates many chances',
      ],
      weaknesses: [
        'Two defenders are significantly exposed to counter-attacks',
        'Midfielders must sprint back the moment possession is lost',
        'High risk if the press is beaten — 3v2 situations emerge quickly',
      ],
      coachTips: [
        'Both CBs must be your best 1v1 defenders — they will face lots of direct duels',
        'One midfielder must always stay back to protect the CBs',
        'Wingers press the opposition CBs high and aggressively at all times',
        'Use only when your team is technically and physically dominant',
      ],
      keyRoles: 'Both CBs must be elite 1v1 defenders. The "holding CM" is the critical defensive cover.',
    ),

    // ── 6v6 ───────────────────────────────────────────────────────────────
    '2-2-1': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'The most common 6-aside formation. Two defensive blocks with a lone striker create a simple and balanced structure that is easy for players to understand.',
      strengths: [
        'Simple structure — easy to communicate and organise',
        'Equal numbers in defence and midfield',
        'Striker always available for counter-attacks',
      ],
      weaknesses: [
        'No natural width — all play goes through the centre',
        'Single striker is isolated without midfield support',
      ],
      coachTips: [
        'Both CMs must support the striker actively and frequently',
        'Defenders hold the line — resist the urge to step out',
        'At set pieces one CM joins the striker to create a 2v2 in the box',
      ],
      keyRoles: 'CMs are the link between all lines. Striker must be sharp and clinical.',
    ),
    '1-3-1': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'An attacking 6-aside formation with three midfielders and one defender. Midfield dominance is the focus. Only for teams with a dominant defensive organiser.',
      strengths: [
        'Three midfielders control and dominate possession',
        'Wide midfielders provide attacking width',
        'Lone striker receives the ball in good positions regularly',
      ],
      weaknesses: [
        'Single CB carries enormous pressure and responsibility',
        'If midfielders don\'t track back, the CB faces 2v1 situations',
      ],
      coachTips: [
        'The CB must be your best defender — reliable, dominant, and experienced',
        'Wide midfielders must track back to protect the CB when needed',
        'Use against weaker opponents when you need to control the game',
      ],
      keyRoles: 'CB is the most critical player — the entire defence depends on them. Three CMs must be disciplined.',
    ),
    '2-1-2': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'A wide attacking formation for 6-aside with two wingers creating width and a single CM acting as the defensive pivot between the lines.',
      strengths: [
        'Maximum width through two natural wingers',
        'Fast wide attacks create crossing opportunities',
        'CM provides a defensive link to the back two',
      ],
      weaknesses: [
        'Central midfield is exposed when wingers push forward',
        'Single CM is outnumbered against any central overload',
      ],
      coachTips: [
        'Wingers are the main weapon — they must be fast with good 1v1 ability',
        'CM stays disciplined — does not advance far from the defensive line',
        'Defenders can join attacks when the wingers cover back',
      ],
      keyRoles: 'Wingers are the primary attacking force. CM must be disciplined as the defensive anchor.',
    ),

    // ── 5v5 ───────────────────────────────────────────────────────────────
    '2-1-1': _FormationInfo(
      style: 'BALANCED',
      styleColor: 0xFF00E676,
      description: 'The classic 5-aside structure with two defenders, one midfielder, and one striker. Simple, balanced, and effective for all ability levels.',
      strengths: [
        'Clear and simple structure for all players',
        'Two defenders cover the defensive zone solidly',
        'CM bridges defence and attack naturally',
      ],
      weaknesses: [
        'Limited attacking options with only one striker',
        'CM is overloaded — must defend and attack constantly',
      ],
      coachTips: [
        'Striker stays positioned between the opposition\'s two defenders',
        'CM is the most important player — must be two-way and cover all areas',
        'Both CBs hold a compact central zone — no chasing the ball wide',
      ],
      keyRoles: 'CM is the most important player — must cover everything. Striker must be sharp and clinical.',
    ),
    '1-2-1': _FormationInfo(
      style: 'ATTACKING',
      styleColor: 0xFFFF5252,
      description: 'An attacking 5-aside formation with two midfielders providing numerical superiority in the centre and a lone striker finishing. High risk with only one defender.',
      strengths: [
        'Two CMs create a central overload and control possession',
        'Multiple passing options between the lines',
        'Striker receives the ball in advanced positions regularly',
      ],
      weaknesses: [
        'Single CB faces enormous pressure — high individual responsibility',
        'CMs must track back immediately every time possession is lost',
      ],
      coachTips: [
        'CB must be the most reliable and experienced defender — no mistakes allowed',
        'CMs alternate — one attacks, the other covers the CB',
        'Striker stays close to goal and acts as the primary finisher',
      ],
      keyRoles: 'CB must be elite in 1v1 situations. Two CMs must share defensive and creative duties equally.',
    ),
    '3-1': _FormationInfo(
      style: 'DEFENSIVE',
      styleColor: 0xFF2979FF,
      description: 'An ultra-defensive 5-aside formation with three defenders and a lone striker for counter-attacks. Used exclusively to protect a lead or contain a stronger opponent.',
      strengths: [
        'Three-man defensive block is nearly impenetrable',
        'Covers all central and wide defensive areas',
        'Lone striker is a direct counter-attacking weapon',
      ],
      weaknesses: [
        'Almost no attacking play by design — the game is reactive',
        'Striker is completely isolated with no support',
      ],
      coachTips: [
        'Use only when protecting a lead or requiring a draw',
        'Striker must be fast — the counter-attack is the only weapon',
        'Three defenders hold a strict flat line — no one steps out to press',
      ],
      keyRoles: 'Striker must be a fast, explosive counter-attacker. Three CBs must hold shape and communicate constantly.',
    ),
  };

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<_Formation> get _currentFormations => _formationsByFormat[_format]!;

  _FormationInfo get _currentInfo =>
      _info[_selected] ??
      const _FormationInfo(
        style: 'BALANCED',
        styleColor: 0xFF00E676,
        description: '',
        strengths: [],
        weaknesses: [],
        coachTips: [],
        keyRoles: '',
      );

  // ─── Build ────────────────────────────────────────────────────────────────

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
          SliverToBoxAdapter(child: _buildInfoCard(title: 'STRENGTHS', icon: Icons.trending_up_rounded, color: PremiumTheme.neonGreen, items: info.strengths)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildInfoCard(title: 'WEAKNESSES', icon: Icons.trending_down_rounded, color: PremiumTheme.danger, items: info.weaknesses)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildInfoCard(title: 'COACH TIPS', icon: Icons.lightbulb_rounded, color: Colors.amber, items: info.coachTips)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildKeyRoles(info)),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

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
              Text('COACH · TACTICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: onSurface.withValues(alpha: 0.5), letterSpacing: 2)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Selectors ────────────────────────────────────────────────────────────

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

  // ─── Style badge ──────────────────────────────────────────────────────────

  Widget _buildStyleBadge(_FormationInfo info) {
    final color = Color(info.styleColor);
    final icon = info.style == 'ATTACKING'
        ? Icons.arrow_upward_rounded
        : info.style == 'DEFENSIVE'
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
                Text(info.style, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
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

  // ─── Pitch ────────────────────────────────────────────────────────────────

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

  // ─── Info panels ──────────────────────────────────────────────────────────

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
              child: Text(info.description, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5)),
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
                Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 5, right: 10), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.4))),
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
                  const Text('KEY ROLES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: PremiumTheme.electricBlue, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text(info.keyRoles, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────────────

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
