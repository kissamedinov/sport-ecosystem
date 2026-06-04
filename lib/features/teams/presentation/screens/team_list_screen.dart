import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TeamListScreen extends StatelessWidget {
  const TeamListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('team.my_teams'.tr())),
      body: Center(child: Text('team.team_coming_soon'.tr())),
    );
  }
}
