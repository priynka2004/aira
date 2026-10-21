// FILE: screens/reviews_ratings_screen.dart
// SCREEN: Reviews & Ratings — average rating, review count, reputation tips.
//
// APIs used:
//   GET /artists/profile/get/
//   GET /artists/reviews/get_all/      (reviews with reply / repliedAt)
//   PUT /artists/reviews/reply/        (replying again edits the reply)

import 'package:flutter/material.dart';
import '../models/artist/artist_extras.dart';
import '../models/artist/artist_profile.dart';
import '../utils/app_feedback.dart';
import '../theme/tokens.dart';
import '../utils/service_locator.dart';
import '../widgets/common.dart';

/// SCREEN: Reviews & Ratings — average rating, review count, reputation tips.
class ReviewsRatingsScreen extends StatefulWidget {
  final ArtistProfile? profile;
  const ReviewsRatingsScreen({super.key, this.profile});

  @override
  State<ReviewsRatingsScreen> createState() => _ReviewsRatingsScreenState();
}

/// State of [ReviewsRatingsScreen] — holds the screen data and logic.
class _ReviewsRatingsScreenState extends State<ReviewsRatingsScreen> {
  ArtistProfile? _profile;
  bool _needsReply = false;
  List<ArtistReviewItem> _reviews = [];
  bool _loadingReviews = true;

  /// Runs once when the screen opens; starts: _load().
  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    if (_profile == null) _load();
    _loadReviews();
  }

  /// API: artistBusiness.getReviews → GET /artists/reviews/get_all/
  Future<void> _loadReviews() async {
    try {
      final r = await ServiceLocator.artistBusiness.getReviews(limit: 100);
      if (mounted) setState(() => _reviews = r);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  /// Opens a sheet to write or edit the reply.
  /// API: artistBusiness.replyToReview → PUT /artists/reviews/reply/
  Future<void> _reply(ArtistReviewItem r) async {
    final ctrl = TextEditingController(text: r.reply ?? '');
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AiraColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.reply == null ? 'Reply To Review' : 'Edit Your Reply', style: AiraText.serif(fontSize: 19)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(hintText: 'Write A Polite, Helpful Reply'),
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Post Reply', expand: true, onTap: () => Navigator.pop(ctx, ctrl.text.trim())),
          ],
        ),
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      await ServiceLocator.artistBusiness.replyToReview(reviewId: r.reviewId, reply: text);
      if (mounted) AppFeedback.showSuccess(context, 'Reply Posted');
      _loadReviews();
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    }
  }

  Widget _reviewCard(ArtistReviewItem r) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: AiraCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(r.customerName ?? 'Client',
                      style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                ),
                for (var i = 0; i < 5; i++)
                  Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 17, color: AiraColors.gold),
              ]),
              if ((r.comment ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r.comment!, style: AiraText.sans(fontSize: 13, color: AiraColors.charcoal, height: 1.4)),
              ],
              if (r.reply != null && r.reply!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AiraColors.blush, borderRadius: BorderRadius.circular(12)),
                  child: Text('Your Reply: ${r.reply}', style: AiraText.sans(fontSize: 12.5, height: 1.4)),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _reply(r),
                  child: Text(r.reply == null ? 'Reply' : 'Edit Reply',
                      style: AiraText.sans(fontWeight: FontWeight.w700, color: AiraColors.rose)),
                ),
              ),
            ],
          ),
        ),
      );

  /// Loads this screen's data.
  /// API: artistService.getProfile → GET /artists/profile/get/
  Future<void> _load() async {
    try {
      final p = await ServiceLocator.artistService.getProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  /// Builds the UI.
  @override
  Widget build(BuildContext context) {
    final rating = _profile?.avgRating ?? 0;
    final total = _profile?.totalReviews ?? 0;
    final shown = _needsReply ? _reviews.where((r) => r.reply == null || r.reply!.isEmpty).toList() : _reviews;

    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SunndariBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SunndariAppBar(onBack: () => Navigator.of(context).pop()),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: SunndariPageHeading(
                  title: 'Reviews & Ratings',
                  subtitle: 'See What Clients Say About Your Services.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: AiraCard(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
                        child: const Icon(Icons.star_border_rounded, size: 36, color: AiraColors.rose),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        total == 0 ? 'No Ratings Yet' : rating.toStringAsFixed(1),
                        style: AiraText.serif(fontSize: total == 0 ? 20 : 34),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = total > 0 && rating >= i + 0.75;
                          final half = total > 0 && !filled && rating >= i + 0.25;
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : half
                                    ? Icons.star_half_rounded
                                    : Icons.star_border_rounded,
                            size: 26,
                            color: AiraColors.gold,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$total ${total == 1 ? 'review' : 'reviews'}',
                        style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: AiraPill(
                        label: 'All Reviews',
                        active: !_needsReply,
                        onTap: () => setState(() => _needsReply = false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AiraPill(
                        label: 'Needs Reply',
                        active: _needsReply,
                        onTap: () => setState(() => _needsReply = true),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingReviews)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AiraColors.rose)),
                )
              else if (shown.isNotEmpty)
                ...shown.map(_reviewCard)
              else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: AiraCard(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(color: AiraColors.blush, shape: BoxShape.circle),
                        child: const Icon(Icons.rate_review_outlined, size: 28, color: AiraColors.rose),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _needsReply ? 'Nothing Needs A Reply' : 'Your First Review Is On Its Way',
                        textAlign: TextAlign.center,
                        style: AiraText.serif(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _needsReply
                            ? 'Reviews Waiting For Your Response Will Show Up Here.'
                            : 'Reviews From Completed Bookings Will Appear Here.',
                        textAlign: TextAlign.center,
                        style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text('Build Your Reputation', style: AiraText.serif(fontSize: 18)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                child: Text(
                  'Positive Client Experiences Naturally Lead To Reviews. Here Are A Few Helpful Tips:',
                  style: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft, height: 1.4),
                ),
              ),
              _tip(Icons.verified_outlined, 'Deliver The Agreed Service', 'Meet Client Expectations And Provide Quality Service.'),
              _tip(Icons.schedule_rounded, 'Be On Time', 'Arrive As Scheduled And Keep Clients Informed.'),
              _tip(Icons.chat_bubble_outline_rounded, 'Respond Professionally To Feedback',
                  'Be Polite, Considerate And Address Any Concerns Openly.'),
            ],
          ),
        ),
      ),
    );
  }

  /// UI piece: tip.
  Widget _tip(IconData icon, String title, String body) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: AiraCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SunndariIconBubble(icon: icon, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AiraText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.roseDeep)),
                    const SizedBox(height: 2),
                    Text(body, style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
