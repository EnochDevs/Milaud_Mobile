import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:may_laud/providers/content_providers.dart';

void main() {
  group('Announcement Model Tests', () {
    test('Announcement.fromJson should parse valid JSON', () {
      // Arrange — keys match a `announcements` row from Supabase (see
      // Announcement.fromJson in content_providers.dart).
      final json = {
        'id': 'announcement-123',
        'title': 'Town Hall Meeting',
        'description': 'Monthly town hall meeting for all residents',
        'category': 'Government',
        'created_at': '2024-03-15T14:30:00.000Z',
        'image_url': 'https://example.com/image.jpg',
        'is_important': true,
        'is_read': false,
      };

      // Act
      final announcement = Announcement.fromJson(json);

      // Assert
      expect(announcement.id, 'announcement-123');
      expect(announcement.title, 'Town Hall Meeting');
      expect(announcement.description,
          'Monthly town hall meeting for all residents');
      expect(announcement.category, 'Government');
      // fromJson() converts the UTC created_at to local time before
      // storing it, so compare via isAtSameMomentAs rather than ==.
      expect(announcement.date
          .isAtSameMomentAs(DateTime.parse(json['created_at'] as String)), true);
      expect(announcement.imageUrl, 'https://example.com/image.jpg');
      expect(announcement.isImportant, true);
      expect(announcement.isRead, false);
    });

    test('formattedDate should return correct format', () {
      // Arrange
      final announcement = Announcement(
        id: 'test',
        title: 'Test',
        description: 'Test',
        category: 'Test',
        date: DateTime.utc(2024, 3, 15, 14, 30),
      );

      // Act
      final formatted = announcement.formattedDate;

      // Assert
      expect(formatted, contains('Mar 15, 2024'));
    });

    test('copyWith should update isRead while preserving other fields', () {
      // Arrange
      final original = Announcement(
        id: 'original',
        title: 'Original Title',
        description: 'Original Description',
        category: 'General',
        date: DateTime.utc(2024, 1, 1),
        isImportant: false,
        isRead: false,
      );

      // Act — Announcement.copyWith only supports overriding `isRead`
      // (see content_providers.dart); every other field always carries
      // over unchanged.
      final updated = original.copyWith(isRead: true);

      // Assert
      expect(updated.id, 'original');
      expect(updated.title, 'Original Title');
      expect(updated.description, 'Original Description');
      expect(updated.category, 'General');
      expect(updated.date, DateTime.utc(2024, 1, 1));
      expect(updated.isImportant, false);
      expect(updated.isRead, true);
    });
  });

  group('AppNotification Model Tests', () {
    test('AppNotification.fromJson should parse valid JSON', () {
      // Arrange — keys match a `notifications` row from Supabase (see
      // AppNotification.fromJson in content_providers.dart).
      final json = {
        'id': 'notification-123',
        'title': 'New Announcement',
        'message': 'A new town hall meeting has been scheduled',
        'created_at': '2024-03-15T10:00:00.000Z',
        'type': 'announcement',
        'is_read': false,
        'data': {'announcementId': 'announcement-123'},
      };

      // Act
      final notification = AppNotification.fromJson(json);

      // Assert
      expect(notification.id, 'notification-123');
      expect(notification.title, 'New Announcement');
      expect(
          notification.message, 'A new town hall meeting has been scheduled');
      expect(notification.timestamp, DateTime.utc(2024, 3, 15, 10, 0));
      expect(notification.type, 'announcement');
      expect(notification.isRead, false);
      expect(notification.data?['announcementId'], 'announcement-123');
    });

    test('copyWith should update isRead while preserving other fields', () {
      // Arrange
      final original = AppNotification(
        id: 'test',
        title: 'Test',
        message: 'Test',
        timestamp: DateTime.utc(2024, 3, 15, 10, 0),
        type: 'announcement',
        isRead: false,
      );

      // Act
      final updated = original.copyWith(isRead: true);

      // Assert
      expect(updated.id, 'test');
      expect(updated.title, 'Test');
      expect(updated.isRead, true);
    });
  });

  group('Content Providers Tests', () {
    // NOTE — announcementsProvider/notificationsProvider now fetch their
    // initial data from Supabase on construction (see
    // AnnouncementsProvider/NotificationsProvider in
    // content_providers.dart), which this test process never connects
    // to (Supabase.initialize() is never called here), so they start —
    // and, absent a live backend, stay — empty rather than preloaded
    // with fixture data. Each test below seeds what it needs directly
    // through the notifier's local mutators (addAnnouncement /
    // addNotification) instead of assuming data is already there.
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('addAnnouncement should increase announcements count', () {
      final notifier = container.read(announcementsProvider.notifier);
      final initialCount = container.read(announcementsProvider).length;

      notifier.addAnnouncement(Announcement(
        id: 'test-new-announcement',
        title: 'Test Announcement',
        description: 'Test Description',
        category: 'Test',
        date: DateTime.now(),
      ));

      final updatedCount = container.read(announcementsProvider).length;
      expect(updatedCount, initialCount + 1);
    });

    test('addNotification should increase notifications count', () {
      final notifier = container.read(notificationsProvider.notifier);
      final initialCount = container.read(notificationsProvider).length;

      notifier.addNotification(AppNotification(
        id: 'test-new-notification',
        title: 'Test Notification',
        message: 'Test Message',
        timestamp: DateTime.now(),
        type: 'test',
      ));

      final updatedCount = container.read(notificationsProvider).length;
      expect(updatedCount, initialCount + 1);
    });

    test('unreadNotificationsCountProvider should count unread notifications',
        () {
      final notifier = container.read(notificationsProvider.notifier);
      notifier.addNotification(AppNotification(
        id: 'n1',
        title: 'Read one',
        message: '-',
        timestamp: DateTime.now(),
        type: 'system',
        isRead: true,
      ));
      notifier.addNotification(AppNotification(
        id: 'n2',
        title: 'Unread one',
        message: '-',
        timestamp: DateTime.now(),
        type: 'system',
        isRead: false,
      ));

      final count = container.read(unreadNotificationsCountProvider);
      expect(count, 1);
    });

    test(
        'importantAnnouncementsProvider should filter important announcements',
        () {
      final notifier = container.read(announcementsProvider.notifier);
      notifier.addAnnouncement(Announcement(
        id: 'a1',
        title: 'Important',
        description: '-',
        category: 'Test',
        date: DateTime.now(),
        isImportant: true,
      ));
      notifier.addAnnouncement(Announcement(
        id: 'a2',
        title: 'Regular',
        description: '-',
        category: 'Test',
        date: DateTime.now(),
        isImportant: false,
      ));

      final importantAnnouncements =
          container.read(importantAnnouncementsProvider);

      expect(importantAnnouncements.length, 1);
      expect(importantAnnouncements.first.id, 'a1');
    });
  });
}
