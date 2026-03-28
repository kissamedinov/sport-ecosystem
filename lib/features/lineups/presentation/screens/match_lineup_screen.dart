import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_client.dart';
import '../widgets/player_card.dart';
import '../../models/player_lineup_model.dart';

class MatchLineupScreen extends StatefulWidget {
  final String matchId;
  final String teamId;

  const MatchLineupScreen({
    super.key,
    required this.matchId,
    required this.teamId,
  });

  @override
  State<MatchLineupScreen> createState() => _MatchLineupScreenState();
}

class _MatchLineupScreenState extends State<MatchLineupScreen> {
  List<PlayerLineupModel> _players = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = context.read<ApiClient>();
      final response = await apiClient.get('/teams/${widget.teamId}/players');
      
      if (response.data is List) {
        final List<dynamic> data = response.data;
        setState(() {
          _players = data.map((item) {
            final playerInfo = item['player'];
            return PlayerLineupModel(
              id: playerInfo['id'],
              name: playerInfo['name'],
              isStarting: false,
              position: null,
            );
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load players: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLineup() async {
    final starters = _players.where((p) => p.isStarting).toList();

    // Validation
    if (starters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least 1 starting player is required'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (starters.any((p) => p.position == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign positions for all starting players'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = context.read<ApiClient>();
      final payload = {
        'team_id': widget.teamId,
        'players': starters.map((p) => p.toJson()).toList(),
      };

      await apiClient.post('/matches/${widget.matchId}/lineup', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lineup submitted successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int startingCount = _players.where((p) => p.isStarting).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lineup Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('$startingCount Starting Players', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(onPressed: _fetchPlayers, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _players.length,
            padding: const EdgeInsets.only(bottom: 100),
            itemBuilder: (context, index) {
              final player = _players[index];
              return PlayerCard(
                player: player,
                onStartingChanged: (value) {
                  setState(() => player.isStarting = value);
                },
                onPositionChanged: (value) {
                  setState(() => player.position = value);
                },
              );
            },
          ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitLineup,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('SUBMIT LINEUP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
