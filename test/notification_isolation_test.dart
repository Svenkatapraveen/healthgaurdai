import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1healthgaurdai/services/db_service.dart';

void main() {
  group('Notification Isolation Tests', () {
    late MockDbService dbService;

    setUp(() {
      dbService = MockDbService();
    });

    test('User A sees only User A notifications and not User B notifications', () async {
      const userA = 'uid_user_A_123';
      const userB = 'uid_user_B_456';

      await dbService.addNotification(NotificationModel(
        id: 'notif_a1',
        userId: userA,
        title: 'User A Appointment',
        body: 'Appointment for User A',
        timestamp: DateTime.now(),
        category: 'Appointment',
      ));

      await dbService.addNotification(NotificationModel(
        id: 'notif_b1',
        userId: userB,
        title: 'User B Alert',
        body: 'Alert for User B',
        timestamp: DateTime.now(),
        category: 'Alert',
      ));

      final notifsA = await dbService.getNotifications(userA);
      final notifsB = await dbService.getNotifications(userB);

      // Verify User A notifications
      expect(notifsA.any((n) => n.userId == userA), isTrue);
      expect(notifsA.any((n) => n.userId == userB), isFalse);
      expect(notifsA.length, equals(1));
      expect(notifsA.first.title, equals('User A Appointment'));

      // Verify User B notifications
      expect(notifsB.any((n) => n.userId == userB), isTrue);
      expect(notifsB.any((n) => n.userId == userA), isFalse);
      expect(notifsB.length, equals(1));
      expect(notifsB.first.title, equals('User B Alert'));
    });

    test('Notification mark as read updates only target notification', () async {
      const userA = 'uid_user_A_123';

      final notif = NotificationModel(
        id: 'notif_unread_1',
        userId: userA,
        title: 'Unread Alert',
        body: 'Test body',
        timestamp: DateTime.now(),
        category: 'Alert',
        isRead: false,
      );

      await dbService.addNotification(notif);

      var listBefore = await dbService.getNotifications(userA);
      expect(listBefore.first.isRead, isFalse);

      await dbService.markNotificationAsRead('notif_unread_1');

      var listAfter = await dbService.getNotifications(userA);
      expect(listAfter.first.isRead, isTrue);
    });
  });
}
