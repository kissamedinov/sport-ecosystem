import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/academies/data/models/academy.dart';
import 'package:mobile/features/academies/presentation/screens/academy_details_screen.dart';

class AcademyListItem extends StatelessWidget {
  final Academy academy;

  const AcademyListItem({super.key, required this.academy});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AcademyDetailsScreen(academy: academy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${academy.city}, ${academy.address}',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          context,
                          Icons.group,
                          '${academy.teamsCount ?? 0} Teams',
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          context,
                          Icons.person,
                          '${academy.playersCount ?? 0} Players',
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: academy.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Academy ID copied to clipboard'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      child: Text(
                        'ID: ${academy.id.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
