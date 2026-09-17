class ApiEndpoints {
  // Base URL
//  static const String baseUrl = 'https://sundari.bonanso.com';
  static const String baseUrl = 'https://sundari.checkour.work';

  // Auth
  static const String authRegister = '/auth/register/';
  static const String authLogin = '/auth/login/';
  static const String authEmailOtpRequest = '/auth/email-otp/request/';
  static const String authEmailOtpVerify = '/auth/email-otp/verify/';
  static const String authPhoneOtpRequest = '/auth/phone-otp/request/';
  static const String authPhoneOtpVerify = '/auth/phone-otp/verify/';
  static const String authGoogle = '/auth/google/';
  static const String authTokenRefresh = '/auth/token/refresh/';

  // Artists - Profile
  static const String artistsProfileGet = '/artists/profile/get/';
  static const String artistsProfileUpdate = '/artists/profile/update/';

  // Artists - Portfolio
  static const String artistsPortfolioCreate = '/artists/portfolio/create/';
  static const String artistsPortfolioGet = '/artists/portfolio/get/';
  static const String artistsPortfolioGetAll = '/artists/portfolio/get_all/';
  static const String artistsPortfolioUpdate = '/artists/portfolio/update/';
  static const String artistsPortfolioDelete = '/artists/portfolio/delete/';

  // Artists - Packages
  static const String artistsPackagesCreate = '/artists/packages/create/';
  static const String artistsPackagesGet = '/artists/packages/get/';
  static const String artistsPackagesGetAll = '/artists/packages/get_all/';
  static const String artistsPackagesUpdate = '/artists/packages/update/';
  static const String artistsPackagesDelete = '/artists/packages/delete/';

  // Artists - Services
  static const String artistsServicesAdd = '/artists/services/add/';
  static const String artistsServicesGetAll = '/artists/services/get_all/';
  static const String artistsServicesRemove = '/artists/services/remove/';

  // Artists - Locations
  static const String artistsLocationsAdd = '/artists/locations/add/';
  static const String artistsLocationsGetAll = '/artists/locations/get_all/';
  static const String artistsLocationsRemove = '/artists/locations/remove/';

  // Artists - Availability
  static const String artistsAvailabilityScheduleSet = '/artists/availability/schedule/set/';
  static const String artistsAvailabilityScheduleGetAll = '/artists/availability/schedule/get_all/';
  static const String artistsAvailabilityScheduleRemove = '/artists/availability/schedule/remove/';
  static const String artistsAvailabilityBlockAdd = '/artists/availability/block/add/';
  static const String artistsAvailabilityBlockGetAll = '/artists/availability/block/get_all/';
  static const String artistsAvailabilityBlockRemove = '/artists/availability/block/remove/';

  // Users - Profile
  static const String usersProfileGet = '/users/profile/get/';
  static const String usersProfileUpdate = '/users/profile/update/';

  // Users - Address
  static const String usersAddressCreate = '/users/address/create/';
  static const String usersAddressGet = '/users/address/get/';
  static const String usersAddressGetAll = '/users/address/get_all/';
  static const String usersAddressUpdate = '/users/address/update/';
  static const String usersAddressDelete = '/users/address/delete/';

  // Core
  static const String coreApprovalStatusGetAll = '/core/approval-status/get_all/';
  static const String coreBookingStatusGetAll = '/core/booking-status/get_all/';
  static const String corePaymentStatusGetAll = '/core/payment-status/get_all/';
  static const String coreLocationTypeGet = '/core/location-type/get/';
  static const String coreLocationTypeGetAll = '/core/location-type/get_all/';
  static const String coreServiceCategoryGet = '/core/service-category/get/';
  static const String coreServiceCategoryGetAll = '/core/service-category/get_all/';
  static const String coreServiceSubCategoryGet = '/core/service-sub-category/get/';
  static const String coreServiceSubCategoryGetAll = '/core/service-sub-category/get_all/';

  // Schema
  static const String apiSchema = '/api/schema/';

  // ── Artist Bookings ─────────────────────────────────────────────────
  static const String artistBookingsGet = '/artists/bookings/get/';
  static const String artistBookingsGetAll = '/artists/bookings/get_all/';
  static const String artistBookingsUpdateStatus = '/artists/bookings/update_status/';
  static const String artistBookingsOnMyWay = '/artists/bookings/on_my_way/';
  static const String artistBookingsArrived = '/artists/bookings/arrived/';
  static const String artistBookingsStartPinVerify = '/artists/bookings/start_pin/verify/';
  static const String artistBookingsCompletionPinVerify = '/artists/bookings/completion_pin/verify/';

  // ── Notifications ───────────────────────────────────────────────────
  static const String notificationsGet = '/notifications/get/';
  static const String notificationsGetAll = '/notifications/get_all/';
  static const String notificationsMarkRead = '/notifications/mark_read/';
  static const String notificationsMarkAllRead = '/notifications/mark_all_read/';

  // ── Chat ─────────────────────────────────────────────────────────────
  static const String chatConversationGet = '/chat/conversation/get/';
  static const String chatMessagesGetAll = '/chat/messages/get_all/';
  static const String chatMessagesCreate = '/chat/messages/create/';

  // ── Help Center ──────────────────────────────────────────────────────
  static const String helpCenterConversationGet = '/help_center/conversation/get/';
  static const String helpCenterMessagesGetAll = '/help_center/messages/get_all/';
  static const String helpCenterMessagesCreate = '/help_center/messages/create/';
}
