
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../models/challenge_provider.dart';
import '../widgets/input_widgets.dart';
import 'package:water_v0/screens/recup_id_famille.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({
    Key? key,
    required this.challenge,
  }) : super(key: key);

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  String? _userInput;
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, String> completedHabits = {};
  Map<String, String> completedSocio = {};
  String? userId;

  @override
  void initState() {
    super.initState();
    _userInput = widget.challenge.userInput;
    _loadUserIdAndFetchData();
  }

  Future<void> _loadUserIdAndFetchData() async {
    userId = await getIdUSer();
    await fetchCompletedHabits();
    await fetchSocioData();
  }

  Future<void> fetchCompletedHabits() async {
  if (userId == null) return;
  setState(() => _isLoading = true);
  final url = Uri.parse('http://127.0.0.1:5000/get_completed_habits');
  try {
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      setState(() {
        completedHabits = {
          for (var item in data)
            item['id'].toString(): item['valeur'].toString()
        };
        // **nouveau** : on recharge _userInput si on a déjà une réponse stockée
        final lastValue = completedHabits[widget.challenge.id];
        if (lastValue != null) {
          _userInput = lastValue;
        }
      });
    }
  } catch (e) {
    print('Error fetching habits: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> fetchSocioData() async {
    if (userId == null) return;
    setState(() => _isLoading = true);
    final url = Uri.parse('http://127.0.0.1:5000/get_socio');
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
      setState(() {
  completedSocio = {
    for (var item in data)
      item['id'].toString(): item['valeur'].toString()
  };
  final lastValue = completedSocio[widget.challenge.id];
  if (lastValue != null) {
    _userInput = lastValue;
  }
});

      }
    } catch (e) {
      print('Error fetching socio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateInput(String value) {
    setState(() => _userInput = value);
  }

  Future<void> _submitChallenge() async {
    if (_userInput == null || _userInput!.isEmpty || userId == null) return;
    setState(() => _isSubmitting = true);

    final provider = Provider.of<ChallengeProvider>(context, listen: false);
    provider.updateChallenge(widget.challenge.id, _userInput!);

    final path = widget.challenge.category == 'sociodemographic'
      ? 'http://127.0.0.1:5000/socio'
      : 'http://127.0.0.1:5000/habits';
    final payload = {
      'id': widget.challenge.id,
      'category': widget.challenge.category,
      'value': _userInput,
      'points': widget.challenge.points,
      'user_id': userId,
    };

    try {
      final response = await http.post(
        Uri.parse(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        // Après soumission réussie, rafraîchir les dernières données
        await fetchCompletedHabits();
        await fetchSocioData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge réussi ! +${widget.challenge.points} points'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      } else {
        print('Erreur POST: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur réseau: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.challenge.title, style: Theme.of(context).textTheme.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(widget.challenge.icon, color: Theme.of(context).colorScheme.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(child: Text(widget.challenge.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [const Icon(Icons.star, color: Colors.white, size: 16), const SizedBox(width: 4), Text('${widget.challenge.points}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(widget.challenge.description, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Your Response', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                InputWidget(
                  challenge: widget.                                  challenge,
                  value: _userInput,
                  onChanged: _updateInput,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_userInput == null || _userInput!.isEmpty || _isSubmitting) ? null : _submitChallenge,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : widget.challenge.isCompleted ? const Text('Challenge Completed') : const Text('Submit Challenge'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
