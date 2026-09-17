import '../api/api_service.dart';
import '../api/auth_service.dart';
import '../api/artist_service.dart';
import '../api/user_service.dart';
import '../api/core_service.dart';
import '../api/booking_service.dart';
import '../api/notification_service.dart';
import '../api/local_notification_builder.dart';
import '../api/chat_service.dart';
import '../api/help_center_service.dart';
import '../api/booking_journey_service.dart';
import '../services/firestore_notification_service.dart';

/// Simple service locator – call [ServiceLocator.init] once in main().
class ServiceLocator {
  ServiceLocator._();

  static late final ApiService    apiService;
  static late final AuthService   authService;
  static late final ArtistService artistService;
  static late final UserService   userService;
  static late final CoreService   coreService;
  static late final BookingService bookingService;
  static late final BookingJourneyService bookingJourneyService;
  static late final NotificationService notificationService;
  static late final LocalNotificationBuilder localNotificationBuilder;
  static late final ChatService chatService;
  static late final HelpCenterService helpCenterService;
  static late final FirestoreNotificationService firestoreNotificationService;
  static late final FirestoreBookingService firestoreBookingService;

  static void init() {
    apiService    = ApiService();
    authService   = AuthService(apiService);
    artistService = ArtistService(apiService);
    userService   = UserService(apiService);
    coreService   = CoreService(apiService);
    bookingService = BookingService(apiService);
    bookingJourneyService = BookingJourneyService(apiService);
    notificationService = NotificationService(apiService);
    chatService = ChatService(apiService);
    helpCenterService = HelpCenterService(apiService);
    // Builds the notification list on-device instead of relying on
    // GET /notifications/get_all/, which currently always reports every
    // item as failed with "FCM not yet configured".
    localNotificationBuilder =
        LocalNotificationBuilder(apiService, bookingService, chatService, helpCenterService);
    firestoreNotificationService = FirestoreNotificationService();
    firestoreBookingService = FirestoreBookingService();
  }
}
