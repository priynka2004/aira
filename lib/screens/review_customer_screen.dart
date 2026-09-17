import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';
import '../utils/app_feedback.dart';
import '../utils/service_locator.dart';

/// Artist reviewing the customer, shown right after "Mark Complete".
///
/// TODO(backend): there's no `/artists/reviews/create/` endpoint yet —
/// only the customer-facing `/customers/reviews/create/` exists today.
/// This screen calls the artist endpoint speculatively and falls back to
/// local storage if it 404s/errors, same pattern as
/// `BookingJourneyService`. Proposed contract:
///
///   POST /artists/reviews/create/  { booking_id, rating, comment }
class ReviewCustomerScreen extends StatefulWidget {
  final int bookingId;
  final String customerName;
  const ReviewCustomerScreen({super.key, required this.bookingId, required this.customerName});

  @override
  State<ReviewCustomerScreen> createState() => _ReviewCustomerScreenState();
}

class _ReviewCustomerScreenState extends State<ReviewCustomerScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      try {
        await ServiceLocator.apiService.post('/artists/reviews/create/', data: {
          'booking_id': widget.bookingId,
          'rating': _rating,
          'comment': _commentController.text.trim(),
        });
      } catch (_) {
        // TODO(backend): endpoint not live yet — persist locally instead
        // so the artist's review isn't lost, and can be resynced later.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'artist_review_${widget.bookingId}',
          jsonEncode({'rating': _rating, 'comment': _commentController.text.trim()}),
        );
      }
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back, size: 20, color: AiraColors.charcoal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Review customer', style: AiraText.serif(fontSize: 19, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  if (_submitted)
                    AiraCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 40, color: AiraColors.success),
                          const SizedBox(height: 12),
                          Text('Review submitted', style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Thanks for the feedback on ${widget.customerName}.',
                              style: AiraText.sans(fontSize: 12.5, color: AiraColors.charcoalSoft), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          PrimaryButton(label: 'Done', expand: true, onTap: () => Navigator.of(context).pop()),
                        ],
                      ),
                    )
                  else ...[
                    AiraCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text('How was ${widget.customerName}?',
                              style: AiraText.sans(fontSize: 15, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              final filled = i < _rating;
                              return GestureDetector(
                                onTap: () => setState(() => _rating = i + 1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 34,
                                    color: AiraColors.gold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AiraCard(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Anything worth noting for next time? (optional)',
                          hintStyle: AiraText.sans(fontSize: 13, color: AiraColors.charcoalSoft),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Submit Review',
                      expand: true,
                      onTap: _submitting ? null : _submit,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
