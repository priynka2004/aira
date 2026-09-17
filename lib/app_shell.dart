import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/models.dart';
import 'theme/tokens.dart';
import 'widgets/common.dart';
import 'screens/home_screen.dart';
import 'screens/business_screen.dart';
import 'screens/grow_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'utils/service_locator.dart';
import 'utils/app_session.dart';
import 'utils/app_feedback.dart';
import 'utils/notification_badge.dart';
import 'services/push_notification_service.dart';
import 'api/help_center_notifier.dart';
import 'utils/autostart_helper.dart';
import 'models/artist/artist_profile.dart';
import 'models/booking/booking.dart';
import 'models/core/status_item.dart';
import 'models/artist/create_portfolio.dart';
import 'models/enums/media_type_enum.dart';
import 'helper/booking_stats.dart';

/// Root widget — owns all shared state (current screen, sub-tabs, booking
/// slots, toast) and the real Sunndari data: artist profile + bookings,
/// fetched from the API and fed down into each screen.
class AiraAppShell extends StatefulWidget {
  const AiraAppShell({super.key});

  @override
  State<AiraAppShell> createState() => _AiraAppShellState();
}

class _AiraAppShellState extends State<AiraAppShell> {
  String _screen = 'home'; // home | business | grow | learn | profile
  String _businessTab = 'insights';
  String _growTab = 'marketing';
  String? _toast;
  Timer? _toastTimer;

  // ── Real data, loaded from the Sunndari API ────────────────────────────
  bool _loading = true;
  ArtistProfile? _profile;
  List<Booking> _bookings = [];
  List<StatusItem> _bookingStatuses = [];
  bool _hasClash = false;
  // Live Firestore listener — keeps [_bookings] in sync the instant the
  // backend writes a booking change to `bookings/<bookingId>`, without
  // waiting for a manual reload. Additive to the REST load above, same
  // pattern as [PushNotificationService]'s Firestore badge listener.
  StreamSubscription<List<Booking>>? _bookingsSub;
  // customerId → real display name (from GET /users/profile/get/), so the
  // booking list, chat app bar, etc show the actual customer instead of a
  // static "Customer #<id>" placeholder. Filled in best-effort after
  // bookings load; falls back to the id-based label per-customer until
  // (or if) that lookup resolves.
  final Map<int, String> _customerNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    // Reached right after login *and* on every relaunch with a saved
    // session (splash screen routes straight here) — the one place we're
    // guaranteed to be logged in, so it's the right spot to register for
    // push notifications and sync the current unread state.
    PushNotificationService.instance.initMessaging();
    HelpCenterNotifier.instance.start(ServiceLocator.apiService);
    NotificationBadge.instance.refresh();
    // Post-frame so `context` is safely mounted for the dialog — this is a
    // one-time prompt (see AutostartHelper), no-ops after the first run.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AutostartHelper.promptIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  /// Subscribes to this artist's live bookings in Firestore
  /// (`bookings` collection, filtered by `artistId`) and keeps
  /// [_bookings] up to date in real time. Runs alongside the REST load
  /// in [_loadData] — whichever source updates first wins on screen;
  /// there's nothing to reconcile since the backend is expected to keep
  /// both in sync.
  ///
  /// Merges into the existing REST-loaded list by `bookingId` rather than
  /// replacing it outright. The Firestore mirror can lag behind or not
  /// yet cover every historical booking (see the "known gap" notes on
  /// this collection), so a live snapshot is often a strict *subset* of
  /// what REST already returned — blindly replacing [_bookings] with
  /// that subset used to silently wipe every booking Firestore hadn't
  /// caught up on yet, leaving the screen blank a moment after the real
  /// data had already rendered. Merging means a live update can only add
  /// or refresh bookings, never make correctly-loaded ones disappear.
  ///
  /// [artistId] must be the artist-table id (e.g. `Booking.artistId`,
  /// `ArtistProfile.artistId`) — NOT [AppSession.instance.userId]. Those
  /// are two different ids for the same person (this account is
  /// `userId=8` but `artistId=5`); passing the wrong one silently matches
  /// zero real bookings and, if some other doc coincidentally has that
  /// value, can pull in a stray customerId that doesn't correspond to an
  /// actual user (seen as a spurious 400 on
  /// GET /users/profile/get/?user_id=<wrong-id> from [_loadCustomerNames]).
  void _listenForLiveBookings(int artistId) {
    _bookingsSub?.cancel();
    _bookingsSub = ServiceLocator.firestoreBookingService
        .artistBookingsStream(artistId)
        .listen(
          (liveBookings) {
        if (!mounted || liveBookings.isEmpty) return;
        final merged = {for (final b in _bookings) b.bookingId: b};
        for (final b in liveBookings) {
          final existing = merged[b.bookingId];
          if (existing == null) {
            // A booking REST hasn't shown us yet — worth adding even if
            // the Firestore copy turns out to be imperfect; there's no
            // good REST copy to protect here.
            merged[b.bookingId] = b;
            continue;
          }
          if (_isNewerOrEqual(b, existing)) {
            merged[b.bookingId] = _mergeLiveFields(existing, b);
          }
        }
        final bookings = merged.values.toList()
          ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
        if (kDebugMode) {
          final todayCount = BookingStats(bookings, _bookingStatuses).todaysAppointments.length;
          debugPrint('[Dashboard] Firestore live merge: incoming=${liveBookings.length}, '
              'merged_total=${bookings.length}, today=$todayCount');
        }
        setState(() {
          _bookings = bookings;
          _hasClash = _detectClash(bookings, _bookingStatuses);
        });
        _loadCustomerNames(bookings);
      },
      onError: (e) {
        if (kDebugMode) debugPrint('[AppShell] live bookings listener error: $e');
      },
    );
  }

  /// True if [candidate]'s `updatedAt` is newer than or equal to
  /// [current]'s — or if either timestamp is unparseable, in which case
  /// we conservatively let the candidate through rather than get stuck
  /// never updating (matches the old behaviour for that edge case only).
  bool _isNewerOrEqual(Booking candidate, Booking current) {
    final a = DateTime.tryParse(candidate.updatedAt ?? '');
    final b = DateTime.tryParse(current.updatedAt ?? '');
    if (a == null || b == null) return true;
    return !a.isBefore(b);
  }

  /// Takes only the fields that are genuinely meant to change live —
  /// `statusId` and the cancellation info that comes with it — from the
  /// Firestore copy [live], and keeps every other field (crucially
  /// `bookingDate`/`startTime`/`endTime`/`totalAmount`) from the
  /// already-correct [rest] copy.
  ///
  /// The Firestore `bookings` mirror has been seen holding a genuinely
  /// **stale but validly-formatted** `bookingDate` for a booking that was
  /// rescheduled after the mirror doc was written (e.g. REST correctly
  /// shows `2026-08-21` while the same doc in Firestore still says
  /// `2026-08-17`). That's not a missing/malformed value — it's wrong but
  /// perfectly parseable — so no amount of validating the *shape* of the
  /// Firestore data can catch it. The only reliable fix is to simply never
  /// let Firestore's date/time/amount fields overwrite REST's for a
  /// booking REST already loaded correctly. This is what silently shifted
  /// "today's bookings" (and the dashboard numbers built from it) from the
  /// right value down to 0 the instant this live listener fired.
  Booking _mergeLiveFields(Booking rest, Booking live) {
    return Booking(
      bookingId: rest.bookingId,
      customerId: rest.customerId,
      artistId: rest.artistId,
      subCategoryId: rest.subCategoryId,
      packageId: rest.packageId,
      locationTypeId: rest.locationTypeId,
      addressId: rest.addressId,
      bookingDate: rest.bookingDate,
      startTime: rest.startTime,
      endTime: rest.endTime,
      statusId: live.statusId,
      totalAmount: rest.totalAmount,
      notes: rest.notes,
      cancelledBy: live.cancelledBy ?? rest.cancelledBy,
      cancellationReason: live.cancellationReason ?? rest.cancellationReason,
      expiresAt: rest.expiresAt,
      createdAt: rest.createdAt,
      updatedAt: live.updatedAt ?? rest.updatedAt,
    );
  }

  // ── Data loading ─────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Booking-statuses is fetched separately (own try/catch) from
      // profile+bookings: previously all three were in one Future.wait,
      // so a single bad StatusItem (or a transient failure on that one
      // endpoint) took down the ENTIRE dashboard — no bookings, no
      // profile, nothing — even though profile+bookings had already
      // succeeded. Every status lookup across the app (booking list
      // badges, Insights completion rate, Finance) depends on this list,
      // so it still matters a lot, but it must never block the booking
      // list itself from rendering.
      final results = await Future.wait([
        ServiceLocator.artistService.getProfile(),
        // Higher limit so date-range filters on Bookings/Finance can reach
        // back into older bookings, not just the most recent ~50.
        ServiceLocator.bookingService.getAllBookings(limit: 300),
      ]);
      final profile = results[0] as ArtistProfile;
      final bookings = results[1] as List<Booking>;

      List<StatusItem> statuses = [];
      try {
        statuses = await ServiceLocator.coreService.getBookingStatuses();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Dashboard] booking-statuses lookup failed — status '
              'badges will show as "Open" until this is retried: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _bookings = bookings;
        _bookingStatuses = statuses;
        _hasClash = _detectClash(bookings, statuses);
        _loading = false;
      });
      if (kDebugMode) {
        final todayCount = BookingStats(bookings, statuses).todaysAppointments.length;
        debugPrint('[Dashboard] REST load done: ${bookings.length} bookings, today=$todayCount');
      }
      _loadCustomerNames(bookings);
      // Only safe to start now — needs the real artistId from [profile],
      // not available until this REST call resolves (see the doc comment
      // on [_listenForLiveBookings] for why it can't use
      // AppSession.instance.userId instead).
      _listenForLiveBookings(profile.artistId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showErrorToast(e, onRetry: _loadData);
    }
  }

  /// Resolves each distinct `customerId` in [bookings] to the customer's
  /// real name via GET /users/profile/get/, so slots/chat show a real
  /// name instead of the "Customer #<id>" placeholder. Every customer is
  /// a different user with a different id — this fetches each one's own
  /// profile rather than reusing/guessing a single static value. Runs
  /// after the main load so it never blocks the booking list from
  /// appearing, and each lookup is independently best-effort — one
  /// customer's profile failing to load doesn't affect the others.
  Future<void> _loadCustomerNames(List<Booking> bookings) async {
    final ids = bookings.map((b) => b.customerId).toSet()
      ..removeWhere((id) => id == 0 || _customerNames.containsKey(id));
    if (ids.isEmpty) return;

    await Future.wait(ids.map((id) async {
      try {
        final profile = await ServiceLocator.userService.getProfile(id);
        if (!mounted) return;
        if (profile.name.trim().isNotEmpty) {
          setState(() => _customerNames[id] = profile.name.trim());
        }
      } catch (_) {
        // Best-effort — that customer keeps the "Customer #<id>" fallback.
      }
    }));
  }

  bool _detectClash(List<Booking> bookings, List<StatusItem> statuses) {
    final active = bookings.where((b) {
      final label = _statusLabel(b.statusId, statuses);
      return label != 'cancelled' && label != 'no_show' && label != 'completed';
    }).toList();
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        if (active[i].bookingDate == active[j].bookingDate &&
            active[i].startTime == active[j].startTime) {
          return true;
        }
      }
    }
    return false;
  }

  String _statusLabel(int statusId, List<StatusItem> statuses) {
    final m = statuses.where((s) => s.statusId == statusId);
    return m.isNotEmpty ? m.first.name.toLowerCase() : '';
  }

  SlotStatus _mapStatus(int statusId, {String? cancelledBy}) =>
      BookingStats.mapStatus(statusId, _bookingStatuses, cancelledBy: cancelledBy);

  String _formatTime(String startTime) {
    try {
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $suffix';
    } catch (_) {
      return startTime;
    }
  }

  List<BookingSlot> get _slots {
    final list = [..._bookings]..sort((a, b) {
      final d = a.bookingDate.compareTo(b.bookingDate);
      return d != 0 ? d : a.startTime.compareTo(b.startTime);
    });
    return list
        .map((b) => BookingSlot(
      bookingId: b.bookingId,
      date: b.bookingDate,
      time: _formatTime(b.startTime),
      rawStartTime: b.startTime,
      client: _customerNames[b.customerId] ?? 'Customer #${b.customerId}',
      service: 'Package #${b.packageId}',
      status: _mapStatus(b.statusId, cancelledBy: b.cancelledBy),
      amount: b.totalAmount,
    ))
        .toList();
  }

  // ── Toast helpers ────────────────────────────────────────────────────
  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  /// Shows a categorized, user-readable error (network/auth/server/etc.)
  /// via [AppFeedback], with an optional retry action.
  void _showErrorToast(Object error, {VoidCallback? onRetry}) {
    if (!mounted) return;
    AppFeedback.showError(context, error, onRetry: onRetry);
  }

  void _navigate(String target, [String? tab]) {
    setState(() {
      _screen = target;
      if (target == 'business' && tab != null) _businessTab = tab;
      if (target == 'grow' && tab != null) _growTab = tab;
    });
  }

  // ── Booking status updates (real API) ──────────────────────────────────
  Future<void> _updateBookingStatus(BookingSlot slot, SlotStatus next, {String? reason}) async {
    if (slot.bookingId == null) return;
    final apiStatus = switch (next) {
      SlotStatus.confirmed => BookingStatusEnum.confirmed,
      SlotStatus.inProgress => BookingStatusEnum.inProgress,
      SlotStatus.completed => BookingStatusEnum.completed,
      SlotStatus.cancelled => BookingStatusEnum.cancelled,
      SlotStatus.noShow => BookingStatusEnum.noShow,
      _ => BookingStatusEnum.confirmed,
    };
    _showToast('Updating booking…');
    try {
      await ServiceLocator.bookingService.updateBookingStatus(slot.bookingId!, apiStatus, reason: reason);
      await _loadData();
      _showToast('Booking updated ✓');
    } catch (e) {
      _showErrorToast(e, onRetry: () => _updateBookingStatus(slot, next, reason: reason));
    }
  }

  Future<void> _logout() async {
    // Must run before authService.logout() clears the session — it needs
    // AppSession.instance.userId to know which Firestore token doc /
    // topic to deactivate.
    await PushNotificationService.instance.resetForLogout();
    HelpCenterNotifier.instance.stop();
    try {
      await ServiceLocator.authService.logout();
    } catch (_) {
      // Even if the server-side logout call fails, the local session has
      // already been cleared by AuthService — proceed to the login screen.
    }
    NotificationBadge.instance.clear();
    if (!mounted) return;
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  Future<void> _postPortfolio() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (xfile == null) return;

      // Best-effort sub_category_id: use the artist's first configured
      // service if we can find one, otherwise fall back to 1.
      int subCategoryId = 1;
      try {
        final services = await ServiceLocator.artistService.getAllServices();
        final list = services is Map ? services['data'] : services;
        if (list is List && list.isNotEmpty) {
          final first = list.first;
          if (first is Map && first['subCategoryId'] != null) {
            subCategoryId = first['subCategoryId'] as int;
          }
        }
      } catch (_) {
        // ignore — fall back to default
      }

      _showToast('Uploading to your portfolio…');
      await ServiceLocator.artistService.createPortfolio(CreatePortfolio(
        mediaType: MediaTypeEnum.image,
        subCategoryId: subCategoryId,
        file: xfile,
        caption: 'Shared via AiRA',
      ));
      _showToast('Added to your portfolio ✓');
    } catch (e) {
      _showErrorToast(e);
    }
  }

  String get _dateLabel {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = BookingStats(_bookings, _bookingStatuses);
    final todays = stats.todaysAppointments;
    // Requests genuinely awaiting the artist's Accept/Reject — not scoped
    // to today, since a pending request for any future date still needs a
    // response now. (Previously this counted already-`confirmed` bookings
    // as a stand-in, back when the backend's real `pending` status wasn't
    // being recognized by the app at all — see SlotStatus.pending.)
    final pendingConfirmationsCount =
        _bookings.where((b) => _mapStatus(b.statusId, cancelledBy: b.cancelledBy) == SlotStatus.pending).length;

    late final Widget mainScreen;
    switch (_screen) {
      case 'business':
        mainScreen = BusinessScreen(
          activeTab: _businessTab,
          onTabSelect: (t) => setState(() => _businessTab = t),
          onNavigate: _navigate,
          slots: _slots,
          loading: _loading,
          onUpdateStatus: _updateBookingStatus,
          bookings: _bookings,
          bookingStatuses: _bookingStatuses,
          customerNames: _customerNames,
          onWithdraw: () => AppFeedback.showInfo(context, "Payouts aren't available in this preview yet"),
          onRefresh: _loadData,
        );
        break;
      case 'grow':
        mainScreen = GrowScreen(
          activeTab: _growTab,
          onTabSelect: (t) => setState(() => _growTab = t),
          onPost: _postPortfolio,
          onShare: () => _showToast('Look shared with client'),
        );
        break;
      case 'learn':
        mainScreen = const LearningScreen();
        break;
      case 'profile':
        mainScreen = SettingsScreen(
          name: AppSession.instance.name ?? '',
          city: _profile?.city,
          profile: _profile,
          onLogout: _logout,
          onProfileUpdated: _loadData,
        );
        break;
      case 'home':
      default:
        if (kDebugMode) {
          debugPrint('[Dashboard] HomeScreen build: loading=$_loading, '
              'bookingsToday=${todays.length}, bookingsTotal=${_bookings.length}');
        }
        mainScreen = HomeScreen(
          onNavigate: _navigate,
          artistName: AppSession.instance.name ?? '',
          dateLabel: _dateLabel,
          loading: _loading,
          bookingsToday: todays.length,
          expectedEarningsToday: todays.fold<double>(0, (s, b) => s + b.totalAmount),
          pendingConfirmations: pendingConfirmationsCount,
          avgRating: _profile?.avgRating ?? 0,
          briefingText: todays.isEmpty
              ? "You're all clear — no bookings on the calendar today."
              : 'You have ${todays.length} booking${todays.length == 1 ? '' : 's'} and '
              '₹${todays.fold<double>(0, (s, b) => s + b.totalAmount).toStringAsFixed(0)} expected today.'
              '${_hasClash ? ' Two bookings clash — check your calendar.' : ''}',
        );
    }

    return Scaffold(
      backgroundColor: AiraColors.bg,
      extendBody: false,
      body: SafeArea(
        child: ClipRect(
          child: Stack(
            children: [
              Positioned.fill(child: mainScreen),
              if (_toast != null) AiraToast(text: _toast!),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AiraBottomNav(active: _screen, onSelect: _navigate),
      ),
    );
  }
}
