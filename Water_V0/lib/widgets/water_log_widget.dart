import 'package:flutter/material.dart';

class WaterLogWidget extends StatelessWidget {
  WaterLogWidget({Key? key}) : super(key: key);

  final List<WaterEntry> _entries = [
    WaterEntry(time: '08:30', amount: 250, icon: Icons.water_drop),
    WaterEntry(time: '10:15', amount: 500, icon: Icons.water),
    WaterEntry(time: '12:45', amount: 250, icon: Icons.water_drop),
    WaterEntry(time: '15:20', amount: 200, icon: Icons.local_drink),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _entries.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.2),
          indent: 70,
        ),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                entry.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              '${entry.amount} ml',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              entry.time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }
}

class WaterEntry {
  final String time;
  final int amount;
  final IconData icon;

  WaterEntry({
    required this.time,
    required this.amount,
    required this.icon,
  });
}

