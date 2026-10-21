// FILE: utils/approval_status.dart
// Maps backend approval-status id -> approved / rejected / suspended / pending.
//
// APIs used:
//   GET /artists/onboarding/status/   (preferred — status: not_started | in_progress | submitted | approved | rejected | suspended)
//   GET /core/approval-status/get_all/ (fallback: id → name)

import 'package:flutter/foundation.dart';
import '../models/artist/artist_profile.dart';
import 'service_locator.dart';

/// Enum: Approval Status Kind values.
enum ApprovalStatusKind { approved, rejected, suspended, pending, unknown }

/// Resolves approval status kind.
/// API: coreService.getApprovalStatuses → GET /core/approval-status/get_all/
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

/// Returns true if approved status ID.
/// API: coreService.getApprovalStatuses → GET /core/approval-status/get_all/
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

    final name = match.first.name.trim().toLowerCase();
    final result = name.contains('approv');
    debugPrint('[ApprovalStatus] matched name="$name" → approved=$result');
    return result;
  } catch (e) {
    debugPrint('[ApprovalStatus] could not fetch status list ($e) — letting the artist in '
        'rather than blocking them over a network hiccup');
    return true;
  }
}

/// Resolves the artist's review state. The onboarding status endpoint is the source of truth
/// (in_progress / submitted → pending); if it cannot be reached we fall back to the approval-status id.
/// API: GET /artists/onboarding/status/
Future<ApprovalStatusKind> resolveArtistStatusKind(ArtistProfile? profile) async {
  try {
    final s = await ServiceLocator.artistBusiness.getOnboardingStatus();
    if (s.isApproved) return ApprovalStatusKind.approved;
    if (s.isRejected) return ApprovalStatusKind.rejected;
    if (s.isSuspended) return ApprovalStatusKind.suspended;
    return ApprovalStatusKind.pending;
  } catch (e) {
    debugPrint('[ApprovalStatus] onboarding status unavailable ($e) → using approval-status id');
    return resolveApprovalStatusKind(profile?.approvalStatusId);
  }
}
