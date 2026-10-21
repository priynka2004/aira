// FILE: utils/service_locator.dart
// Creates and holds all services once at startup: ServiceLocator.artistService, .authService, etc.

import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../api/artist_service.dart';
import '../api/artist_business_service.dart';
import '../api/user_service.dart';
import '../api/core_service.dart';
import '../api/booking_service.dart';
import '../api/notification_service.dart';
import '../api/local_notification_builder.dart';
import '../api/chat_service.dart';
import '../api/help_center_service.dart';
import '../api/booking_journey_service.dart';
import '../api/reschedule_service.dart';
import '../services/firestore_notification_service.dart';

/// Single place to access every service (ServiceLocator.xyzService).
class ServiceLocator {
  ServiceLocator._();

  static late final ApiService    apiService;
  static late final AuthService   authService;
  static late final ArtistService artistService;
  static late final ArtistBusinessService artistBusiness;
  static late final UserService   userService;
  static late final CoreService   coreService;
  static late final BookingService bookingService;
  static late final BookingJourneyService bookingJourneyService;
  static late final RescheduleService rescheduleService;
  static late final NotificationService notificationService;
  static late final LocalNotificationBuilder localNotificationBuilder;
  static late final ChatService chatService;
  static late final HelpCenterService helpCenterService;
  static late final FirestoreNotificationService firestoreNotificationService;
  static late final FirestoreBookingService firestoreBookingService;

  /// Creates all services (called once from main()).
  static void init() {
    apiService    = ApiService();
    authService   = AuthService(apiService);
    artistService = ArtistService(apiService);
    artistBusiness = ArtistBusinessService(apiService);
    userService   = UserService(apiService);
    coreService   = CoreService(apiService);
    bookingService = BookingService(apiService);
    bookingJourneyService = BookingJourneyService(apiService);
    rescheduleService = RescheduleService();
    notificationService = NotificationService(apiService);
    chatService = ChatService(apiService);
    helpCenterService = HelpCenterService(apiService);
    localNotificationBuilder =
        LocalNotificationBuilder(apiService, bookingService, chatService, helpCenterService);
    firestoreNotificationService = FirestoreNotificationService();
    firestoreBookingService = FirestoreBookingService();
  }
}
