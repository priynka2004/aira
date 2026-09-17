import 'package:flutter/foundation.dart';
import 'service_locator.dart';

/// The set of approval "kinds" the UI knows how to render, resolved by
/// matching the backend's status *name* rather than a hardcoded numeric id.
///
/// IDs for these rows come from the `core_approval_status` table on the
/// backend (visible in Django admin as "suspended / rejected / approved /
/// pending"). Their numeric order there is an implementation detail and can
/// differ per environment/migration — the app must never assume e.g.
/// "2 = approved". Only the `name` is a stable contract.
enum ApprovalStatusKind { approved, rejected, suspended, pending, unknown }

/// Resolves a raw `approval_status_id` into an [ApprovalStatusKind] by
/// looking it up against GET /core/approval-status/get_all/ and matching
/// on the status *name*, instead of comparing the id to a hardcoded number.
///
/// This is the single source of truth both for "should this artist be let
/// into the app" (see [isApprovedStatusId]) and for "what should the
/// registration-status screen display" — previously those two checks had
/// drifted apart: navigation used this dynamic name-based lookup, while
/// RegistrationStatusScreen still compared `approvalStatusId` to hardcoded
/// 2/3/4, which could show the wrong screen (e.g. a suspended artist seeing
/// "still under review") whenever those hardcoded ids didn't match the
/// backend's real ids.
Future<ApprovalStatusKind> resolveApprovalStatusKind(int? statusId) async {
  if (statusId == null) {
    debugPrint('[ApprovalStatus] statusId is null → pending');
    return ApprovalStatusKind.pending;
  }
  try {
    final statuses = await ServiceLocator.coreService.getApprovalStatuses();
    debugPrint('[ApprovalStatus] artist statusId=$statusId, '
        'available statuses=${statuses.map((s) => '${s.statusId}:${s.name}').toList()}');

    final match = statuses.where((s) => s.statusId == statusId);
    if (match.isEmpty) {
      debugPrint('[ApprovalStatus] no status in the list matches id $statusId → unknown');
      return ApprovalStatusKind.unknown;
    }

    final name = match.first.name.trim().toLowerCase();
    debugPrint('[ApprovalStatus] matched name="$name"');

    if (name.contains('approv')) return ApprovalStatusKind.approved;
    if (name.contains('reject')) return ApprovalStatusKind.rejected;
    if (name.contains('suspend')) return ApprovalStatusKind.suspended;
    if (name.contains('pending')) return ApprovalStatusKind.pending;

    debugPrint('[ApprovalStatus] name "$name" did not match any known kind → unknown');
    return ApprovalStatusKind.unknown;
  } catch (e) {
    debugPrint('[ApprovalStatus] could not fetch status list ($e) → unknown');
    return ApprovalStatusKind.unknown;
  }
}

/// Resolves whether a given `approval_status_id` means "approved" by
/// looking it up against GET /core/approval-status/get_all/ — instead of
/// assuming a fixed numeric ID (e.g. hardcoding "2 = approved").
///
/// Backends commonly assign these status IDs dynamically via migrations or
/// seed data, so a hardcoded ID can silently drift out of sync with the
/// real value in a given environment. That mismatch was the root cause of
/// a real bug: already-approved artists were being sent back to
/// RegistrationStatusScreen on every app relaunch, because the splash
/// screen compared `profile.approvalStatusId` against a hardcoded `2`
/// instead of resolving it by name.
Future<bool> isApprovedStatusId(int? statusId) async {
  if (statusId == null) {
    debugPrint('[ApprovalStatus] statusId is null → not approved');
    return false;
  }
  try {
    final statuses = await ServiceLocator.coreService.getApprovalStatuses();
    final match = statuses.where((s) => s.statusId == statusId);
    if (match.isEmpty) {
      debugPrint('[ApprovalStatus] no status in the list matches id $statusId → not approved');
      return false;
    }

    // Match loosely ("Approved", "APPROVED", "Approval Granted", etc.)
    // rather than requiring an exact "approved" string, since we don't
    // control the backend's exact wording.
    final name = match.first.name.trim().toLowerCase();
    final result = name.contains('approv');
    debugPrint('[ApprovalStatus] matched name="$name" → approved=$result');
    return result;
  } catch (e) {
    debugPrint('[ApprovalStatus] could not fetch status list ($e) — letting the artist in '
        'rather than blocking them over a network hiccup');
    // If the status list can't be fetched (e.g. a transient network
    // hiccup), don't lock an already-logged-in, previously-approved artist
    // out of the app over it.
    return true;
  }
}
