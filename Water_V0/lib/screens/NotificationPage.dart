import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'dart:convert';
import 'InviteMemberPage.dart';
import 'login_screen.dart'; // <-- Import your login screen

class NotificationPage extends StatefulWidget {
  final String userEmail;
  final bool isMember; // <-- Pass true if member!

  const NotificationPage({
    super.key,
    required this.userEmail,
    this.isMember = false,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];

  Future<void> fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:5000/get_notifications?userId=${widget.userEmail}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['notifications'] is List) {
          setState(() {
            notifications = data['notifications'];
          });
        } else {
          setState(() {
            notifications = [];
          });
        }
      }
    } catch (e) {
      setState(() {
        notifications = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Logout icon
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(
                Icons.exit_to_app,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
      body:
          notifications.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    tileColor:
                        notif['status'] == 'pending'
                            ? Colors.blue.withOpacity(0.08)
                            : Colors.white,
                    title: Text(
                      notif['title'] ?? notif['message'] ?? '',
                      style: TextStyle(
                        fontWeight:
                            notif['status'] == 'pending'
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                    onTap: () async {
                      // Mark as vued BEFORE opening detail
                      if (notif['status'] == 'pending') {
                        await http.post(
                          Uri.parse(
                            'http://127.0.0.1:5000/mark_notification_vued',
                          ),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode({"notificationId": notif['id']}),
                        );
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => NotificationDetailPage(
                                notification: notif,
                                userEmail: widget.userEmail,
                                isMember: widget.isMember,
                                onAction: fetchNotifications,
                              ),
                        ),
                      );
                      fetchNotifications();
                    },
                  );
                },
              ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String userEmail;
  final bool isMember;
  final VoidCallback? onAction;

  const NotificationDetailPage({
    Key? key,
    required this.notification,
    required this.userEmail,
    required this.isMember,
    this.onAction,
  }) : super(key: key);

  Future<void> _memberRespondInvitation(
    BuildContext context,
    String action,
  ) async {
    final chefEmail = notification["senderId"];
    final notifId = notification["id"];
    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/invitation_action"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "memberEmail": userEmail,
        "chefEmail": chefEmail,
        "action": action, // "accept" or "ignore"
        "notificationId": notifId,
      }),
    );
    Navigator.pop(context);
    if (onAction != null) onAction!();
    // Optionally: show a snackbar or dialog for feedback
  }

  @override
  Widget build(BuildContext context) {
    final isInviteNotif =
        ((notification['type'] ?? '').toLowerCase() == 'invitation') ||
        ((notification['title'] ?? '').toLowerCase().contains('invitation'));

    return Scaffold(
      appBar: AppBar(
        title: Text(notification['title'] ?? "Détail de la notification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "Reçue le : ${notification['createdAt'] ?? ''}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // CHEF: Show invite family button
            if (isInviteNotif && !isMember)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => InviteMemberPage(chefEmail: userEmail),
                    ),
                  );
                },
                child: const Text("Inviter un membre"),
              ),
            // MEMBER: Show accept/ignore buttons
            if (isInviteNotif &&
                isMember &&
                (notification['status'] == 'pending')) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed:
                          () => _memberRespondInvitation(context, "accept"),
                      child: const Text("Accepter"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed:
                          () => _memberRespondInvitation(context, "ignore"),
                      child: const Text("Ignorer"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
       bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: '',
        isChef: true,
        onTap: (i) {/* à gérer si besoin */},
      ),
    );
  }
}
