import 'package:flutter/material.dart';
import '../../data/models/tournament.dart';

class TournamentDetailsScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentDetailsScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tournament.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tournament.logoUrl != null)
              Center(
                child: Image.network(
                  tournament.logoUrl!,
                  height: 150,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              tournament.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Text(tournament.location),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text('${tournament.startDate} - ${tournament.endDate}'),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Format: ${tournament.format}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Category: ${tournament.ageCategory}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Register logic
                },
                child: const Text('Register for Tournament'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
